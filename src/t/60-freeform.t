use 5.011;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_rules/;

foreach (qw(garwarn feye)){
    my $rule = parse_rules('rules/example/freeform.yml', $_);
    my $ret = CIF::Smrt->new({
        rule            => $rule,
        tmp             => '/tmp',
        ignore_journal  => 1,
    })->process();
    ok($#{$ret},'testing for results for: '.$rule->{'feed'});
}


done_testing();
