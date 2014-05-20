package CIF::Router::Request;

use strict;
use warnings;

use Mouse::Role;

requires qw(process);

has 'storage_handle' => (
    is      => 'ro',
    reader  => 'get_storage_handle',
);

has 'auth_handle' => (
    is      => 'ro',
    reader  => 'get_auth_handle',
);

1;