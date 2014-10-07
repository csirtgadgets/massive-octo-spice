use strict;
use warnings;
use 5.011;

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Client');
    use_ok('CIF::Message::Token');
};

my $cli = CIF::Client->new({ token => 1234 });
my $ret;

#$ret = $cli->token_create({
#    admin   => 1,
#    Alias   => 'wes@barely3am.com',
#    Description => 'teh pwn!',
#});

$ret = $cli->token_list({
    alias   => 'wes@barely3am.com',
});

warn Dumper($ret);

done_testing();
