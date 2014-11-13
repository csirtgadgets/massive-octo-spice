package CIF::Storage::Dummy;

use strict;
use warnings;

use Mouse;

with 'CIF::Storage';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'plugin'});
    return 1 if(lc($args->{'plugin'}) eq 'dummy');
}

sub shutdown {}

sub process {
    my $self = shift;
    my $args = shift;
    return [];
}

sub check_handle { return 1; }
sub check_auth { return 1; }

__PACKAGE__->meta()->make_immutable();

1;