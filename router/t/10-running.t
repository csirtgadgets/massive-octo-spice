use strict;
use warnings;
use 5.011;

use Test::More;

BEGIN {
    # travis-ci doesn't support threads
    if($ENV{'CIF_PERL_NO_THREADS'}){
        plan( skip_all => 'no thread support');
    } else {
        use threads;
        use_ok('CIF');
        use_ok('CIF::Router');
        use_ok('CIF::Client');
    }
};

use Data::Dumper;
use AnyEvent;
use CIF qw/hash_create_random/;

my $storage = 'dummy';
my $auth = 'dummy';

my $t = threads->create('start_router');

my $cli = CIF::Client->new({
    remote          => 'tcp://localhost:'.CIF::DEFAULT_PORT(),
    Token           => hash_create_random(),
    encoder_pretty  => 1,
});

my $ret = $cli->ping();
ok($ret > 0, 'running ping...');

say 'killing router...';
$t->kill('KILL')->detach();

sub start_router {
    my $done = AnyEvent->condvar();
    $SIG{'KILL'} = sub { $done->send(); threads->exit(); };
    
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

    my $ret = $obj->startup();
    
    diag('waiting...');
    $done->recv();
}
        

done_testing();
