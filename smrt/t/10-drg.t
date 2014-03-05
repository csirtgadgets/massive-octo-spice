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

# clean up rule, set defaults vs the processing rules, 

our $debug = 1;
use Data::Dumper;
say 'creating new...';

my $rules = [
    {
        config  => 'rules/default/drg.cfg',
        rule    => 'ssh',
        override    => {
            remote    => 'file://../testdata/dragonresearchgroup.org/sshpwauth_small.txt',
        },
    },
    {
        config  => 'rules/default/drg.cfg',
        rule    => 'vnc',
        override    => {
            remote  => 'file://../testdata/dragonresearchgroup.org/vncprobe.txt',
        }
    },
];

my $smrt = CIF::Smrt->new({
    client_config => {
        remote          => 'dummy',
        Token           => hash_create_random(),
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
    ok(@$ret[0]->{'observable'} =~ /(141.52.251.250|63.230.14.171)/, 'testing output...');
    $ret = $smrt->get_client->submit({
        Observables => $ret,
    });
    ok($#{$ret},'testing subission results: '..(($#{$ret})+1));
}

done_testing();
