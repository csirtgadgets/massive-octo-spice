package CIF::Smrt::Fetcher;

use strict;
use warnings;

use Mouse::Role;
use CIF qw/$Logger hash_create_static/;
use File::Spec;

use constant DEFAULT_AGENT => 'cif-smrt/'.CIF::VERSION().' ('.CIF::ORG().')';

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

has 'test_mode' => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_test_mode',
);

has 'tmp'   => (
    is      => 'ro',
    reader  => 'get_tmp',
    isa     => 'Str',
);

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
    $wh->close();
    return $array;
}

1;