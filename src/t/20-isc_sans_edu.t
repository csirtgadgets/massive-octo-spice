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

my $rule = 'rules/default/isc_sans_edu.yml';

$rule = parse_rules($rule,'00_domains_high');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'file:./testdata/isc_sans_edu/domains_high.txt';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@{$ret}[-1]->{'observable'} eq 'zzukoni.net');
done_testing();
