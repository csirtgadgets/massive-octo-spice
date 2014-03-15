use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;
use AnyEvent;

BEGIN {
    if($ENV{'CIF_PERL_NO_THREADS'}){
        plan( skip_all => 'no thread support');
    } else {
        use threads;
        use_ok('CIF');
        use_ok('CIF::Router');
        use_ok('CIF::Client');
    }
};

#our $debug = 1;
my $storage = 'DUMMY';
my $auth = 'DUMMY';
use CIF qw/hash_create_random/;

my $t = threads->create('start_router');

my $cli = CIF::Client->new({
        remote          => 'tcp://localhost:'.CIF::DEFAULT_PORT(),
        Token           => hash_create_random(),
        encoder_pretty  => 1,
    });

my $ret = $cli->ping();
ok($ret > 0, 'running ping...');

my $observables =  [
        {
            group       => 'group1',
            observable  => 'example.com',
            provider    => 'test.com',
            confidence  => 95,
            message     => 'hihi',
            tags        => 'fqdn,malware',
            tlp         => 'green',
        },
        {
            group       => 'group1',
            observable  => 'example.com',
            provider    => 'test.com',
            confidence  => 95,
            message     => 'hihi',
            tags        => 'fqdn,botnet',
            tlp         => 'amber',
        },
];

diag('submit...');
$ret = $cli->submit({ Observables => $observables });
ok($ret,'submit...');

diag('query...');
$ret = $cli->query({
    query       => 'example.com',
    group       => 'group1',
    limit       => 50,
    confidence  => 25,
});

ok($ret !~ /^ERROR/, 'testing query...');

my $txt = $cli->format({ format => 'table', data => $ret });

say $txt;

say 'killing router...';
$t->kill('KILL')->detach();

sub start_router {
    $SIG{'KILL'} = sub { threads->exit(); };
    
    diag('starting router...');
    my $obj = CIF::Router->new({
        encoder_pretty  => 1,
        storage => {
            plugin => $storage,
        },
        auth    => {
            plugin => $auth,
        }
    });

    my $done = AnyEvent->condvar();

    my $ret = $obj->startup();

    diag('waiting...');
    $done->recv();
}
        

done_testing();
