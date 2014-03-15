use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN {
    if($ENV{'CIF_PERL_NO_THREADS'}){
        plan( skip_all => 'no thread support');
    } else {
        use threads;
        use_ok('CIF');
        use_ok('CIF::StorageFactory');
    }
};
our $debug = 1;
my $store = CIF::StorageFactory->new_plugin({
    plugin => 'elasticsearch',
});

my $rv;
my $ob = [
        {
            tags         => ['botnet','zeus','fqdn'],
            observable  => 'example.com',
            group       => 'everyone',
            confidence  => 85
        },
        {
            tags        => ['botnet','citidel'],
            observable  => 'ex2.org',
            group       => 'group1',
            confidence  => 85,
            
        }
    ];
$rv = $store->process({ Observables  => $ob });


my $q = 'tags/zeus,fqdn';

$rv = $store->process({
    Query   => $q,
    limit   => 500,
    #group   => 'group1',
    confidence  => 84,
});

warn Dumper($rv);