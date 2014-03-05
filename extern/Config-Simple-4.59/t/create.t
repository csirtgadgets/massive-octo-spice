# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
use FindBin '$RealBin';
use File::Spec;
BEGIN {
  plan tests => 11;
}
require Config::Simple;
ok(1);
Config::Simple->import('-strict');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ini_file = File::Spec->catfile($RealBin, 'new.cfg');

my $cfg = new Config::Simple(syntax=>'ini');
ok($cfg);


$cfg->param("mysql.dsn", "DBI:mysql:db;host=handalak.com");
$cfg->param("mysql.user", "sherzodr");
$cfg->param("mysql.pass", 'marley01');
$cfg->param("site.title", 'sherzodR "The Geek"');
$cfg->param("debug.state", 0);
$cfg->param("debug.delim", "");

ok($cfg->write($ini_file));
ok( -e $ini_file );


#
# There was a bug report, according to which if value of a key evaluates
# to false, (such as "" or 0), Config::Simple wouldn't store them in a file
#

$cfg = Config::Simple->new($ini_file);
ok($cfg);

for (qw/mysql.dsn mysql.user mysql.pass site.title/) {
    ok( $cfg->param($_) );
}

for ( qw/debug.state debug.delim/ ) {
    ok( defined $cfg->param($_) );
}

unlink ( $ini_file );

