use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN {
    # travis-ci doesn't do random well yet
    if($ENV{'CI_BUILD'}){
        plan( skip_all => 'very little entropy support');
    } else {
        use_ok('CIF');
    }
};

use CIF qw/hash_create_random/;

ok(hash_create_random(), 'creating sample hash');

done_testing();
