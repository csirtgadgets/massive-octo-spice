package CIF::Router::RESTApp;

use strict;
use warnings;

use Plack::Request;
use Plack::Middleware::REST::Util;
use HTTP::Status qw(status_message);
use JSON::XS;
use Data::Dumper;
use Mouse;
use CIF qw/init_logging $Logger/;
use CIF::Client;
use HTTP::Request::Common qw(GET PUT POST DELETE HEAD);
use HTTP::Status qw(status_message);
use Time::HiRes qw(gettimeofday);

use constant REMOTE_DEFAULT => 'tcp://localhost:'.CIF::DEFAULT_PORT();

use constant REQUIRED_FIELDS => {
    observable  => 1,
    provider    => 1,
    confidence  => 1,
    tags        => 1,
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;
    
    my $level = $args->{'loglevel'} || 'DEBUG';
    init_logging({ level => $level }) unless($Logger);
    
    return $self->$orig($args);
};

has 'remote' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_remote',
    default => REMOTE_DEFAULT(),
);

has 'client' => (
    is          => 'ro',
    isa         => 'CIF::Client',
    reader      => 'get_client',
    lazy_build  => 1,
);

## builders

sub _build_client {
    my $self = shift;
    
    return CIF::Client->new({
        remote  => $self->get_remote(),
    });
}

## helper method

sub response {
    my $code = shift;
    my $body = @_ ? shift : status_message($code);
    $body = { message => $body } if($code >= 400);
    $body = JSON::XS->new->convert_blessed(1)->encode($body);
    [ $code, [ 'Content-Type' => 'application/json', @_ ], [ $body ] ];
}

## methods

sub get {
    my ($self,$env) = @_;
    my $req = Plack::Request->new($env);
    
    ## auth is handled by cif-router
    ## we're just a wrapper
    return response(400,'missing token') unless($req->param('token'));
    
    my $req_id = request_id($env);
    return response(400,'missing query') unless($req_id);
    return response(200, { timestamp => [gettimeofday()] }) if($req_id eq '_ping');
    
    my $resource = $self->get_client->search({
        nodecode    => 1,
        Token       => $req->param('token'),
        Query       => $req_id,
        limit       => $req->param('limit')         || 500,
        confidence  => $req->param('confidence')    || 0,
        ## TODO - group       => $req->param('group') || 'everyone',
    });
    return defined $resource ? response( 200 => $resource ) : response(404);
}

sub create {
    my ($self,$env) = @_;
    my ($resource, $type) = request_content($env);
    
    return response(400) unless defined $resource;
    my $obs = JSON::XS::decode_json($resource);
    $obs = [$obs] unless(ref($obs) eq 'ARRAY');
    
    my $check;
    foreach my $o (@$obs){
        $check = _check_fields($o);
        unless($check eq 1){
            
            return response(400,'missing required field: '.$check);
        }
    }
    my $req = Plack::Request->new($env);
    my $res = $self->get_client->submit({
        Token       => $req->param('token'),
        Observables => $obs,
    });
    
    if($#{$res} == 0){ # single
        my $uri = request_uri($env,'id/'.@{$res}[0]);
        return response(201, @$obs, 'X-Location' => $uri, 'X-Id' => @{$res}[0]);
    } else { # bulk
        $res = [ map { $_ = { id => $_ } } @$res ];
        return response(201, $res);
    }
}

sub _check_fields {
    my $ob = shift;
    
    foreach my $k (keys REQUIRED_FIELDS){
        return $k unless($ob->{$k});   
    }
    return 1;
}

1;