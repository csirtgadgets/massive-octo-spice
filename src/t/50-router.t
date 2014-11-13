use strict;
use warnings;

use Test::More;

BEGIN {
    if($ENV{'CI_BUILD'}){
        plan( skip_all => 'skipping for CI build' );
    } else {
        use_ok('CIF');
        use_ok('CIF::Router');
        use_ok('CIF::Client');
    }
};

use AnyEvent;

my $storage = 'dummy';

my $pid = fork();

if($pid == 0){
    start_router();
} else {
    diag('starting client');
    my $cli = CIF::Client->new({
        remote          => 'tcp://localhost:'.CIF::DEFAULT_PORT(),
        token           => '1234',
        encoder_pretty  => 1,
    });
    diag('running ping...');
    my $ret = $cli->ping();
    ok($ret > 0, 'testing ping...');
    
    diag('killing router...');
    kill KILL => $pid;
}

sub start_router {
    my $done = AnyEvent->condvar();
    $SIG{'KILL'} = sub { $done->send(); };
    
    diag('starting router...');
    my $obj = CIF::Router->new({
        encoder_pretty  => 1,
        storage         => $storage,
    });

    my $ret = $obj->startup();
    
    diag('waiting...');
    $done->recv();
}
        

done_testing();
