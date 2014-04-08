use strict;
use warnings;
use 5.011;

use Test::More skip_all => 'not ready yet';
use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

my $rules = [
    {
        config  => 'rules/example/garwarn.cfg',
        feed    => 'blog',
        override    => {
            remote  => 'testdata/garwarn/test.html',
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
    ok($#{$ret},'testing subission results: '.(($#{$ret})+1));
}

done_testing();
