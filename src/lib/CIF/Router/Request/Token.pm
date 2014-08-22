package CIF::Router::Request::Token;

use strict;
use warnings;

use Mouse;
use Time::HiRes qw(gettimeofday);

with 'CIF::Router::Request';

has 'Id'    => (
    is     => 'rw',
    reader => 'get_Id',
    writer => 'set_Id',
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'token');
}

sub process {
    my $self = shift;
    my $args = shift;
    
    
}

sub TO_JSON {
    my $self = shift;
    
    return {
        'Id'    => self->Id(),
    };
}

__PACKAGE__->meta()->make_immutable();

1;