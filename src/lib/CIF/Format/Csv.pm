package CIF::Format::Csv;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
#use Text::CSV;

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
