use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules normalize_timestamp/;

my $rule = parse_rules('rules/default/zeustracker.yml','configs');

ok($rule, 'testing rule...');

$rule->set_not_before('10000 days ago');

$rule->{'defaults'}->{'remote'} = 'testdata/abuse.ch/zeustracker-configs.xml';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results: '.$#{$ret});
ok($#{$ret} == 49,'testing for 49 results...');
ok(@$ret[-1]->{'observable'} eq 'http://belorus.tk/logs/file.php');

done_testing();
