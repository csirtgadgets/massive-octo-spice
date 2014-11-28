package CIF::ObservableAddress;

use strict;
use warnings;

use Mouse::Role;

with 'CIF::Observable';

has 'portlist' => (
    is        => 'rw',
    isa       => 'Maybe[CIF::Type::PortList]',
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
    reader  => 'get_application',
);

has 'cc'   => (
    is      => 'ro',
    isa     => 'Maybe[CIF::Type::UpperCaseStr]',
    coerce  => 1,
    reader  => 'get_cc',
);

has 'rdata' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    coerce  => 1,
);

has 'rtype' => (
    is  => 'ro'
);

1;
