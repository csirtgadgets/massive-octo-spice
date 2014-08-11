package CIF::REST::Help;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    shift->respond_to(
        html    => { template => 'help/index' },
    );
}

1;
