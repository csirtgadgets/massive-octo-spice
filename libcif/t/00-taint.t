#!perl -T

use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

if ( not $ENV{TAINT} ) {
    my $msg = 'Author test.  Set $ENV{TAINT} to a true value to run.';
    plan( skip_all => $msg );
}

use_ok('CIF');

done_testing();