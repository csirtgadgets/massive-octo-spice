use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;

BEGIN { 
    use_ok('CIF::StorageFactory'); 
};

my $obj = CIF::StorageFactory->new_plugin({
    plugin      => 'sql',
    AutoCommit  => 1,
    RaiseError  => 1,
    username    => 'wes',
    password    => 'wes',
    dsn         => 'DBI:SQLite:dbname=cif_auth.db',
});