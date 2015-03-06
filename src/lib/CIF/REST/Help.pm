package CIF::REST::Help;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    shift->respond_to(
        html    => { template => 'help/index' },
    );
}

sub preflight {
    my $self = shift;
    
    $self->res->headers->header('Access-Control-Allow-Origin' => '*');
    $self->res->headers->header('Access-Control-Allow-Methods' => 'OPTIONS, GET, POST');
    $self->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    
    $self->respond_to(any => { data => '', status => 200 });
}

1;
