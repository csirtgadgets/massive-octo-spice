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

use CIF qw/is_ip is_url is_ip_private is_fqdn is_hash is_email/;

ok(is_ip('192.168.1.1'),'testing ip address...');

ok(is_ip_private('192.168.1.1'),'testing private ip...');
ok(!is_ip_private('128.205.1.1'),'testing public ip...');

ok(is_ip('2001:1608:10:147::21') eq 'ipv6', 'testing ipv6');
ok(is_ip('2001:da8:8001:2303:b58f:25b4:a6fc:509d') eq 'ipv6', 'testing ipv6');
ok(is_ip('2001:4860:4860::8888') eq 'ipv6', 'testing ipv6');
ok(is_ip('2001:4860:4860::8844') eq 'ipv6', 'testing ipv6');

ok(!is_ip('192.168.1.1.example.com'));
ok(is_fqdn('192.168.1.1.example.com'));
ok(is_fqdn('xn----jtbbmekqknepg3a.xn--p1ai'));
ok(!is_fqdn('www41..xzmnt.com'), 'www41..xzmnt.com');
ok(!is_fqdn('1.0.0.0/1'));

ok(is_fqdn('update-your-account-information--cgi-bin-webscrcmd-login5w80ah.newageastrology.gr'), 'checking domain');
ok(is_fqdn('paypal_update_acouunt.joannebradybeauty.co.uk'), 'checking domain');
ok(is_fqdn('yahoo.uk'), 'checking domain');

ok(!is_ip('1.0.0.0/1'));


ok(is_ip('2001:4860:4860::8888'));

ok(is_hash('73e4ee3b4b76ec339cdf413fdce9c5b8') eq 'md5', 'testing md5');

ok(is_email('wes@csirtgadgets.org'));
ok(!is_email('.now.@forest.ocn.ne.jp'));

done_testing();
