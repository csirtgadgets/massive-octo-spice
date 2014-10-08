package CIF::Observable::Fqdn;

use strict;
use warnings;

use Mouse;
use CIF qw/is_fqdn/;

with 'CIF::ObservableAddress';

has '+otype' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'fqdn',
);

sub process {}
sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'observable'});
    return unless(is_fqdn($args->{'observable'}));
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;