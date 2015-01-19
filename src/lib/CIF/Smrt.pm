package CIF::Smrt;

use strict;
use warnings;

use Mouse;
use CIF qw/observable_type hash_create_random hash_create_static normalize_timestamp is_ip init_logging $Logger/;
use CIF::Client; ## eventually this will go to the SDK
use CIF::ObservableFactory;
use CIF::Smrt::ParserFactory;
use CIF::Smrt::Fetcher;
use File::Path qw(make_path);
use File::Spec;
use File::Type;
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);
use JSON::XS;
use Try::Tiny;
use URI::Escape;

use Data::Dumper;
use Carp::Assert;

use constant {
    RE_DECODE_TYPES => qr/zip|lzf|lzma|xz|lzop/,
    TMP             => $CIF::VarPath.'/smrt/cache',
    MAX_DT          => '2100-12-31T23:59:59Z' # if you're still using this by then, God help you.
};

has [qw(ignore_journal config is_test other_attributes test_mode handler rule tmp)] => (
    is      => 'ro',
);

has [qw(fetcher parser tmp_handle)] => (
    is          => 'ro',
    lazy_build  => 1,
);

has 'not_before'    => (
    is          => 'ro',
    isa         => 'CIF::Type::DateTimeInt',
    coerce      => 1,
    default     => sub { DateTime->today()->epoch() },
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

    ## TODO
    $Logger->info('starting at: '.
        DateTime->from_epoch(epoch => $self->not_before)->datetime(),'Z'
    );

    # fetch
    $Logger->debug('fetching...');
    my $data = $self->fetcher->process();
    unless($data){
        $Logger->debug('no data.. skipping..');
        return [];
    }
    
    $Logger->debug('cache: '.$self->tmp_handle);
    
    # decode
    $Logger->debug('decoding..');
    $data = $self->decode($data);
    
    # parse
    $Logger->debug('parsing...');
    
    $data = $self->parser->process($data);

    unless($self->ignore_journal){
        # log
        $Logger->debug('checking journal');
        $data = $self->check_journal($data);
        
        $Logger->debug('writing journal...');
        $self->write_journal($data); ##TODO -- should this be after?
    }
    # build
    $Logger->info('processing events: '.($#{$data} + 1));
    my @array;
    
    my $reporttime = DateTime->from_epoch(epoch => time());
    $reporttime = $reporttime->ymd().'T'.$reporttime->hms().'Z';
    
    my $ts;
    my $otype;
    foreach (@$data){
        $otype = observable_type($_->{'observable'});
        next unless($otype);
        
        $_->{'reporttime'} = $reporttime unless($_->{'reporttime'});

        $ts = $_->{'firsttime'} || $_->{'lasttime'} || $_->{'reporttime'} || MAX_DT;
        $ts = normalize_timestamp($ts)->epoch();
        
        next unless($self->not_before <= $ts );
        $_ = $self->rule->process({ data => $_ });

        push(@array,$_);
    }

    $Logger->info('processed events: '.($#array + 1));

    return \@array;
}

sub _journal_hash {
    my $data = shift;

    my $today = DateTime->today();
    
    my $err;
    $data->{'observable'} = uri_escape_utf8($data->{'observable'},'\x00-\x1f\x7f-\xff'); # be very specific about this.
    
    my $x = JSON::XS->new->canonical->encode($data);

    try {
        $x = hash_create_static($today->epoch().$x);
    } catch {
        $err = shift;
        $Logger->error($err);
        $Logger->error($x);
    };
    
    return $x;
}

sub write_journal {
    my $self = shift;
    my $data = shift;
    
    my $today = DateTime->today();
    my $log = File::Spec->catfile($self->tmp(),$today->ymd('').'.log');
    my $f = IO::File->new(">>".$log);
    
    my $array; my $tmp;
    foreach (@$data){
        $tmp = _journal_hash($_);
        print $f $tmp."\n";
        push(@$array,$_);
    }
    $f->close();
}

sub check_journal {
    my $self = shift;
    my $data = shift;
    
    my $today = DateTime->today();
    
    my $log = File::Spec->catfile($self->tmp(),$today->ymd('').'.log');
    
    $Logger->debug('using log: '.$log);
  
    my $f = IO::File->new("<".$log);
    my $exists;
    if($f){
        while(<$f>){
            chomp();
            $exists->{$_} = 1;
        }
        $f->close();
    }
    
    $f = IO::File->new(">>".$log);
    
    my $array; my $tmp;
    foreach (@$data){
        $tmp = _journal_hash($_);
        next if($exists->{$tmp});
        push(@$array,$_);
    }
    $f->close();
    return $array;
}


__PACKAGE__->meta->make_immutable();

1;
