package CIF::Observable::Hash;

use strict;
use warnings;


use Mouse;
use CIF qw/is_hash/;

with 'CIF::Observable';

has '+otype' => (
    default => sub { is_hash($_[0]->{'observable'}) },
);

sub process {}
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'observable'});
    return unless(is_hash($args->{'observable'}));
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;