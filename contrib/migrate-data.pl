#!/usr/bin/perl -w

use strict;
use warnings;

# fix lib paths, some may be relative
BEGIN {
    require File::Spec;
    my @libs = (
        "lib",
        "local/lib",
        "../libcif/lib", # in case we're in -dev mode
        "etc/upgrade/lib",
    );
    my $bin_path;

    for my $lib (@libs) {
        unless ( File::Spec->file_name_is_absolute($lib) ) {
            unless ($bin_path) {
                if ( File::Spec->file_name_is_absolute(__FILE__) ) {
                    $bin_path = ( File::Spec->splitpath(__FILE__) )[1];
                }
                else {
                    require FindBin;
                    no warnings "once";
                    $bin_path = $FindBin::Bin;
                }
            }
            $lib = File::Spec->catfile( $bin_path, File::Spec->updir, $lib );
        }
        unshift @INC, $lib;
    }
}

use Getopt::Std;
use Config::Simple;
use Data::Dumper;
use MIME::Lite;
use JSON::XS;
use threads;
use Time::HiRes qw/nanosleep/;
use ZeroMQ qw/:all/;
use Try::Tiny;
use Compress::Snappy;
use MIME::Base64;
use Iodef::Pb;
use Iodef::Pb::Format;

use CIF qw/debug generate_uuid_ns/;

# control connections
use constant CTRL_CONNECTION            => 'ipc:///tmp/ctrl';
use constant WORKER_CONNECTION          => 'ipc:///tmp/workers';
use constant WRITER_CONNECTION          => 'ipc:///tmp/writer';

# bi-directional pipe for return counts, figure out when we're done
use constant MSGS_PROCESSED_CONNECTION  => 'ipc:///tmp/msgs_processed';
use constant MSGS_WRITTEN_CONNECTION    => 'ipc:///tmp/msgs_written';

# used for SIGINT cleanup
my @pipes = ('msgs_written','workers','msgs_processed','writer','ctrl');

# the lower this is, the higher the chance of 
# threading collisions resulting in a seg fault.
# the higher the thread count, the higher this number needs to be
use constant NSECS_PER_MSEC     => 1_000_000;

use constant DEFAULT_THROTTLE_FACTOR => 1;

my %opts;
getopts('v:hdC:T:t:A:J:B:g:',\%opts);
our $debug = $opts{'d'} || 0;
$debug = $opts{'v'} if($opts{'v'});

my $config      = $opts{'C'} || $ENV{'HOME'}.'/.cif';
my $throttle    = $opts{'T'} || 'low';
my $threads     = $opts{'t'};
my $admin       = $opts{'A'} || 'root';
my $journal     = $opts{'J'} || '/tmp/cif-upgrade-database.journal';
my $batch_size  = $opts{'B'} || 5000;
my $groups      = $opts{'g'} || 'everyone';

die 'remove this warning, this script unstable...';

my $group_map = {};
my @gg = split(',', $groups);
foreach (@gg){
    $group_map->{generate_uuid_ns($_)} = $_;
}

my $tlp_map = {
    'private'       => 'red',
    'need-to-know'  => 'amber',
    'default'       => 'amber',
    'public'        => 'green'
};


die usage() if($opts{'h'});

die usage()."\n\n".'missing config' unless(-e $config);

my $storage = CIF::StorageFactory->new_plugin({ 
    plugin => $storage,
    nodes  => [ 'localhost:9200' ],
});

my $j = check_journal();

$SIG{__DIE__} = \&cleanup;

sub cleanup {
    my $msg = shift;
    if($msg){   
        print $msg."\n";
    } else {
        print "\n\nCaught Interrupt (^C), Aborting\n";
    }
    
    # zmq ipc cleanup in case we SIGINT
    foreach (@pipes){
        my $pipe = './'.$_;
        unlink ($pipe) if(-e $pipe);
    }
    exit(0);
}

$threads = CIF::Legacy::_throttle($throttle) unless($threads);

threads->create('_pager_routine',$config)->join();

debug('done...');
exit(0);

