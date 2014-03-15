package CIF::Storage::Dummy;

use 5.011;
use strict;
use warnings;

use Mouse;

with 'CIF::Storage';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'plugin'});
    return 1 if($args->{'plugin'} eq 'DUMMY');
}

sub shutdown {}

sub process {
    my $self = shift;
    my $args = shift;
    return [];
}

__PACKAGE__->meta()->make_immutable();

1;