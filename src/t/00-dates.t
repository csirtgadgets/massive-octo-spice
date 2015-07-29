use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
};

use CIF qw/normalize_timestamp/;

my $time = '2015-01-01T00:12:55Z';
my $t = normalize_timestamp($time);
    
ok(ref($t) eq 'DateTime');
ok($t->ymd().'T'.$t->hms().'Z' eq $time, 'testing std YYYY-DD-MMTHH:MM:SS');

$time = '2/1/2015';
$t = normalize_timestamp($time);

ok(ref($t) eq 'DateTime');
ok($time eq $t->month.'/'.$t->day.'/'.$t->year);
ok($t->ymd().'T'.$t->hms().'Z' eq '2015-02-01T00:00:00Z');

$time = '29/7/2015';
$t = normalize_timestamp($time);

ok(ref($t) eq 'DateTime');
ok($time eq $t->day.'/'.$t->month.'/'.$t->year, 'testing euro style...');
ok($t->ymd().'T'.$t->hms().'Z' eq '2015-07-29T00:00:00Z');


$time = '29-7-2015';
$t = normalize_timestamp($time);

ok(ref($t) eq 'DateTime');
ok($time eq $t->day.'-'.$t->month.'-'.$t->year, 'testing euro style...');
ok($t->ymd().'T'.$t->hms().'Z' eq '2015-07-29T00:00:00Z');
done_testing();
