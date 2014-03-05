package CIF;

use warnings;
use strict;

our $VERSION = '2.00.00-alpha.1';
our ($MAJOR_VERSION, $MINOR_VERSION, $PATCH, $META) = $VERSION =~ /^(\d+)\.(\d+)\.(\d+)-?([\w\.\d]+)?$/;

$BasePath = '/opt/cif';

$LibPath = $BasePath.'/lib';
$EtcPath = $BasePath.'/etc';

$BinPath    = $BasePath . '/bin';
$SbinPath   = $BasePath . '/sbin';
$VarPath    = $BasePath . '/var';

$SmrtPath = '/opt/cif';
$SmrtLibPath = $SmrtPath . '/lib';

$RouterPath = '/opt/cif';
$RouterLibPath = $RouterPath . '/lib';

1;
