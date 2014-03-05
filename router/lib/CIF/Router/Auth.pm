package CIF::Router::Auth;

use strict;
use warnings;

use Mouse::Role;

requires qw(
    understands
    process
);

1;