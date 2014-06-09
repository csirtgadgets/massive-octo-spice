package CIF::Smrt::Parser;

use strict;
use warnings;

use Mouse::Role;

requires qw(understands process);

has 'content'   => (
    is  => 'ro',
    isa => 'Str',
    reader  => 'get_content',
);

has 'rule'  => (
    is      => 'rw',
    reader  => 'get_rule',
    writer  => 'set_rule',
);

1;
