#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More;
use FindBin '$RealBin';
use File::Spec;
BEGIN { 
  plan tests => 9;
}

require Config::Simple;
ok(1);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ini_file = File::Spec->catfile($RealBin, 'simple.cfg');

my $cfg = new Config::Simple();
ok($cfg);
ok($cfg->read($ini_file));
ok($cfg->param('FromEmail') eq 'test@handalak.com');
my $vars = $cfg->vars();
ok($vars->{'MinImgWidth'} == 10);
ok($cfg->param(-name=>'ProjectName', -value =>'Config::Simple'));
ok($cfg->param(-name=>'ProjectNames', -values=>['First Name', 'Second name']));
ok(($cfg->param('DBN') =~ m/DBI:/), $cfg->param('DBN'));
ok($cfg->save);

