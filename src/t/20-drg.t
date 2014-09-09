use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_config/;
my $rule = 'rules/default/drg.yml';
my @feeds = qw(ssh vnc);

$rule = parse_config($rule);

ok($rule);

$rule->{'not_before'} = '10000 days ago';
$rule->{'feeds'}->{'vnc'}->{'remote'} = 'testdata/dragonresearchgroup.org/vncprobe.txt';
$rule->{'feeds'}->{'ssh'}->{'remote'} = 'testdata/dragonresearchgroup.org/sshpwauth_small.txt';

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
    ok(@$ret[0]->{'observable'} =~ /(141.52.251.250|63.230.14.171)/, 'testing output...');
}

done_testing();
