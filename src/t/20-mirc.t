use strict;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules/;

my $rule = parse_rules('rules/default/mirc.yml','domains');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'testdata/mirc.com/servers.ini';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
})->process();
ok($#{$ret} >= 0,'testing for results...');

done_testing();
