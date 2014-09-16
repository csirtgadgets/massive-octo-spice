use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_config/;
my $rule = 'rules/default/alexa.yml';
my @feeds = qw(top10);

$rule = parse_config($rule);

ok($rule);

$rule->{'not_before'} = '10000 days ago';
$rule->{'feeds'}->{'top10'}->{'remote'} = 'testdata/alexa.com/top-1m.csv';

my @rules;
foreach my $feed (@feeds){
    my $r = {%$rule};
    $r->{'defaults'} = { %{$r->{'defaults'}}, %{$r->{'feeds'}->{$feed}} };
    $r->{'feed'} = $feed;
    $r = CIF::Rule->new($r);

    push(@rules,$r);
}

foreach (@rules){
    my $ret = CIF::Smrt->new({
        rule            => $_,
        tmp             => '/tmp',
        ignore_journal  => 1,
    })->process();
    ok($#{$ret} >= 0,'testing for results...');
    my $found = 0;
    foreach my $r (@$ret){
        if($r->{'observable'} eq 'google.com'){
            $found = 1;
            last;
        }
    }
    ok($found, 'testing for google.com...');
}

done_testing();
