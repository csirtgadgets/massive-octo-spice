package CIF::ObservableAddressIP;

use strict;
use warnings;

use Mouse::Role;

with 'CIF::ObservableAddress';

# server/client?
has 'orientation' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_orientation',
);

has 'asn'   => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_asn',
);

has 'asn_desc'  => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_asn_desc',
);

has 'rir'   => (
    is      => 'ro',
    isa     => 'Maybe[CIF::Type::RIR]',
    reader  => 'get_rir',
);

has 'peers' => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    reader  => 'get_peers',
    coerce  => 1,
);

has 'prefix'    => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_prefix',
);

has 'citycode'   => (
    is      => 'ro',
    isa     => 'CIF::Type::UpperCaseStr',
    coerce  => 1,
    reader  => 'get_citycode',
);

has 'longitude' => (
    is      => 'ro',
    isa     => 'Num',
    reader  => 'get_longitude',
);

has 'latitude' => (
    is      => 'ro',
    isa     => 'Num',
    reader   => 'get_latitude',
);

has 'geolocation' => (
    is => 'ro',
);

has 'timezone' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_timezone',
);

has 'subdivision' => (
    is      => 'ro',
    isa     => 'Str',
    coerce  => 1,
    reader  => 'get_subdivision',
);

1;
