package CIF::ObservableAddress;

use strict;
use warnings;

use Mouse::Role;

with 'CIF::Observable';

has 'portlist' => (
    is        => 'rw',
    #isa       => 'CIF::Type::PortList', ##TODO
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
    isa     => 'Maybe[ArrayRef]',
    coerce  => 1,
    reader  => 'get_application',
);

has 'cc'   => (
    is      => 'ro',
    isa     => 'CIF::Type::UpperCaseStr',
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
