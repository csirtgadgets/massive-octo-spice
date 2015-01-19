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

use CIF qw/is_ip is_url is_ip_private is_fqdn/;

warn is_ip('192.168.1.1');

ok(is_ip('192.168.1.1'),'testing ip address...');
ok(is_url('http://12.12.12.12/example/test.html'), 'testing url...');

ok(is_ip_private('192.168.1.1'),'testing private ip...');
ok(!is_ip_private('128.205.1.1'),'testing public ip...');

ok(!is_ip('192.168.1.1.example.com'));
ok(is_fqdn('192.168.1.1.example.com'));
ok(is_url('192.168.1.1/html/1.thm'));
ok(!is_url('192.168.0.0/24'));

done_testing();
