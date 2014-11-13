package CIF::REST::Observables;

use Mojo::Base 'Mojolicious::Controller';
use POSIX;
use CIF qw/$Logger/;
use Data::Dumper;

sub index {
    my $self = shift;

    my $query      	= $self->param('q') || $self->param('observable');
    
    $Logger->debug('generating search...');
    my $res = $self->cli->search({
        token      	=> $self->token,
        query      	=> scalar $query,
        nolog       => scalar $self->param('nolog'),
        filters     => {
        	otype          	=> scalar $self->param('otype')        || undef,
        	cc             	=> scalar $self->param('cc')           || undef,
        	confidence     	=> scalar $self->param('confidence')   || 0,
        	group          	=> scalar $self->param('group')        || undef,
        	limit          	=> scalar $self->param('limit')        || undef,
        	tags           	=> scalar $self->param('tags')         || undef,
        	application    	=> scalar $self->param('application')  || undef,
        	asn            	=> scalar $self->param('asn')          || undef,
        	provider       	=> scalar $self->param('provider')     || undef,
        	rdata          	=> scalar $self->param('rdata')        || undef,
        	firsttime      	=> scalar $self->param('firsttime')    || undef,
        	lasttime	    => scalar $self->param('lasttime')     || undef,
        	reporttime      => scalar $self->param('reporttime')   || undef,
        },
    });
    
    if(defined($res)){
        if($res){
            $self->stash(observables => $res, token => $self->token);
            $self->respond_to(
                json    => { json => $res },
                html    => { template => 'observables/index' },
            );
        } else {
            $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
        }
    } else {
        $self->render(json   => { 'message' => 'unknown failure' }, status => 500 );
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
           $self->stash(observables => $res);
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
    
    # ping the router first, make sure we have a valid key
    my $res = $self->cli->ping_write({
        token   => $self->token,
    });
    
    if($res == 0){
        $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
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
        if($res){
            $self->respond_to(
                json    => { json => $res, status => 201 },
            );
            $self->res->headers->add('X-Location' => $self->req->url->to_string());
            $self->res->headers->add('X-Id' => @{$res}[0]); ## TODO
        } elsif($res == -1 ){
           $self->respond_to(
                json => { json => { "error" => "timeout" }, status => 408 },
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
        enable_metadata => 1,
    });
    return $res;
}
1;
