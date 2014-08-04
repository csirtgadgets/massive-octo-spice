package CIF::Router::Request::Search;

use strict;
use warnings;

use Mouse;
use CIF::Message::Search;
use CIF::ObservableFactory;
use CIF qw/hash_create_static $Logger/;
use Data::Dumper;

with 'CIF::Router::Request';

use constant RE_BADCHARS        => qr/(\/?\.\.+\/?|;|\w+\(|=>)/;
use constant RE_GOODQUERY       => qr/^[a-zA-Z0-9_\.\,\/\-@\:]+$/;
use constant CONFIDENCE_DEFAULT => 25; ## TODO -- move to router
use constant TLP_DEFAULT        => 'amber'; ## TODO
use constant GROUP_DEFAULT      => 'everyone'; ## TODO

sub check {
    my $self    = shift;
    my $q       = shift || return;

    for($q){
        return 0 if(ref($_));
        return 0 if($_ =~ RE_BADCHARS());
        return 0 unless($_ =~ RE_GOODQUERY());
    }
    return 1;
}

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'search');
}

sub _log_search {
    my $self    = shift;
    my $data    = shift;
    
    $Logger->debug('logging search: '.$data->{'Data'}->{'Query'});
    
    my $obs = CIF::ObservableFactory->new_plugin({ 
        observable  => $data->{'Data'}->{'Query'},
        provider    => hash_create_static($data->{'Token'}),
        confidence  => CONFIDENCE_DEFAULT(),
        tlp         => TLP_DEFAULT(),
        tags        => ['search'],
        group       => GROUP_DEFAULT(),
    });
    
    $obs = $obs->TO_JSON();
    
    my $res = $self->get_storage_handle()->process({ Observables => [$obs] });
    
    $Logger->debug('search logged');
    return $res;
}

sub process {
    my $self    = shift;
    my $msg     = shift;
    my $data    = $msg->{'Data'};
    
    if($data->{'Query'}){
    	return -1 unless($self->check($data->{'Query'}));
    } else {
    	return -1 unless ($data->{'Id'} || $data->{'Filters'});
    }
    
    $Logger->debug(Dumper($msg));
   
    my $results = $self->get_storage_handle()->process($data);
   
    if($data->{'Query'} && $data->{'Query'} ne 'all'){
        $self->_log_search($msg) unless($data->{'nolog'});
    }
    
    return (-1) unless(ref($results) eq "ARRAY");

    my $resp = CIF::Message::Search->new({
        Results     => $results,
    });
    if($data->{'Query'}){
    	$resp->set_Query($data->{'Query'});
    } else {
    	$resp->set_Id($data->{'Id'});
    }
    return $resp;
}

__PACKAGE__->meta()->make_immutable();

1;