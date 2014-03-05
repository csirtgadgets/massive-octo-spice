use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Message');
};

use CIF qw/hash_create_random/;
use Data::Dumper;

my $token = hash_create_random();

my $msg = CIF::Message->new({
    rtype   => 'query',
    mtype   => 'request',
    Token   => $token,
    query   => '10.0.0.0/8',
});

warn Dumper($msg);

done_testing();
