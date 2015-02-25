package CIF::REST::Feeds;
use Mojo::Base 'Mojolicious::Controller';
use POSIX ":sys_wait_h";
use JSON::XS;

use CIF qw/$Logger/;

use constant TIMEOUT => 115;

sub index {
    my $self = shift;
	
	my $res = $self->cli->search({
		token     => $self->token,
		filters   => {
			otype        => scalar $self->param('otype')        || undef,
			confidence   => scalar $self->param('confidence')   || undef,
			cc           => scalar $self->param('cc')           || undef,
			tags         => scalar $self->param('tag')          || undef,
			provider     => scalar $self->param('provider')     || undef,
			tlp          => scalar $self->param('tlp')          || undef,
		},
		feed      => 1,
		nodecode  => 1,
	});
	
	$self->respond_to(
        json    => { text => @{$res}[0] }, # it's already an encoded string
        html    => { template => 'feeds/index' },
    );
}

sub show {
  my $self  = shift;
  
  my $res = $self->cli->search({
      token => $self->token,
      id    => scalar $self->param('feed'),
      feed  => 1,
  });
  
  $self->stash(feeds => $res);
    $self->respond_to(
        json    => { json => $res },
    );
}

sub create {
    my $self = shift;
    
    # we do this, since we can't recoup memory in perl
    $SIG{CHLD} = sub { };
    my $child = fork();

    unless(defined($child)){
        $Logger->error('fork() error: '.$!);
        $self->render(json => { 'message' => 'unknown error, contact sysadmin' } , status => 500 );
        return;
    }
    
    if($child == 0){
        my $res = $self->cli->ping_write({
            token   => $self->token,
        });
        
        if($res == 0){
            $self->render(json   => { 'message' => 'unauthorized' }, status => 401 );
            die;
        }
        
        my $data = $self->req->text();
        $data = JSON::XS->new->decode($data);
        $data = [$data] unless(ref($data) eq 'ARRAY');
        
        $Logger->debug('submitting feed...');
        
        $res = $self->cli->submit_feed({
        	token  => $self->token,
            feed   => $data,
        });
        
        $Logger->debug('returning...');
        exit(0);
    } else { # parent
         my $endtime = time() + TIMEOUT;
         my $pid;
         while (1) {
             my $tosleep = $endtime - time();
             last unless($tosleep > 0);
             
             $pid = waitpid(-1, WNOHANG);
             last if($pid > 0);
         }
         if ($pid <= 0){
             $Logger->error('child timed out!');
             kill 9, $child;
             $self->respond_to(
                json    => { json => { 'message' => 'failed to create feed' }, status => 403 }
            );
         } else {
            $self->res->headers->add('X-Location' => $self->req->url->to_string());
    
            $self->respond_to(
                json    => { json => { 'message' => 'feed successfully created' }, status => 201 },
            );
         }
    }
}
    
1;