package CIF::Router::Request;

use strict;
use warnings;

use Mouse::Role;

requires qw(process);

has 'storage_handle' => (
    reader  => 'get_storage_handle',
);

has 'auth' => (is => 'ro');

1;