sub usage {
    return <<EOF;
Usage: perl $0 {options...}

Basic:
    -h  --help:             this message

Basic:

    -C  --config:           configuration file, default: $config
    -A  --admin:            admin address, default: $admin
    
Advanced:

    -J  --journal:          journal location, default: $journal
    -B  --batch-size:       default commit size, default: $batch_size
    -g                      specify groups (csv)
    
Debugging:

    -d  --debug
    -v  --verbosity  
    

Examples:

Basic:
    
    $0 -C ~/.cifv1
    $0 -C ~/.cifv1 -A root\@localhost
    
Advanced:
    
    $0 -C ~/.cifv1 -L /tmp/mylock.lock
    $0 -C ~/.cifv1 -B 500
    
EOF
}

sub check_journal { 
    my $value = 0;
    # doesn't exist, create
    if(! -e $journal){
        open(F,'>',$journal) || die('failed to open journal file: '.$!);
        print F '0';
    } else {
        # exists, read in value
        open(F,'<',$journal);
        $value = <F>;
        unless(defined($value)){
            set_journal(0);
            $value = 0;
        }
    }
    close(F);
    
    # return value   
    return $value;
}

sub set_journal {
    my $value = shift;
    
    open(F,'>',$journal);
    print F $value;
    close(F);
    return $value;
}

