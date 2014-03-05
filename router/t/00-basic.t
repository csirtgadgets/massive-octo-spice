use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Router');
};

say 'starting router...';
my $obj = CIF::Router->new({
    encoder_pretty  => 1,
    auth    => {
        plugin => 'sql',
    },
    storage => {
        plugin => 'elasticsearch',
    },
});

ok(ref($obj) eq 'CIF::Router','testing router...');

done_testing();