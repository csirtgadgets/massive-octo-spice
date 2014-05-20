package CIF;

use warnings;
use strict;

use constant VERSION => '2.00.00-alpha.0-65-gc6239a3';
our ($MAJOR_VERSION, $MINOR_VERSION, $PATCH, $META) = VERSION =~ /^(\d+)\.(\d+)\.(\d+)-?([\w\.\d]+)?$/;

use constant PROTOCOL_VERSION   => 2.0000001;
use constant ORG                => 'csirtgadgets.org';
use constant DEFAULT_PORT       => 4961;

use constant DEFAULT_FRONTEND_PORT          => DEFAULT_PORT();
use constant DEFAULT_BACKEND_PORT           => (DEFAULT_PORT() + 1);
use constant DEFAULT_PUBLISHER_PORT         => (DEFAULT_PORT() + 2);
use constant DEFAULT_STATS_PUBLISHER_PORT   => (DEFAULT_PORT() + 3);

our $CIF_USER = 'cif';
our $CIF_GROUP = 'cif';

our $BasePath = '/opt/cif';

our $LibPath    = '/opt/cif/lib/perl5';
our $EtcPath    = '/opt/cif/etc';
our $VarPath    = '/opt/cif/var';

our $BinPath    = $BasePath . '/bin';
our $SbinPath   = $BasePath . '/sbin';


our $SmrtRulesPath      = $EtcPath . '/rules';
our $SmrtRulesDefault   = $SmrtRulesPath . '/default';
our $SmrtRulesLocal     = $SmrtRulesPath . '/local';

1;
