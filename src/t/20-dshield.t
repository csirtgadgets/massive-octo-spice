use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;
use CIF::ObservableFactory;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules/;

my $rule = 'rules/default/dshield.yml';

$rule = parse_rules($rule,'scanners');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'file:./testdata/dshield.org/block.txt';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@{$ret}[-1]->{'observable'} eq '76.180.236.0');
ok(@{$ret}[-1]->{'mask'} eq '24');

foreach (@{$ret}){
    $_ = CIF::ObservableFactory->new_plugin($_);
}

ok(@{$ret}[-1]->{'observable'} eq '76.180.236.0/24');

done_testing();
