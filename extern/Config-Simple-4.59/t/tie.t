#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
use FindBin '$RealBin';
use File::Spec;
BEGIN {
  plan tests => 6;
}

require Config::Simple;
Config::Simple->import('-strict');
ok(1);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $file = File::Spec->catfile($RealBin, 'project.ini');

my $obj = undef;

ok($obj = tie my %Config, 'Config::Simple', $file);
ok( exists $Config{'Project\1.Count'} );
ok( $Config{'Project\0.Name'} eq 'Default' );
ok( scalar( keys %Config ) == 24 );
delete $Config{'Project\1.Count'};
ok ( exists($Config{'Project\1.Count'}) ? 0 : 1);

#print tied(%Config)->dump;

