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

use CIF qw/parse_config $Logger init_logging/;

init_logging(
    {
        level       => 'WARN',
    },
);

my $rule = 'rules/default/malc0de.yml';
my @feeds = qw/urls/;

$rule = parse_config($rule);

ok($rule);

$rule->{'not_before'} = '10000 days ago';
$rule->{'feeds'}->{'urls'}->{'remote'} = 'testdata/malc0de.com/rss.xml';

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
}

done_testing();
