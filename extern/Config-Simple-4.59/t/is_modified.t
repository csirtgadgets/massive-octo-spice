# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use FindBin '$RealBin';
use File::Spec;
BEGIN { 
  plan tests => 2;
}

require Config::Simple;
ok(1);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cfg_file = File::Spec->catfile($RealBin, 'is_modified.cfg');

my $cfg = new Config::Simple(filename=>$cfg_file)
                        or die Config::Simple->error;
ok($cfg);

$cfg->autosave(1);

$cfg->param('newValue', 'Just a test');

