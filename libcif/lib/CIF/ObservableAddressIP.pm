package CIF::ObservableAddressIP;

use strict;
use warnings;
use namespace::autoclean;

use Mouse::Role;

with 'CIF::ObservableAddress';

has 'asn'   => (
    is      => 'ro',
    isa     => 'Num',
    reader  => 'get_asn',
);

has 'asn_desc'  => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_asn_desc',
);

has 'rir'   => (
    is      => 'ro',
    isa     => 'CIF::Type::RIR',
    reader  => 'get_rir',
);

has 'peers' => (
    is      => 'ro',
    isa     => 'ArrayRef', ##TODO -- array of ASN objs
    reader  => 'get_peers',
    coerce  => 1,
);

has 'prefix'    => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_prefix',
);

1;