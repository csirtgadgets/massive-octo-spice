package CIF::Message::Token;

use strict;
use warnings;


use Mouse;

has [qw/token alias description/] => (
    is      => 'ro',
    isa     => 'Str',
);

has [qw/created expires/] => (
    is      => 'ro',
    isa     => 'Int',
);

has [qw/restricted revoked admin/] => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} =~ /^token-/);
}

__PACKAGE__->meta()->make_immutable();

1;