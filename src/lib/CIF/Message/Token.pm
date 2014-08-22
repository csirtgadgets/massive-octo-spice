package CIF::Message::Token;

use strict;
use warnings;

use Mouse;

has [qw/Token Alias Description/] => (
    is      => 'ro',
    isa     => 'Str',
);

has [qw/Created Expires/] => (
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

sub TO_JSON {
    my $self = shift;

    my $ret = {
        'Token'         => $self->Token(),
        'Alias'         => $self->Alias(),
        'Description'   => $self->Description(),
        'Created'       => $self->Created(),
        'Expires'       => $self->Expires(),
        
        'restricted'    => $self->restricted(),
        'revoked'       => $self->revoked(),
        'admin'         => $self->admin(),
        
    };
    return $ret;
}

__PACKAGE__->meta()->make_immutable();

1;