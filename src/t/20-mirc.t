use strict;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Rule');
};

use CIF qw/parse_config/;
use Data::Dumper;

my $rule = parse_config('rules/default/mirc.yml');

ok($rule);

$rule->{'not_before'} = '10000 days ago';
$rule->{'feeds'}->{'domains'}->{'remote'} = 'testdata/mirc.com/servers.ini';

my $r = {%$rule};
$r->{'defaults'} = { %{$r->{'defaults'}}, %{$r->{'feeds'}->{'domains'}} };
$r->{'feed'} = 'domains';

my $ret = CIF::Smrt->new({
    rule    => CIF::Rule->new($r),
    tmp     => '/tmp',
})->process();

ok($#{$ret},'testing for results...');

done_testing();
