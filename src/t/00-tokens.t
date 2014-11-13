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

done_testing();
