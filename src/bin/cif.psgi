#!/usr/bin/env perl
use Mojo::Base -strict;

##TODO - http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Plack-middleware

use File::Basename 'dirname';
use File::Spec;

##TODO- this should all be baked into the configure.ac ?
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'lib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'lib/perl5';

my $base = join '/', File::Spec->splitdir(dirname(__FILE__));

if(-e $base.'/../lib/perl5'){
    $base .= '/../lib/perl5/CIF';
} else {
    $base .= '/../lib/CIF';
}
$ENV{MOJO_HOME} = $base;

# Check if Mojolicious is installed;
die <<EOF unless eval { require Mojolicious::Commands; 1 };
It looks like you don't have the Mojolicious framework installed.
Please visit http://mojolicio.us for detailed installation instructions.

EOF

use CIF qw($Logger init_logging);

my $debug = $ENV{'DEBUG'} || 'INFO';

init_logging(
    {
        level       => $debug,
        category    => 'cif.psgi',
    },
);



$Logger->info('starting CIF::REST');

# Start commands
Mojolicious::Commands->start_app('CIF::REST');