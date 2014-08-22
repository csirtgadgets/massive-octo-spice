package CIF::Smrt::Handler::Default;

use warnings;
use strict;

use Mouse;

use CIF::Smrt::FetcherFactory;
use CIF::Smrt::DecoderFactory;
use CIF::Smrt::ParserFactory;
use CIF qw/$Logger/;

with 'CIF::Smrt::Handler';

has 'fetcher'   => (
    is      => 'ro',
    reader  => 'get_fetcher',
);

has 'parser'    => (
    is      => 'ro',
    reader  => 'get_parser',
);

sub understands {
    my $self = shift;
    my $args = shift;
    
    # if there's nothing, it's us
    return 1 unless($args->{'handler'});
    return 1 if($args->{'handler'} eq 'default');
    return 0;
}

around BUILDARGS => sub {
    my $origin  = shift;
    my $self    = shift;
    my $args    = shift;
    
    $args->{'parser'}   = CIF::Smrt::ParserFactory->new_plugin($args);
    $args->{'fetcher'}  = CIF::Smrt::FetcherFactory->new_plugin($args);
    
    return $self->$origin($args);
};

sub fetch {}

sub decode {
    my $self = shift;
    use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);
    
    my $buffer;
    my $status = anyuncompress $file => \$buffer or die $AnyUncompressError;
    
}
    

sub process {
    my $self = shift;
    my $args = shift;
    
    my $tmp = $self->get_tmp().'/'.$self->get_rule()->get_defaults()->{'provider'}.'-'.$self->get_rule()->get_feed();
    assert(-w $tmp, 'temp space is not writeable by user, or file exists and is not owned by user: '.$tmp) if(-e $tmp);
    ##TODO -- umask
    
    $Logger->debug('fetching...');
    my $ret = $self->get_fetcher()->process($args);
    return unless($ret);

    $Logger->debug('determining mime-type');
    my $ftype = File::Type->new()->mime_type(@$ret[0]);
    
    if($ftype =~ /zip|lzf|lzma|xz|lzop/){
        $Logger->debug('decoding...');
        $self->decode();
    }

    $Logger->debug('parsing...');
    $ret = $self->get_parser()->process({ content => $ret });
    
    $Logger->debug('logging the results...');
    

    return $ret;
    
}

sub process_file {
    my $self = shift;
    my $args = shift;
    
    ##TODO - refactor
    my $ts = $args->{'ts'} || DateTime->today();
    my ($vol,$dir) = File::Spec->splitpath($args->{'file'});
    my $log = File::Spec->catfile($self->get_tmp(),$ts->ymd('').'.log');
    
    $Logger->debug('using log: '.$log);
   
    $Logger->debug('file: '.$args->{'file'});
    die "file doesn't exist: ".$args->{'file'} unless(-e $args->{'file'});
    my $file = URI::file->new_abs($args->{'file'});
    unless ($file->scheme() eq 'file') {
        die("Unsupported URI scheme: " . $file->scheme);
    }
    
    # for now, we need to move content around, later on we might pass handles around
    my $fh = IO::File->new("< " . $file->path) || die($!.': '.$file->path);
    my $fh2 = IO::File->new("<".$log);
    my $exists;
    if($fh2){
        while(<$fh2>){
            chomp();
            $exists->{$_} = 1;
        }
        $fh2->close();
    }
    my $wh = IO::File->new(">>".$log);
    
    my $array; my $tmp;
    while (<$fh>){
        chomp();
        $tmp = hash_create_static($ts->epoch().$_);
        next if(!$_ || $exists->{$tmp});
        print $wh $tmp."\n" unless($file->path() =~ /testdata/); ##TODO- workaround for tests
        push(@$array,$_);
    }
    $fh->close();
    $wh->close() if($wh);
    return $array;
}

__PACKAGE__->meta->make_immutable();

1;