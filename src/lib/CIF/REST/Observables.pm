package CIF::REST::Observables;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    my $query      	= $self->param('q') || $self->param('observable');
    
    my $res = $self->cli->search({
        token      	=> $self->param('token'),
        query      	=> $query,
        filters     => {
        	otype          => $self->param('otype')        || undef,
        	cc             => $self->param('cc')           || undef,
        	confidence     => $self->param('confidence')   || 0,
        	starttime      => $self->param('starttime')    || undef,
        	groups         => $self->param('group')       || undef,
        	limit          => $self->param('limit')        || undef,
        	tags           => $self->param('tag')         || undef,
        	applications   => $self->param('application') || undef,
        	asns           => $self->param('asn')         || undef,
        	providers      => $self->param('provider')    || undef,
        },
    });
    $self->stash(observables => $res);
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'observables/index' },
    );
}

sub show {
    my $self  = shift;

    my $query      = $self->param('observable');
    
    my $res = $self->cli->search({
        token      => $self->param('token'),
        id         => $query,
    });
    $self->stash(observables => $res); ##TODO -- does this leak if we don't clear it?
    $self->respond_to(
        json    => { json => $res },
        html    => { template => 'observables/show' },
    );
}

sub create {
    
}

1;