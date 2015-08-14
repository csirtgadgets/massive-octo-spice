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

#urls

my $rule = 'rules/default/malc0de.yml';

$rule = parse_rules($rule,'urls');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'testdata/malc0de.com/rss.xml';

my $ret = CIF::Smrt->new({
    rule            => $rule,
    tmp             => '/tmp',
    ignore_journal  => 1,
    not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@$ret[-1]->{'observable'} eq 'http://llsw.download3.utorrent.com/beta/utorrent.40786.installer.exe', 'testing output...') or diag Dumper($ret);
foreach (@{$ret}){
    ok($_->{'otype'} eq 'url', "testing: " . $_->{'observable'});
}

#malware (hashes)

$rule = 'rules/default/malc0de.yml';

$rule = parse_rules($rule,'malware');

ok($rule);

$rule->{'defaults'}->{'remote'} = 'testdata/malc0de.com/rss.xml';

$ret = CIF::Smrt->new({
  rule            => $rule,
  tmp             => '/tmp',
  ignore_journal  => 1,
  not_before      => '2010-01-01',
})->process();

ok($#{$ret} >= 0,'testing for results...');
ok(@$ret[-1]->{'observable'} eq '25ce8b9b6ffd0842b7fd2eb35244d53b', 'testing output...') or diag Dumper($ret);
ok(@$ret[-1]->{'altid'} eq 'http://malc0de.com/database/index.php?search=llsw.download3.utorrent.com', 'testing altid') or diag Dumper($ret);

foreach (@{$ret}){
    ok($_->{'otype'} eq 'md5', "testing: " . $_->{'observable'});
}

done_testing();
