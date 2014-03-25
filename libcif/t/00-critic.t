use strict;
use warnings;
use 5.011;

use Test::More;
use Test::Perl::Critic;

use English qw(-no_match_vars);

if ( not $ENV{CRITIC} ) {
    my $msg = 'Author test.  Set $ENV{CRITIC} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

all_critic_ok();

done_testing();
