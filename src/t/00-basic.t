use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::Router');
};

use CIF qw/is_ip is_url/;

ok(is_ip('192.168.1.1'),'testing ip address...');
ok(is_url('http://12.12.12.12/example/test.html'), 'testing url...');

done_testing();
