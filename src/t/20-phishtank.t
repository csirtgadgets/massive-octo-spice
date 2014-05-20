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
        config  => 'rules/default/phishtank.cfg',
        feed    => 'urls',
        override    => {
            remote  => 'testdata/phishtank.com/online-valid.json.gz',
            not_before  => '10000 days ago',
        }
    },
    {
        config  => 'rules/default/phishtank.cfg',
        feed    => 'urls',
        override    => {
            values      => 'null,observable,alternativeid,detecttime,null,null,null,description',
            skip_first  => 1,
            parser      => 'csv',
            remote      => 'testdata/phishtank.com/online-valid.csv',
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
        test_mode       => 1,
    });
    ok($#{$ret},'testing for results...');
    $ret = $smrt->get_client->submit({
        Observables => $ret,
    });
    ok($#{$ret},'testing subission results: '.(($#{$ret})+1));
}

done_testing();
