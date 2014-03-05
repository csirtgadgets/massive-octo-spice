#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { 
  plan tests => 3;
};
require Config::Simple;

ok(1);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $file = 'dummy-file.cfg';
ok(Config::Simple->new($file) ? 0 : 1);
ok(Config::Simple->new()->read($file) ? 0 : 1);


