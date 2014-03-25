package CIF::Router::Auth::Dummy;

use strict;
use warnings;

use Mouse;

with 'CIF::Router::Auth';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'plugin'});
    return 1 if(lc($args->{'plugin'}) eq 'dummy');
}

sub process { return 1; }

__PACKAGE__->meta()->make_immutable();

1;