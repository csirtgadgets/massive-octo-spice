# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use FindBin ('$RealBin');
use Test::More ('no_plan');
use File::Spec;

BEGIN { 
    use_ok('Config::Simple');
}

my %files   = (
    'guess_syntax.cfg'      => 'simple',
    'bug.cfg'               => 'ini',
    'project.ini'           => 'ini',
    'simple.cfg'            => 'simple',
    'simplified.ini'        => 'ini'
);

while (my ($file, $syntax) = each %files ) {
    my $full_path = File::Spec->catfile($RealBin, $file);
    ok(my $config = Config::Simple->new( $full_path ), "read(): $full_path" );
    ok( $config->syntax eq $syntax, "guess_syntax(): $file  => '$syntax'");
}


my $config = Config::Simple->new( File::Spec->catfile($RealBin, 'simplified.ini') );
ok($config->syntax eq 'ini');
ok($config->{_SUB_SYNTAX} eq 'simple-ini' );



    