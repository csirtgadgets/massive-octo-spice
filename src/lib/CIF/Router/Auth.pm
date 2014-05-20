package CIF::Router::Auth;

use strict;
use warnings;

use Mouse::Role;

requires qw(
    understands
    process
);

has 'handle' => (
    is      => 'ro',
    reader  => 'get_handle',
);

1;