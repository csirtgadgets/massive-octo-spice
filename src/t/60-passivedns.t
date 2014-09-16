use 5.011;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Data::Dumper;

BEGIN {
    if($ENV{'CI_BUILD'}){
        plan( skip_all => 'skipping for CI build' );
    } else {
        use_ok('CIF');
        use_ok('CIF::Smrt');
        use_ok('CIF::Rule');
    }
};

use CIF qw/parse_rules/;

my $rule = parse_rules('rules/example/passivedns.yml','gamelinux');

ok($rule);

$rule->set_not_before('10000 days ago');

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
})->process();
ok($#{$ret},'testing for results...');

done_testing();
