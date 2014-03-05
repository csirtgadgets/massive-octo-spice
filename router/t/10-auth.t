use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;
use AnyEvent;
use threads;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Router');
    use_ok('CIF::Client');
};

use CIF qw/hash_create_random/;

say 'starting router...';
my $t = threads->create('start_router');

my $cli = CIF::Client->new({
        remote          => 'tcp://localhost:'.CIF::DEFAULT_PORT(),
        Token           => hash_create_random(),
        encoder_pretty  => 1,
    });

my $ret = $cli->ping();
say $ret;

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

$ret = $cli->submit({ Observables => $observables });

$ret = $cli->query({
    #query       => '62.182.0.0/16',
    #query        => 'umc.su',
    #query       => ['botnet','fqdn'],
    #query => 'botnet',
    #query       => 'botnet,fqdn',
    #query => 'hijacked',
    #query   => 'example.com',
    query       => 'malware',
    group       => 'group1',
    limit       => 50,
    confidence  => 25,
});

my $txt = $cli->format({ format => 'table', data => $ret });

say $txt;

say 'killing router...';
$t->kill('KILL')->detach();

sub start_router {
    $SIG{'KILL'} = sub { threads->exit(); };
    my $obj = CIF::Router->new({
        encoder_pretty  => 1,
        auth    => {
        	plugin => 'sql',
        },
        storage => {
            plugin => 'elasticsearch',
        },
    });

    my $done = AnyEvent->condvar();

    my $ret = $obj->startup();

    say 'waiting...';
    $done->recv();
}
        

done_testing();