use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules normalize_timestamp/;
my $rule = 'rules/default/ransomware_abuse_ch.yml';

$rule = parse_rules($rule, 'ransomware');

$rule->set_not_before('10000 days ago');
$rule->{'defaults'}->{'remote'} = 'testdata/abuse.ch/ransomware.csv';

my $ret = CIF::Smrt->new({
        rule            => $rule,
        tmp             => '/tmp',
        ignore_journal  => 1,
        not_before      => '2010-01-01',
})->process();

ok($ret && $#{$ret} >= 0,'testing for results for: '.$rule->{'feed'});

ok(@$ret[0]->{'observable'} eq 'http://89.108.85.163/main.php', 'testing output...');
ok(@$ret[0]->{'description'} eq 'Locky C2', 'testing output...');
ok(@$ret[0]->{'additional_data'}[0]->{'threat'} eq 'C2', 'testing output...');

ok(@$ret[-1]->{'observable'} eq 'http://hrfgd74nfksjdcnnklnwefvdsf.materdunst.com/', 'testing output...');
ok(@$ret[-1]->{'description'} eq 'TeslaCrypt Payment Site', 'testing output...');
ok(@$ret[-1]->{'additional_data'}[0]->{'threat'} eq 'Payment Site', 'testing output...');

ok($#{$ret} == 13);

done_testing();
