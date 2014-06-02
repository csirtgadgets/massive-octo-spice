use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN { 
    use_ok('CIF::Client');
};

use Data::Dumper;

my $obj = CIF::Client->new({
    no_log  => 1,
    remote  => 'http://localhost',
});

ok($obj);

done_testing();
