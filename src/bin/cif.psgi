#!/usr/bin/env perl
use Mojo::Base -strict;

use File::Basename 'dirname';
use File::Spec;

$ENV{MOJO_HOME} = join '/', File::Spec->splitdir(dirname(__FILE__)), '..', 'lib/perl5/CIF';

# Check if Mojolicious is installed;
die <<EOF unless eval { require Mojolicious::Commands; 1 };
It looks like you don't have the Mojolicious framework installed.
Please visit http://mojolicio.us for detailed installation instructions.

EOF

use CIF qw($Logger init_logging);

my $debug = $ENV{'DEBUG'} || 'DEBUG';

init_logging(
    {
        level       => $debug,
        category	=> 'cif.psgi',
    },
);

# Start commands
Mojolicious::Commands->start_app('CIF::REST');