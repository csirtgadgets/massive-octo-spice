use Test::More;

use strict;
use warnings;
use 5.011;

use Data::Dumper;

BEGIN {
    use_ok('CIF::ObservableFactory');
    use_ok('CIF::Worker');
};

my $obj = CIF::Worker->new({ publisher => 'localhost', dummy => 1 });

ok($obj);

my $msg = CIF::ObservableFactory->new_plugin({
    observable  => 'example.com',
    confidence  => 85,
    
});

use JSON::XS;

$msg = JSON::XS->new->convert_blessed->encode($msg);

my $ret = $obj->process($msg);

ok($ret);

$msg = CIF::ObservableFactory->new_plugin({
    observable  => '192.168.1.1',
    confidence  => 85,
});

$msg = JSON::XS->new->convert_blessed->encode($msg);

$ret = $obj->process($msg);

ok($ret);

done_testing();
