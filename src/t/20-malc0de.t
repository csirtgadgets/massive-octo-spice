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

#urls

my $rule = 'rules/default/malc0de.yml';

$rule = parse_rules($rule,'urls');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'testdata/malc0de.com/rss.xml';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@$ret[-1]->{'observable'} eq 'http://117.21.175.128/nut40a361.exe', 'testing output...') or diag Dumper($ret);

#malware (hashes)

$rule = 'rules/default/malc0de.yml';

$rule = parse_rules($rule,'malware');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'testdata/malc0de.com/rss.xml';

$ret = CIF::Smrt->new({
  rule            => $rule,
  tmp             => '/tmp',
  ignore_journal  => 1,
  not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@$ret[-1]->{'observable'} eq '28c31288a6ade00531854e145ad0b4c2', 'testing output...') or diag Dumper($ret);

done_testing();
