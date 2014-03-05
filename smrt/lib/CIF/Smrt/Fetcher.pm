package CIF::Smrt::Fetcher;

use strict;
use warnings;

#TODO make $CIF::Smrt::VERSION work
use constant DEFAULT_AGENT => 'cif-smrt/2.00.00 (csirtgadgets.org)';

use Mouse::Role;

# http://stackoverflow.com/questions/10954827/perl-moose-how-can-i-dynamically-choose-a-specific-implementation-of-a-metho
requires qw(understands process);

has 'agent'     => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_AGENT(),
    reader  => 'get_reader',
);

has 'rule'  => (
    is      => 'rw',
    reader  => 'get_rule',
    writer  => 'get_writer',
);

1;