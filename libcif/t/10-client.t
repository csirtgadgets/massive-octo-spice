use Test::More;

use strict;
use warnings;
use 5.011;

BEGIN { 
    use_ok('CIF::Client');
};

use Data::Dumper;

my $obj = CIF::Client->new({
    no_log  => 1,
    remote  => 'http://localhost',
});
warn Dumper($obj);

my $ret;

#while ( 1 ) {
#    my $random = int( rand ( 10_000 ) );
#    say 'sending :'.$random;
#    $ret = $obj->send({ data => 'hello: '.$random });
#    unless($ret){
#        say 'failed...';
#        last;
#    }
#    select( undef, undef, undef, 1);
#}

done_testing();
