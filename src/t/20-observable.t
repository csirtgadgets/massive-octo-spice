use Test::More;

use strict;
use warnings;
use 5.011;

use Data::Dumper;

BEGIN {
    use_ok('CIF::ObservableFactory');
};

my $ob = '10.0.0.1';

my $obs = {
    id          => 1234,
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
ok($msg);

done_testing();
