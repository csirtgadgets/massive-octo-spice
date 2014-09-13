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

use CIF qw/parse_config/;

my $rule = parse_config('rules/example/passivedns.yml');

ok($rule);

$rule->{'not_before'} = '10000 days ago';

my @rules;

foreach my $feed (qw/gamelinux/){
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
    ok($#{$ret},'testing for results...');
}

done_testing();
