use strict;
use warnings;

use Test::More;

BEGIN {
    # travis-ci doesn't do random well yet
    if($ENV{'CI_BUILD'}){
        plan( skip_all => 'skipping for CI build' );
    } else {
        use_ok('CIF');
    }
};

use CIF qw/hash_create_random/;

ok(hash_create_random(), 'creating sample hash');

done_testing();
