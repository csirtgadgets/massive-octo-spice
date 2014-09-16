use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules normalize_timestamp/;
my $rule = 'rules/default/drg.yml';
my @rules;

my $vnc = parse_rules($rule,'vnc');
$vnc->set_not_before('10000 days ago');
$vnc->{'defaults'}->{'remote'} = 'testdata/dragonresearchgroup.org/vncprobe.txt';

push(@rules,$vnc);

my $ssh = parse_rules($rule,'ssh');
$ssh->set_not_before('10000 days ago');
$ssh->{'defaults'}->{'remote'} = 'testdata/dragonresearchgroup.org/sshpwauth_small.txt';

push(@rules,$ssh);

foreach (@rules){
    my $ret = CIF::Smrt->new({
        rule            => $_,
        tmp             => '/tmp',
        ignore_journal  => 1,
    })->process();
    ok($#{$ret} >= 0,'testing for results for: '.$_->{'feed'});
    ok(@$ret[0]->{'observable'} =~ /(141.52.251.250|63.230.14.171)/, 'testing output...');
}

done_testing();
