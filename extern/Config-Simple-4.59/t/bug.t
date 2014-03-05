#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict;
use Test;
use Data::Dumper;
use FindBin '$RealBin';
use File::Spec;
BEGIN {
  plan tests => 13;
}

use Config::Simple qw(-strict);
ok(1);
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ini_file = File::Spec->catfile($RealBin, 'bug.cfg');

my $cfg = Config::Simple->new();
ok($cfg);
ok($cfg->read($ini_file));


my $vars = $cfg->vars();

ok(ref($vars) eq 'HASH');
ok(@{$vars->{'Default.Inner_Color'}} == 3);
ok(@{$vars->{'Default.Outer_Color'}} == 3);
ok($vars->{'Default.Outer_Color'}->[1] == 0);
ok($vars->{'Default.Outer_Color'}->[2] == 0.1);

#warn $vars->{'WIN32.My_Music'}, "\n";
ok($vars->{'WIN32.My_Documents'} eq "C:\\DOCUMENTS AND SETTINGS\\SHERZOD RUZMETOV\\MY DOCUMENTS\\");
ok($vars->{'WIN32.My_Music'} eq "C:\\DOCUMENTS AND SETTINGS\\SHERZOD RUZMETOV\\MY DOCUMENTS\\MY MUSIC\\");
ok($vars->{'WIN32.My_Pictures'} eq "C:\\DOCUMENTS AND SETTINGS\\SHERZOD RUZMETOV\\MY DOCUMENTS\\MY PICTURES\\");

$cfg->param('WIN32.My_Money', $vars->{'WIN32.My_Documents'} . "MY MONEY\\");

ok($cfg->param('WIN32.My_Money') eq "C:\\DOCUMENTS AND SETTINGS\\SHERZOD RUZMETOV\\MY DOCUMENTS\\MY MONEY\\");
ok($cfg->write); 

