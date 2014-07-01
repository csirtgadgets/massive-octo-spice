use 5.011;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

my $rules = [
#    {
#        config  => 'rules/example/freeform.cfg.example',
#        feed    => 'garwarn',
#        tmp => '/tmp',
#    },
    {
    	config => 'rules/example/freeform.cfg.example',
    	feed   => 'feye',
    	tmp    => '/tmp',
    }
];

my $smrt = CIF::Smrt->new({
    client_config => {
        remote          => 'dummy',
        Token           => '1234',
    },
     tmp => '/tmp',
});

my $ret;
foreach my $r (@$rules){
    $ret = $smrt->process({ 
        rule        => $r,
        test_mode   => 1,
        tmp => '/tmp',
    });
    warn Dumper($ret);
    ok($#{$ret},'testing for results...');
}

done_testing();
