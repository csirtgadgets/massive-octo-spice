package CIF::Storage;

use strict;
use warnings;

use Mouse::Role;

requires qw(
    understands
    process
    shutdown
);

1;