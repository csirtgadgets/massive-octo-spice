use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN { 
    use_ok('CIF::Worker');
};

my $obj = CIF::Worker->new({ publisher => 'localhost' });

ok($obj);

done_testing();
