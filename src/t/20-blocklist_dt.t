use strict;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules normalize_timestamp/;
my $rule = 'rules/default/blocklist_de.yml';

$rule = parse_rules($rule, 'bruteforcelogin');

$rule->set_not_before('10000 days ago');
$rule->{'defaults'}->{'remote'} = 'testdata/blocklist.de/bruteforcelogin.txt';

my $ret = CIF::Smrt->new({
        rule            => $rule,
        tmp             => '/tmp',
        ignore_journal  => 1,
        not_before      => '2010-01-01',
})->process();

ok($ret && $#{$ret} >= 0,'testing for results for: '.$rule->{'feed'});

ok(@$ret[-1]->{'observable'} eq '2001:8d8:830:2100::a1:8d3c', 'testing output...');
ok(@$ret[-1]->{'otype'} eq 'ipv6', 'testing output...');

ok(@$ret[0]->{'observable'} eq '200.84.90.253', 'testing output...');
ok(@$ret[0]->{'otype'} eq 'ipv4', 'testing output...');

ok($#{$ret} == 3);

done_testing();
