package CIF::Format::Csv;

use strict;
use warnings;


use Mouse;

with 'CIF::Format';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'type'});
    return 1 if($args->{'type'} eq 'csv');
}

sub process {}

__PACKAGE__->meta()->make_immutable();

1;