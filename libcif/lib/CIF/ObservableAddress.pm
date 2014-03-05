package CIF::ObservableAddress;

use strict;
use warnings;


use Mouse::Role;

with 'CIF::Observable';

has 'portlist' => (
  is    => 'rw',
  isa   => 'CIF::Type::PortList'
);

has 'protocol' => (
    is      => 'rw',
    isa     => 'CIF::Type::Protocol',
    coerce  => 1,
);

1;