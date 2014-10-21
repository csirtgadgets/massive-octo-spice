package CIF::REST::Observables;
use Mojo::Base 'Mojolicious::Controller';
use POSIX;

use CIF qw/$Logger/;

sub index {
    my $self = shift;

    my $query      	= $self->param('q') || $self->param('observable');
    
    $Logger->debug('generating search...');
    my $res = $self->cli->search({
        token      	=> scalar $self->param('token'),
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
    $self->stash(observables => $res, token => scalar $self->param('token')); ##TODO is this safe?
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'observables/index' },
    );
}

sub show {
    my $self  = shift;
    
    my $res = $self->cli->search({
        token      => scalar $self->param('token'),
        id         => $self->stash->{'observable'},
    });
    $self->stash(observables => $res); ##TODO -- does this leak if we don't clear it?
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'observables/show' },
    );
}

sub create {
    my $self = shift;
    
    my $data    = $self->req->json();
    my $nowait  = scalar $self->param('nowait') || 0;
    
    my $res;
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

    unless($res){
         $self->respond_to(
            json => { json => { "error" => "unknown, contact system administrator" }, status => 500 },
        );
        return;
    }
    
    if($res == -1){
        $self->respond_to(
            json => { json => { "error" => "timeout" }, status => 408 },
        );
        return;
    }
    
    $self->respond_to(
        json    => { json => $res, status => 201 },
    );
    
    $self->res->headers->add('X-Location' => $self->req->url->to_string());
    $self->res->headers->add('X-Id' => @{$res}[0]); ## TODO
}

sub _submit {
    my $self = shift;
    my $data = shift;
    
    my $res = $self->cli->submit({
        token           => scalar $self->param('token'),
        observables     => $data,
        enable_metadata => 1,
    });
    return $res;
}
1;
