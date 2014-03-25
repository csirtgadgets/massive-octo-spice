use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN {
    use_ok('CIF::Message');
};

my $msg = CIF::Message->new({
    rtype   => 'ping',
    mtype   => 'request',
    Token   => 1234,
});

ok($msg,'ping test');

$msg = CIF::Message->new({
    rtype   => 'search',
    mtype   => 'request',
    Token   => 1234,
    Query   => '10.0.0.0/8',
});

ok($msg,'search test');

done_testing();
