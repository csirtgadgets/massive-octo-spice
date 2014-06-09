package CIF::Observable::IPv6;

use strict;
use warnings;

use Mouse;
use CIF qw/is_ip/;

with 'CIF::ObservableAddressIP';

has '+otype' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ipv6',
);


sub process {}
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'observable'});
    return unless(is_ip($args->{'observable'}) eq 'ipv6');
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;