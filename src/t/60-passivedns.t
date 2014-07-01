use 5.011;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok('CIF');
    use_ok('CIF::Smrt');
    use_ok('CIF::ObservableFactory');
};

my $rules = [
    {
        config  => 'rules/example/passivedns.cfg.example',
        feed    => 'gamelinux',
        tmp => '/tmp',
    },
];

my $smrt = CIF::Smrt->new({
    client_config => {
        remote          => 'dummy',
        Token           => '1234',
    },
     tmp => '/tmp',
});

my $ret;
foreach my $r (@$rules){
    $ret = $smrt->process({ 
        rule        => $r,
        test_mode   => 1,
        tmp => '/tmp',
    });
    map { $_ = CIF::ObservableFactory->new_plugin($_) } (@$ret);
    ok($#{$ret},'testing for results...');
}

done_testing();
