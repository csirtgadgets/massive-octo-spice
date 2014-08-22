package CIF::Smrt::Handler;

use warnings;
use strict;

use Mouse;

use CIF::Smrt::Fetcher;
use CIF::Smrt::ParserFactory;
use CIF qw/$Logger/;

has [qw(parser)] => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_parser {
    my $self = shift;
    return CIF::Smrt::ParserFactory->new_plugin($args);
}

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