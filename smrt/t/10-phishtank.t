use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

my $rules = [
    {
        config  => 'rules/default/phishtank.cfg',
        rule    => 'urls',
        override    => {
            remote  => 'file://../testdata/phishtank.com/online-valid.json.gz',
        }
    },
    {
        config  => 'rules/default/phishtank.cfg',
        rule    => 'urls',
        override    => {
            values      => 'null,observable,alternativeid,detecttime,null,null,null,description',
            skip_first  => 1,
            parser      => 'csv',
            remote      => 'file://../testdata/phishtank.com/online-valid.csv',
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
