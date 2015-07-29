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

my $file = 'rules/default/bambenekconsulting_com.yml';

## c2-domainmasterlist

my $rule = parse_rules($file,'c2-dommasterlist');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'file:./testdata/bambenekconsulting.com/c2-dommasterlist.txt';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@{$ret}[-1]->{'observable'} eq 'getadobeflashplayer.net');

## c2-ipmasterlist

$rule = parse_rules($file,'c2-ipmasterlist');
 
 ok($rule);
 
 $rule->{'defaults'}->{'remote'} = 'file:./testdata/bambenekconsulting.com/c2-ipmasterlist.txt';
 
 $ret = CIF::Smrt->new({
     rule            => $rule,
     tmp             => '/tmp',
     ignore_journal  => 1,
     not_before      => '2010-01-01',
 })->process();
 
 ok($#{$ret} >= 0,'testing for results...');
 ok(@{$ret}[-1]->{'observable'} eq '192.241.211.213');

done_testing();
