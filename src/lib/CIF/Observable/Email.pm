package CIF::Observable::Email;

use strict;
use warnings;

use Mouse;
use CIF qw/is_email/;
use Digest::SHA qw/sha256_hex/;
use Compress::Snappy;
use MIME::Base64;

use constant DEFAULT_HASH_TYPE => 'sha256';

with 'CIF::Observable';

has '+otype' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'email',
);

has 'message' => (
    is      => 'ro',
    isa     => 'Str',
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
    return unless(is_email($args->{'observable'}));
    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;
