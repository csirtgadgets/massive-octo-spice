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
    writer  => 'set_rule',
);

sub process_file {
    my $self = shift;
    my $args = shift;

    my $file = URI::file->new_abs($args->{'file'});
    unless ($file->scheme() eq 'file') {
        die("Unsupported URI scheme: " . $file->scheme);
    }
    
    # for now, we need to move content around, later on we might pass handles around
    my $fh = IO::File->new("< " . $file->path) || die($!.': '.$file->path);
    
    my $array;
    while (<$fh>){
        chomp();
        push(@$array,$_);
    }
    $fh->close();
    return $array;
}

1;