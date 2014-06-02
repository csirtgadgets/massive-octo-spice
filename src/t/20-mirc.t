use strict;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

my $rules = [
    {
        config  => 'rules/default/00_mirc_whitelist.cfg',
        feed    => 'domains',
        override    => {
            remote    => 'testdata/mirc.com/servers.ini',
            not_before  => '10000 days ago',
            tmp => '/tmp',
            id  => '1234',
        },
         tmp => '/tmp',
    },
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
    ok($#{$ret},'testing for results...');
}

done_testing();
