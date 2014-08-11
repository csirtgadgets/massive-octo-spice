package CIF::ObservableAddress;

use strict;
use warnings;

use Mouse::Role;

with 'CIF::Observable';

has 'portlist' => (
    is        => 'rw',
    isa       => 'CIF::Type::PortList',
    reader    => 'get_portlist',
);

has 'protocol' => (
    is      => 'rw',
    isa     => 'CIF::Type::Protocol',
    coerce  => 1,
    reader  => 'get_protocol',
);

has 'application' => (
    is      => 'ro',
    isa     => 'CIF::Type::LowerCaseStr',
    coerce  => 1,
    reader  => 'get_application',
);

has 'cc'   => (
    is      => 'ro',
    isa     => 'CIF::Type::UpperCaseStr',
    coerce  => 1,
    reader  => 'get_cc',
);

1;
