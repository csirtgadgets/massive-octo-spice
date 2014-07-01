package CIF::Plugin::Binary;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use CIF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    is_binary
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

use Compress::Snappy;
use Carp::Assert;

use constant DEFAULT_MAX_BINARY_SIZE => 1048576; # arbitrary

sub is_binary {
    my $binary = shift;
    
    return if($binary =~ /[\.]+$/);
    
    if(-e $binary){
        assert((-s $binary) <= DEFAULT_MAX_BINARY_SIZE(), 'file too large');
        open(F,$binary) or die('unable to open file: '.$binary.': '.$!);
        $binary = <F>;
        close(F) or die($!);
    }
}

1;