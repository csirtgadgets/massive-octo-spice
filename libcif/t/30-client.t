use Test::More;

use feature 'say';
use strict;
use warnings;

no if $] >= 5.018, warnings => "experimental";

BEGIN { 
    use_ok('CIF::Client');
};

use CIF qw/hash_create_random/;

use Data::Dumper;

my $obj = CIF::Client->new({
    remote          => 'dummy',
    format          => 'table',
    Token           => hash_create_random(),
    encoder_pretty   => 1,
});

my $ret = $obj->query({ 
    query       => 'example.com',
    confidence  => 0,
    limit       => 500,
    group       => 'group1',
});

my $txt = $obj->format($ret);

say $txt;

done_testing();
