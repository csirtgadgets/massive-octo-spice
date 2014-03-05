use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

my $smrt = CIF::Smrt->new({
    client_config => {
    	remote => 'dummy',
    	Token  => '1234',
    },
});

ok(ref($smrt) eq 'CIF::Smrt', 'testing basic CIF::Smrt creation...');


done_testing();
