package CIF::Smrt::Handler;

use warnings;
use strict;
use namespace::autoclean;

use Mouse::Role;

requires qw(process fetch);

has 'rule'  => (
    is      => 'ro',
    reader  => 'get_rule',
);

1;