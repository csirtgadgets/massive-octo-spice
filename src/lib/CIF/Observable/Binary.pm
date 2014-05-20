package CIF::Observable::Binary;

use strict;
use warnings;


use Mouse;
use Digest::SHA qw/sha256_hex/;

with 'CIF::Observable';

use constant DEFAULT_HASH_TYPE => 'sha256';

has '+otype' => (
    default => 'binary',
);

has 'hash' => (
    is      => 'ro',
    isa     => 'CIF::Type::Hash',
    default => sub { sha256_hex($_[0]->{'observable'}) },
);

has 'htype' => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_HASH_TYPE(),
);

sub process {}
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'observable'});
    return unless($args->{'otype'});
    return unless($args->{'otype'} eq 'binary');
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;