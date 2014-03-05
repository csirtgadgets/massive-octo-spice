package CIF::Message;

use strict;
use warnings;

use Mouse;
use CIF qw/hash_create_random/;
use CIF::MessageFactory;
use Time::HiRes qw(tv_interval);

has 'version'   => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { CIF::PROTOCOL_VERSION(); },
    reader  => 'get_version',
);

has 'mtype' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    reader      => 'get_mtype',
    writer      => 'set_mtype',
);

has 'stype' => (
    is      => 'rw',
    isa     => 'Str',
    reader      => 'get_stype',
    writer      => 'set_stype',
);

has 'rtype' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    reader      => 'get_rtype',
);

has 'timestamp' => (
    is      => 'ro',
    isa     => 'Num',
    reader  => 'get_timestamp',
    default => sub { tv_interval() },
);

has 'id'   => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { hash_create_random() },
    reader  => 'get_id',
);

has 'Token' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    reader      => 'get_Token',
);

has 'Data'  => (
    is      => 'rw',
    reader      => 'get_Data',
    writer      => 'set_Data',
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
        '@version'      => $self->get_version(),
        '@mtype'        => $self->get_mtype(),    
        '@stype'        => $self->get_stype(),
        '@rtype'        => $self->get_rtype(),
        '@timestamp'    => $self->get_timestamp(),
        '@id'           => $self->get_id(),
        
        'Data'          => $self->get_Data(),
        'Token'         => $self->get_Token(), 
    };
    return $ret;
}
__PACKAGE__->meta()->make_immutable();

1;