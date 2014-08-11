package CIF::REST::Feeds;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
	
	my $res = $self->cli->search({
		Token     => $self->param('token'),
		Filters   => {
			otype        => $self->param('otype')        || undef,
			confidence   => $self->param('confidence')   || undef,
			cc           => $self->param('cc')           || undef,
			tags         => $self->param('tag')          || undef,
			providers    => $self->param('provider')     || undef,
			tlp          => $self->param('tlp')          || undef,
		},
		feed      => 1,
	});
	
	$self->stash(observables => $res);
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'feeds/index' },
    );
}

sub show {
  my $self  = shift;
  
  my $res = $self->cli->search({
      Token => $self->param('token'),
      Id    => $self->param('feed'),
      feed  => 1,
  });
  
  $self->stash(feeds => $res);
    $self->respond_to(
        json    => { json => $res },
    );
}

sub create {
    my $self = shift;
    
    my $data = $self->req->json();
    $data = [$data] unless(ref($data) eq 'ARRAY');
    
    my $res = $self->cli->submit_feed({
    	Token  => $self->param('token'),
        Feed   => $data,
    });
    
    $self->res->headers->add('X-Location' => $self->req->url->to_string());
    $self->res->headers->add('X-Id' => @{$res}[0]); ## TODO

    $self->respond_to(
        json    => { json => $res, status => 201 },
    );
}
    
1;