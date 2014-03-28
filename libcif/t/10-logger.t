use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN { 
    use_ok('CIF::Logger');
};

use Data::Dumper;

my $obj = CIF::Logger->new({ level => 'ERROR' });

ok(ref($obj) eq 'CIF::Logger');
ok(!$obj->get_logger->debug('this is a test...'),'testing logger...');
ok($obj->get_logger->error('this is another test'),'testing logger...');

done_testing();
