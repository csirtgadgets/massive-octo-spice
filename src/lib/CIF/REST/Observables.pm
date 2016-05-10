package CIF::REST::Observables;

use Mojo::Base 'Mojolicious::Controller';
use POSIX;
use CIF qw/$Logger/;
use Data::Dumper;
use JSON::XS;
 use Gzip::Faster;
 use MIME::Base64 qw/encode_base64 decode_base64/;

my $encoder = JSON::XS->new->convert_blessed;

sub _json {
    my $data = shift;
    my $gzip = shift;
    
    $data = $encoder->encode($data);
    if($gzip){
        $data = encode_base64(gzip($data));
    }
    return $data;
}

sub index {
    my $self = shift;

    my $query      	= scalar $self->param('q') || scalar $self->param('observable');
    my $gzip        = scalar $self->param('gzip') || 0;
    
    my $filters = {};
    
    foreach my $x (qw/id provider otype cc confidence group limit tags application asn rdata firsttime lasttime reporttime reporttimeend description/){
        if($self->param($x)){
            $filters->{$x} = scalar $self->param($x);
            if($filters->{$x} =~ /^\-/){
                $self->render(json   => { 'message' => 'Malformed request' }, status => 422 );
                return;
            }
        }
    }
    $Logger->debug(Dumper($filters));
    
    my $res;
    if($query or scalar(keys($filters)) > 0){
        $filters->{'confidence'} = 0 unless($filters->{'confidence'});
        $Logger->debug('generating search...');
        if($filters->{'id'}){
            $res = $self->cli->search({
                token      	=> scalar $self->token,
                id          => $filters->{'id'}
            });
        } else {
            $res = $self->cli->search({
                token      	=> scalar $self->token,
                query      	=> scalar $query,
                nolog       => scalar $self->param('nolog'),
                filters     => $filters,
            });
        }
    } else {
        $self->render(json   => { 'message' => 'invalid query' }, status => 404 );
    }
    
    if(defined($res)){
        #$Logger->debug(Dumper($res));
        if($res){
            $self->respond_to(
                json    => { text => _json($res,$gzip) },
                html    => { template => 'observables/index' },
            );
        } else {
            $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
        }
    } else {
        $self->render(json   => { 'message' => 'Malformed request' }, status => 503 );
    }
}

sub show {
    my $self  = shift;
    
    my $res = $self->cli->search({
        token      => $self->token,
        id         => $self->stash->{'observable'},
    });
    
    if(defined($res)){
        if($res){
           #$self->stash(observables => $res);
           $Logger->debug(Dumper($res));
            $self->respond_to(
                json    => { json => $res },
                html    => { template => 'observables/show' },
            );
        } else {
            $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
        }
    } else {
        $self->render(json   => { 'message' => 'unknown failure' }, status => 500 );
    }
}

sub create {
    my $self = shift;
    
    my $data    = $self->req->json();
    my $nowait  = scalar $self->param('nowait') || 0;
    
    $Logger->debug(Dumper($data));
    
    # ping the router first, make sure we have a valid key
    my $res = $self->cli->ping_write({
        token   => $self->token,
    });
    
    if($res == 0){
        $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
        return;
    }
    
    unless (ref($data) eq 'ARRAY') {
        $data = [ $data ];
    }
    
    unless(@{$data}[0]->{'group'}){
        $self->render(json => { 'message' => 'Bad Request, missing group tag in one of the observables', status => 400 } );
        return;
    }
    
    if($nowait){
        $SIG{CHLD} = 'IGNORE'; # http://stackoverflow.com/questions/10923530/reaping-child-processes-from-perl
        my $child = fork();
        
    	unless (defined $child) {
    		die "fork(): $!";
    	}
    	
        if($child == 0){
            # child
            $self->_submit($data);

            exit;
        } else {
            $self->respond_to(
                json    => { json => { 'message' => 'submission accepted, processing may take time' }, status => 201 },
            );
            return;
        }
    } else {
        $res = $self->_submit($data);
    }
    
    if(defined($res)){
        if($res && $res != -1){
            $self->respond_to(
                json    => { json => $res, status => 201 },
            );
            if($#{$res} >= 0){
                $self->res->headers->add('X-Location' => $self->req->url->to_string());
                $self->res->headers->add('X-Id' => @{$res}[0]); ## TODO
            } else {
                $self->respond_to(
                    json => { json => { "error" => "timeout" }, status => 422 },
                );
            }
        } elsif($res == -1 ){
           $self->respond_to(
                json => { json => { "error" => "timeout" }, status => 422 },
           );
        } else {
            $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
        }
    } else {
        $self->render(json   => { 'message' => 'unknown failure' }, status => 500 );
    }
}

sub _submit {
    my $self = shift;
    my $data = shift;
    
    my $res = $self->cli->submit({
        token           => $self->token,
        observables     => $data,
    });
    return $res;
}
1;
