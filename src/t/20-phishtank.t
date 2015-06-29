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

my $rule = parse_rules('rules/default/phishtank.yml','urls');

ok($rule, 'testing rule...');

$rule->set_not_before('10000 days ago');

$rule->{'defaults'}->{'remote'} = 'testdata/phishtank.com/online-valid.json.gz';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();
    
ok($#{$ret} >= 0,'testing for results...');
ok($#{$ret} == 16,'testing for 16 results...');

warn $#{$ret};

done_testing();
