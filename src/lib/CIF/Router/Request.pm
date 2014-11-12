package CIF::Router::Request;

use strict;
use warnings;

use Mouse::Role;

requires qw(process);

has [qw/user storage nolog msg/] => (
    is  => 'ro',
);

1;