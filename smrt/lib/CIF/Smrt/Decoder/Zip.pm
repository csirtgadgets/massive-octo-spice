package CIF::Smrt::Decoder::Zip;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use IO::Uncompress::Unzip qw(unzip $UnzipError);

with 'CIF::Smrt::Decoder';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return 0 unless($args->{'type'});
    return 0 if($args->{'type'} =~ /gzip/);
    return 1 if($args->{'type'} =~ /zip/);
    return 0;
}

sub process {
    my $self = shift;
    my $args = shift;
    
    my $file = $args->{'zip_filename'};
    unless($file){
        $args->{'remote'} =~ m/\/([a-zA-Z0-9_]+).zip$/;
        $file = $1;
    }
    
    return unless($file);

    my $unzipped;
    unzip \$args->{'data'} => \$unzipped, Name => $file || die('unzip failed: '.$UnzipError);
    return $unzipped;   
}

__PACKAGE__->meta()->make_immutable();

1;