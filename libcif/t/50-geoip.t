use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Meta::GeoIP');
};

use CIF qw/$Logger init_logging/;

init_logging({ level => 'ERROR' });

my $r = CIF::Meta::GeoIP->new({
    file    => 'contrib/GeoLite2-City.mmdb',
});

my $obs = {
    observable  => '128.205.1.1',
};

ok($r->understands($obs), 'understands...');

$r->process($obs);

ok($obs->{'countrycode'});

done_testing();
