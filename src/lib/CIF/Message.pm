package CIF::Message;

use strict;
use warnings;

use Mouse;
use CIF qw/hash_create_random/;
use CIF::MessageFactory;
use Time::HiRes qw(gettimeofday);

has 'version'   => (
    is  => 'ro',
    default => sub { CIF::PROTOCOL_VERSION; },
);

has [qw/stype rtype mtype/] => (
    is      => 'rw',
);

has 'timestamp' => (
    is  => 'ro',
    default => sub { gettimeofday() },
);

has 'id'   => (
    is  => 'ro',
    default => sub { hash_create_random() },
);

has 'Token' => (
    is  => 'ro',
    required    => 1,
);

has 'Data'  => (
    is      => 'rw',
);

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;

    $args->{'Data'} = CIF::MessageFactory->new_plugin($args);
    return $self->$orig($args);
};

sub TO_JSON {
    my $self = shift;

    my $ret = {
        'version'      => $self->version,
        'timestamp'    => $self->timestamp,
        'id'           => $self->id,
        
        'mtype'        => $self->mtype,    
        'stype'        => $self->stype,
        'rtype'        => $self->rtype,
        
        'Data'          => $self->Data,
        'Token'         => $self->Token, 
    };
    return $ret;
}
__PACKAGE__->meta()->make_immutable();

1;