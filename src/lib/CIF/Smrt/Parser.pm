package CIF::Smrt::Parser;

use strict;
use warnings;

use Mouse::Role;

requires qw(understands process);

has [qw(rule)] => (
    is  => 'ro',
);

1;
