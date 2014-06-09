package CIF::Format::Csv;

use strict;
use warnings;

use Mouse;

with 'CIF::Format';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args);
    return 1 if($args eq 'csv');
}

sub process {
    my $self = shift;
    my $args = shift;

}

__PACKAGE__->meta()->make_immutable();

1;
