use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Meta::GeoIP');
    use_ok('CIF::Meta::BGP');
    use_ok('CIF::ObservableFactory');
};

use CIF qw/$Logger init_logging/;

init_logging({ level => 'DEBUG' });

my $r = CIF::Meta::GeoIP->new();
my $obs = {
    observable  => '128.205.1.1',
};

my $ret = $r->process($obs);

warn Dumper($obs);

$r = CIF::Meta::BGP->new();
$r->process($obs);

warn Dumper($obs);

my $o = CIF::ObservableFactory->new_plugin($obs);

warn Dumper($o);
done_testing();
