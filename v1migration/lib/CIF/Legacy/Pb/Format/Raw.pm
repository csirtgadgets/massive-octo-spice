package CIF::Legacy::Pb::Format::Raw;
use base 'CIF::Legacy::Pb::Format';

use strict;
use warnings;

sub write_out {
    my $self = shift;
    my $args = shift;

    my $array = $self->to_keypair($args);
    return $array;
}
1;
