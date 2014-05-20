package CIF::Format;

use strict;
use warnings;


use Mouse::Role;

requires qw/understands process/;

use constant DEFAULT_COLS   => [ 
    'provider','tlp','group','observable','confidence',
    'firsttime','lasttime','reporttime','altid','altid_tlp',
    'tags' 
];

use constant DEFAULT_SORT   => [
    { 'lasttime'    => 'ASC' },
    { 'firsttime'   => 'ASC' },
];

has 'columns'   => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { DEFAULT_COLS() },
    reader  => 'get_columns',
);

has 'sort'  => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { DEFAULT_SORT() },
);

1;