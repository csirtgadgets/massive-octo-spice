use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
};

# clean up rule, set defaults vs the processing rules, 

my $rules = [
    {
        config  => 'rules/default/drg.cfg',
        feed    => 'ssh',
        override    => {
            remote      => 'testdata/dragonresearchgroup.org/sshpwauth_small.txt',
            not_before  => '10000 days ago',
        },
    },
    {
        config  => 'rules/default/drg.cfg',
        feed    => 'vnc',
        override    => {
            remote      => 'testdata/dragonresearchgroup.org/vncprobe.txt',
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
        rule        => $r,
        test_mode   => 1,
    });
    ok($#{$ret},'testing for results...');
    ok(@$ret[0]->{'observable'} =~ /(141.52.251.250|63.230.14.171)/, 'testing output...');
    $ret = $smrt->get_client->submit({
        Observables => $ret,
    });

    ok(($#{$ret}),'testing subission results: '.(($#{$ret})+1));
}

done_testing();
