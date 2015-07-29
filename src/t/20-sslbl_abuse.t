use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules normalize_timestamp/;
my $rule = 'rules/default/sslbl_abuse_ch.yml';

## sslipblacklist

$rule = parse_rules($rule, 'sslipblacklist');

$rule->set_not_before('10000 days ago');
$rule->{'defaults'}->{'remote'} = 'testdata/abuse.ch/sslipblacklist.csv';

my $ret = CIF::Smrt->new({
        rule            => $rule,
        tmp             => '/tmp',
        ignore_journal  => 1,
        not_before      => '2010-01-01',
})->process();

ok($ret && $#{$ret} >= 0,'testing for results for: '.$rule->{'feed'});
ok(@$ret[-1]->{'observable'} eq '144.76.232.59', 'testing output...');
ok($#{$ret} == 6);

## dyre_sslipblacklist
$rule = 'rules/default/sslbl_abuse_ch.yml';
$rule = parse_rules($rule, 'dyre_sslipblacklist');

$rule->set_not_before('10000 days ago');
$rule->{'defaults'}->{'remote'} = 'testdata/abuse.ch/dyre_sslipblacklist.csv';

$ret = CIF::Smrt->new({
        rule            => $rule,
        tmp             => '/tmp',
        ignore_journal  => 1,
        not_before      => '2010-01-01',
})->process();

ok($ret && $#{$ret} >= 0,'testing for results for: '.$rule->{'feed'});
ok(@$ret[-1]->{'observable'} eq '162.248.36.17', 'testing output...');
ok($#{$ret} == 9);

done_testing();
