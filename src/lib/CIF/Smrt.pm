package CIF::Smrt;

use strict;
use warnings;

use Mouse;
use CIF qw/hash_create_random normalize_timestamp is_ip init_logging $Logger/;
use CIF::Client; ## eventually this will go to the SDK
use CIF::ObservableFactory;
use CIF::RuleFactory;
use CIF::Smrt::ParserFactory;
use CIF::Smrt::Fetcher;
use File::Path qw(make_path);
use File::Spec;
use File::Type;
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);

use Data::Dumper;
use Config::Simple;
use Carp::Assert;

use constant {
    RE_DECODE_TYPES => qr/zip|lzf|lzma|xz|lzop/,
    TMP             => $CIF::VarPath.'/smrt/cache',
    MAX_DT          => '2100-12-31T23:59:59Z' # if you're still using this by then, God help you.
};

has [qw(config is_test other_attributes test_mode handler rule tmp)] => (
    is      => 'ro',
);

has [qw(fetcher parser tmp_handle)] => (
    is          => 'ro',
    lazy_build  => 1,
);

sub _build_tmp_handle {
    my $self = shift;
    my $tmp = $self->tmp.'/'.$self->rule->defaults->{'provider'}.'-'.$self->rule->{'feed'};
    assert(-w $tmp, 'temp space is not writeable by user, or file exists and is not owned by user: '.$tmp) if(-e $tmp);
    return $tmp;
}

sub _build_fetcher {
    my $self = shift;

    return CIF::Smrt::Fetcher->new({
        rule    => $self->rule,
        tmp     => $self->tmp_handle,
    });
}

sub _build_parser {
    my $self = shift;
    return CIF::Smrt::ParserFactory->new_plugin({ rule => $self->rule });
}

sub BUILD {
    my $self = shift;
    init_logging({ level => 'ERROR'}) unless($Logger);
    
    make_path($self->tmp, { mode => 0770 }) unless(-e $self->tmp);
}

sub decode {
    my $self = shift;
    my $data = shift;
 
    my $ftype = File::Type->new->mime_type($data);
    $Logger->debug('data is of type: '.$ftype);
    
    if($ftype =~ RE_DECODE_TYPES){
        my $buffer;
        my $status = anyuncompress \$data => \$buffer or die $AnyUncompressError;
        return $buffer;
    }
    
    return $data;
}

sub process {
    my $self = shift;
    my $args = shift;
    
    #$Logger->debug(Dumper($self));
    #$Logger->debug(Dumper($self->rule_handle));
    
    $Logger->info('starting at: '.
        DateTime->from_epoch(epoch => $self->rule->not_before)->datetime(),'Z'
    );

    # fetch
    $Logger->debug('fetching...');
    my $data = $self->fetcher->process();
    
    $Logger->debug('cache: '.$self->tmp_handle);
    
    # decode
    $Logger->debug('decoding..');
    $data = $self->decode($data);
    
    # parse
    $Logger->debug('parsing...');
    $data = $self->parser->process($data);
    
    # build
    $Logger->info('processing events: '.($#{$data} + 1));
    my @array;
    
    my $ts;
    foreach (@$data){
        $ts = $_->{'detecttime'} || $_->{'lasttime'} || $_->{'reporttime'} || MAX_DT;
        $ts = normalize_timestamp($ts)->epoch();

        next unless($self->rule->not_before <= $ts );
        $_ = $self->rule->process({ data => $_ });
        push(@array,$_);
    }
    $Logger->info('processed events: '.($#array + 1));
    return \@array;
}

sub process_file {
    my $self = shift;
    my $args = shift;
    
    ##TODO - refactor
    my $ts = $args->{'ts'} || DateTime->today();
    my ($vol,$dir) = File::Spec->splitpath($args->{'file'});
    my $log = File::Spec->catfile($self->tmp(),$ts->ymd('').'.log');
    
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
