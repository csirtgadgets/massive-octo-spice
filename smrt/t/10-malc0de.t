use strict;
use warnings;
use 5.011;

use Test::More skip_all => 'not ready yet, needs xpath stuff fixed';
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

# clean up rule, set defaults vs the processing rules, 

my $rules = [
    {
        config  => 'rules/default/malc0de.cfg',
        feed    => 'url',
        override    => {
            remote  => 'testdata/malc0de.com/rss.xml',
            limit   => 5,
            not_before  => '10000 days ago',
        }
    },
];

my $smrt = CIF::Smrt->new({
    client_config => {
        remote          => 'dummy',
        Token           => '1234',
    },
});

my $ret;
foreach my $r (@$rules){
    $ret = $smrt->process({ 
        rule            => $r,
        is_test         => 1,
        encoder_pretty  => 1,
    });
    ok($#{$ret},'testing for results...');
    $ret = $smrt->get_client->submit({
        Observables => $ret,
    });
    ok($#{$ret},'testing subission results: '.$#{$ret});
}

done_testing();
