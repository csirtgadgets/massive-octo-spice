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

my $rule = 'rules/default/bambenekconsulting_com.yml';
$rule = parse_rules($rule,'c2-dommasterlist');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'file:./testdata/bambenekconsulting.com/c2-domainmasterlist.txt';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@{$ret}[-1]->{'observable'} eq 'a161ac01564e7b9ede1d5b6b555b7d7f35.tk');

$rule = parse_rules($rule,'c2-ipmasterlist');
 
 ok($rule);
 
 $rule->{'defaults'}->{'remote'} = 'file:./testdata/bambenekconsulting.com/c2-ipmasterlist.txt';
 
 my $ret = CIF::Smrt->new({
     rule            => $rule,
     tmp             => '/tmp',
     ignore_journal  => 1,
     not_before      => '2010-01-01',
 })->process();
 
 ok($#{$ret} >= 0,'testing for results...');
 ok(@{$ret}[-1]->{'observable'} eq '31.31.204.59');

done_testing();
