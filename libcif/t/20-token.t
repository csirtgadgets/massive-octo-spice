use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Message');
};

use CIF qw/hash_create_random/;
use Data::Dumper;

my $token = hash_create_random();

my $msg = CIF::Message->new({
    rtype       => 'token-create',
    mtype       => 'request',
    Token       => $token,
    
    # data stuff
    token       => hash_create_random(),
    created     => time(),
    expires     => (time() + 84600),
    alias       => 'me@example.com',
    description => 'myapp',
    admin       => 1,
});

warn Dumper($msg);

done_testing();