sub _pager_routine {
    my $config  = shift;
    my $ts      = shift;

    my $context = ZeroMQ::Context->new();
    
    my $ctrl = $context->socket(ZMQ_PUB);
    $ctrl->bind(CTRL_CONNECTION());

    debug('done...') if($::debug);
    
    my $workers = $context->socket(ZMQ_PUSH);
    $workers->bind(WORKER_CONNECTION());
    
    my $msgs_written = $context->socket(ZMQ_PULL);
    $msgs_written->bind(MSGS_WRITTEN_CONNECTION());

    my $msgs_processed = $context->socket(ZMQ_PULL);
    $msgs_processed->bind(MSGS_PROCESSED_CONNECTION());
    
    my ($ret,$err,$data,$tmp,$sth);

    ($err,$ret) = init_db({ config => $config });
    return ($err) if($err);
    
    ($err,$ret) = CIF::Archive->new({ config => $config });
    return $err if($err);
    
    my $archive = $ret;
    $archive->{'limit'} = $batch_size;
    $archive->{'offset'} = 0;
    
    # setup the sql
    my $sql = 'SELECT id,uuid,guid,data FROM archive';
    
    my $jj = check_journal();
    if($jj > 0){ 
       debug('starting at id: '.$jj);
       $archive->load_page_info({ sql => qq{ id > $jj } });
       $sql .= ' WHERE id > '.$jj;
    } else {
        $archive->load_page_info();
    }
    
    $sql .= ' ORDER BY id ASC LIMIT '.$archive->{'limit'}.' OFFSET ?';
    
    my $total = $archive->{'total'};
    debug('total count: '.$total);
    debug('pages: '.$archive->page_count());
    
    if($total){
        $archive->set_sql(custom1 => $sql);
        $sth = $archive->sql_custom1();
        
        # feature of zmq, pub/sub's need a warm up msg
        debug('sending ctrl warm-up msg...');
        $ctrl->send('WARMING_UP');
    
        my $writer_t = threads->create('_writer_routine',$config,$total,$archive->{'limit'})->detach();
        nanosleep NSECS_PER_MSEC;
        
        debug('creating '.$threads.' worker threads...');
        for (1 ... $threads) {
            threads->create('_worker_routine',$config)->detach();
        }
        nanosleep NSECS_PER_MSEC;
        
        my $poll = ZeroMQ::Poller->new(
            {
                name    => 'msgs_written',
                socket  => $msgs_written,
                events  => ZMQ_POLLIN,
            },
            {
                name    => 'msgs_processed',
                socket  => $msgs_processed,
                events  => ZMQ_POLLIN,
            },
        );
        
        do {
            debug('executing sql...');
            $sth->execute($archive->{'offset'});
            $ret = $sth->fetchall_hashref('id');
      
            my @keys = sort map { $_ = $ret->{$_}->{'id'} } keys(%$ret);
            
            debug('sending next pages to workers...');
            $workers->send_as('json' => $ret->{$_}) foreach(keys(%$ret));
            
            debug('waiting on workers to finish up...') if($::debug > 4);
            my $completed = 0;
            # need to tell the writer process when they should commit between pages
            # send signal or something
            do {
                debug('polling...') if($::debug > 4);
                $poll->poll();
                if($poll->has_event('msgs_written')){
                    $ret = $msgs_written->recv()->data();
                    $completed += $ret;
                    $total -= $ret;
                }        
                #sleep(1); # so ->poll() doesn't crush us and we can INT out
                nanosleep NSECS_PER_MSEC;
            } while(($completed < $archive->{'limit'}) && $total > 0);
            
            #debug('completed: '.$completed.'/'.$archive->{'limit'}) if($::debug > 1););
            debug('remaining: '.$total.' ('.int(($total/$archive->{'total'})*100).'%)');
            
            set_journal($keys[$#keys]);
           
            my $pages_left = $archive->page_count() - $archive->current_page();
            debug('pages left: '.$pages_left);
            debug('last id: '.$keys[$#keys]);
            $archive->{'offset'} = $archive->next_offset();
        } while($archive->current_page <= $archive->page_count());
    } else {
        debug('nothing to do...');
    }
    
    debug('sending WRK_DONE...') if($::debug);
    $ctrl->send('WRK_DONE');

    nanosleep NSECS_PER_MSEC;
    
    debug('closing connections...');

    $ctrl->close();
    $msgs_processed->close();
    $workers->close();
    $msgs_written->close();
    $context->term();
    return (undef,1);
}

sub _worker_routine {
    my $context = ZeroMQ::Context->new();
    
    debug('starting worker: '.threads->tid()) if($::debug > 1);
    
    my $receiver = $context->socket(ZMQ_PULL);
    $receiver->connect(WORKER_CONNECTION());
    
    my $writer = $context->socket(ZMQ_PUSH);
    $writer->connect(WRITER_CONNECTION());
    
    my $msgs_processed = $context->socket(ZMQ_PUSH);
    $msgs_processed->connect(MSGS_PROCESSED_CONNECTION());
    
    my $ctrl = $context->socket(ZMQ_SUB);
    $ctrl->setsockopt(ZMQ_SUBSCRIBE,''); 
    $ctrl->connect(CTRL_CONNECTION());
    
     my $poller = ZeroMQ::Poller->new(
        {
            name    => 'worker',
            socket  => $receiver,
            events  => ZMQ_POLLIN,
        },
        {
            name    => 'ctrl',
            socket  => $ctrl,
            events  => ZMQ_POLLIN,
        },
    ); 
       
    my $done = 0;
    my $recs = 0;
    my $tmp_total = 0;
    my $err;
    while(!$done){
        debug('polling...') if($::debug > 5);
        $poller->poll();
        debug('checking control...') if($::debug > 5);
        if($poller->has_event('ctrl')){
            my $msg = $ctrl->recv()->data();
            debug('ctrl sig received: '.$msg) if($::debug > 5 && $msg eq 'WRK_DONE');
            $done = 1 if($msg eq 'WRK_DONE');
        }
        debug('checking event...') if($::debug > 4);
        if($poller->has_event('worker')){
            #debug('['.threads->tid.']'.' receiving event...') if($::debug > 2 && $tmp_total % 10 == 0);
            my $msg = $receiver->recv()->data();
            debug('processing message...') if($::debug > 4);
           
            try {
                $msg = _process_message($msg);
                $writer->send_as('json' => $msg);
                debug('sent to writer...') if($::debug > 4);
                $msgs_processed->send('1');
            } catch {
                $err = shift;
                $writer->send('-1');
                $msgs_processed->send('1');
            };
        }
        $tmp_total++;
    }
    debug('done...') if($::debug > 2);
    debug('worker exiting...');
    $writer->close();
    $receiver->close();
    $ctrl->close();
    $context->term();
}

sub _process_message {
    my $rec = shift;
    
    my $err;
    
    $rec = JSON::XS::decode_json($rec);
    my $data = Compress::Snappy::decompress(decode_base64($rec->{'data'}));
    
    $data = IODEFDocumentType->decode($data);
    $data = Iodef::Pb::Format->new({
        data => $data,
        format => 'raw',
    });
    $data = @$data[0];
    
    $data = {
        'observable'    => $data->{'address'},
        'asn'           => $data->{'asn'},
        'firsttime'     => $data->{'detecttime'},
        'lasttime'      => $data->{'reporttime'},
        'reporttime'    => $data->{'reporttime'},
        'group'         => $group_map->{$data->{'guid'}},
        'rdata'         => $data->{'rdata'},
        'description'   => $data->{'description'},
        'tags'          => [split(' ', $data->{'description'})],
        'confidence'    => $data->{'confidence'},
        'prefix'        => $data->{'prefix'},
        'tlp'           => $tlp_map->{$data->{'restriction'}},
        'altid'         => $data->{'alternativeid'},
        'altid_tlp'     => $tlp_map->{$data->{'alternativeid_restriction'}},
        'rir'           => $data->{'rir'},
        'cc'            => $data->{'cc'},
    };
    return $data;
}

sub init_db {
    my $args = shift;

    my $config = Config::Simple->new($args->{'config'}) || return('missing config file');
    $config = $config->param(-block => 'db');
    
    my $db          = $config->{'database'} || 'cif';
    my $user        = $config->{'user'}     || 'postgres';
    my $password    = $config->{'password'} || '';
    my $host        = $config->{'host'}     || '127.0.0.1';
    
    my $dbi = 'DBI:Pg:database='.$db.';host='.$host;
    my $ret = CIF::DBI->connection($dbi,$user,$password,{ AutoCommit => 0});
    return (undef,$ret);
}

sub _writer_routine {
    my $config      = shift;
    my $total       = shift;
    my $commit_size = shift;

    my $context = ZeroMQ::Context->new();
    debug('starting writer thread...');
    
    my $writer = $context->socket(ZMQ_PULL);
    $writer->bind(WRITER_CONNECTION());
    
    my $msgs_written = $context->socket(ZMQ_PUSH);
    $msgs_written->connect(MSGS_WRITTEN_CONNECTION());
    
    my $poller = ZeroMQ::Poller->new(
        {
            name    => 'writer',
            socket  => $writer,
            events  => ZMQ_POLLIN,
        },
    ); 
    
    my ($msg,$tmsg);
    my $tmp_total = 0;
    
    my ($ret,$err);
    my ($done,$total_r,$total_w) = (0,0,0);
    
    do {
        ($tmsg,$msg) = (undef,undef);
        debug('polling...') if($::debug > 4);
        
        $poller->poll();
        if($poller->has_event('writer')){
            debug('found message...') if($::debug > 4);
            $msg = $writer->recv()->data();
            if($msg ne '-1'){
                $msg = JSON::XS::decode_json($msg);
                $ret = $storage->_submission({
                    Observables => [$msg],
                    timestamp => DateTime::Format::DateParse->parse_datetime($msg->{'reporttime'})),
                });
                die ::Dumper($ret);
                
                debug($err) if($err);
            } 
            $total_r += 1;
            $tmp_total += 1;
            debug($tmp_total) if($tmp_total % 100 == 0);
        }
        $done = 1 if($total_r == $total);
        
        if((($total_r % $commit_size) == 0) || $done){
            debug('flushing writer...');
            $dbi->dbi_commit();
            $msgs_written->send($tmp_total);
            debug('wrote: '.$tmp_total.' messages...');
            $total_w += $tmp_total;
            # reset the local counter
            $tmp_total = 0;
        }
        debug('total_received: '.$total_r) if($::debug > 4);
        debug('total_written: '.$total_w) if($::debug > 4);
        debug('total: '.$total) if($::debug > 4);
    } while(!$done);
    
    debug('writer done...') if($::debug > 1);
    
    $writer->close();
    $context->term();
    return;
}
