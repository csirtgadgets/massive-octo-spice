package CIF::Observable::Actor;

use strict;
use warnings;

use Mouse;

with 'CIF::Observable';

has '+otype' => (
    is      => 'ro',
    default => 'actor',
);

has 'aliases' => (
    is      => 'ro',
);

sub process {}
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'otype'});
    return unless($args->{'otype'} eq 'actor');
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;