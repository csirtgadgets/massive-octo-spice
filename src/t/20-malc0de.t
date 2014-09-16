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

use CIF qw/parse_rules/;

my $rule = 'rules/default/malc0de.yml';

$rule = parse_rules($rule,'urls');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'testdata/malc0de.com/rss.xml';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
})->process();
ok($#{$ret} >= 0,'testing for results...');

done_testing();
