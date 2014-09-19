use strict;
use warnings;
use 5.011;

use Test::More skip_all => 'skipping phishtank giving us bad data atm';
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
})->process();
    
ok($#{$ret} >= 0,'testing for results...');

done_testing();
