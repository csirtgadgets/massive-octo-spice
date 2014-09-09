use strict;
use warnings;
use 5.011;

use Test::More;
use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_config/;

my $rule = parse_config('rules/default/phishtank.yml');

ok($rule);

$rule->{'not_before'} = '10000 days ago';
$rule->{'feeds'}->{'urls'}->{'remote'} = 'testdata/phishtank.com/online-valid.json.gz';

my @rules;
foreach my $feed (qw/urls/){
    my $r = {%$rule};
    $r->{'defaults'} = { %{$r->{'defaults'}}, %{$r->{'feeds'}->{$feed}} };
    $r->{'feed'} = $feed;
    $r = CIF::Rule->new($r);
    push(@rules,$r);
}

foreach (@rules){
    my $ret = CIF::Smrt->new({
        rule    => $_,
        tmp     => '/tmp',
    })->process();
    
    ok($#{$ret},'testing for results...');
}

done_testing();
