use strict;

use Test::More;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules/;
my $rule = 'rules/default/alexa.yml';
my @feeds = qw(top10);

$rule = parse_rules($rule,'top10');

ok($rule);

$rule->set_not_before('10000 days ago');
$rule->{'defaults'}->{'remote'} = 'testdata/alexa.com/top-1m.csv';

my @rules = ($rule);
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
