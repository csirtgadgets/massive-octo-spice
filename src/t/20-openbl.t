use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules normalize_timestamp/;
my $rule = 'rules/default/openbl.yml';

$rule = parse_rules($rule, 'base_1days');

$rule->set_not_before('10000 days ago');
$rule->{'defaults'}->{'remote'} = 'testdata/openbl.org/base_1days.txt';

my $ret = CIF::Smrt->new({
        rule            => $rule,
        tmp             => '/tmp',
        ignore_journal  => 1,
        not_before      => '2010-01-01',
})->process();

ok($ret && $#{$ret} >= 0,'testing for results for: '.$_->{'feed'});
ok(@$ret[-1]->{'observable'} eq '103.31.75.15', 'testing output...');
ok($#{$ret} == 117);

done_testing();
