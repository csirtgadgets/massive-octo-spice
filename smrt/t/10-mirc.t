use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

use CIF qw/hash_create_random/;

my $rules = [
    {
        config  => 'rules/default/00_mirc_whitelist.cfg',
        rule    => 'domains',
        override    => {
            remote    => 'file://../testdata/mirc.com/servers.ini',
        },
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
        encoder_pretty  => 1,
    });
    ok($#{$ret},'testing for results...');
    $ret = $smrt->get_client->submit({
        Observables => $ret,
    });

    ok($#{$ret},'testing subission results: '.(($#{$ret})+1));
}

done_testing();
