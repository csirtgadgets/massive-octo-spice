package CIF::Smrt::Fetcher::File;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use File::Type;

# other
use URI::file;
use IO::File;

with 'CIF::Smrt::Fetcher';

sub understands {
    my $self = shift;
    my $args = shift;

    return 1 if($args->{'rule'}->get_remote() =~ /^file:\/\//);
    return 1 if(-e $args->{'rule'}->get_remote());
    return 0;
}

sub process {
    my $self = shift;
    my $args = shift;
    
    my $file = URI::file->new_abs($self->get_rule()->get_remote());

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

__PACKAGE__->meta->make_immutable();

1;