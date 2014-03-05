use Test::More;

use strict;
use warnings;
use 5.011;

use Data::Dumper;

BEGIN {
    use_ok('CIF::ObservableFactory');
};

use CIF qw/hash_create_random/;

my $ob = '10.0.0.1';
$ob = hash_create_random();
$ob = 'http://Example.com/1.htm';

my $obs = {
    observable  => $ob,
    tlp         => 'red',
    lang        => 'en',
    tags        => 'botnet,zeus',
    confidence  => 65,
    group       => 'group1',
    additional_data => [
        {
            type    => 'string',
            meaning => 'meaning',
            content => 'test1234',
        },
    ],
};

my $msg = CIF::ObservableFactory->new_plugin($obs);

warn Dumper($msg);

done_testing();
