use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::ObservableFactory');
};

use CIF qw/is_ip is_url is_ip_private is_fqdn is_hash/;

my @data = (
    '192.168.1.1',
    '2001:1608:10:147::21',
    '2001:4860:4860::8888'
);

foreach (@data){
    ok(!is_url($_), 'testing: '.$_);
}

@data = (
    'example.com',
    '1.2.3.4.com',
    'xn----jtbbmekqknepg3a.xn--p1ai',
    'www',
);

foreach (@data){
    ok(!is_url($_), 'testing: '.$_);
}

@data = (
    '192.168.1.1/1.html',
    'http://www41..xzmnt.com',
);

foreach (@data){
    ok(!is_url($_), 'testing: '.$_);
}

@data = (
    'http://12.12.12.12/example/test.html',
    'http://fb.co',
    'http://fb.com/1234.html',
    'http://www.test.com/example.htm ',
    'http://example.org/?q=12&1=2',
    'http://192.168.1.1/24/1.html'
);

foreach (@data){
    ok(is_url($_), 'testing: '.$_);
}

foreach (@data){
    ok(is_url($_), 'testing: '.$_);
    $_ = CIF::ObservableFactory->new_plugin({
        observable => $_
    });
    ok($_->{'otype'} eq 'url', 'testing otype: '.$_->{'observable'});
}
done_testing();
