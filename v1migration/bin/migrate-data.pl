#!/usr/bin/perl -w

use strict;
use warnings;

# fix lib paths, some may be relative
BEGIN {
    use FindBin;
    use local::lib "$FindBin::Bin/..";
}

use Getopt::Long;
use Time::HiRes qw/nanosleep/;
use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_REP ZMQ_PUB ZMQ_SUB ZMQ_PUSH ZMQ_PULL);
use Try::Tiny;
use Compress::Snappy;
use CIF::Legacy::Pb;
use CIF::Legacy::Pb::Format;
use CIF::Legacy::Archive;
use JSON::XS;
use Data::UUID;
use CIF::StorageFactory;
use MIME::Base64;

use threads;
use CIF qw/init_logging $Logger observable_type/;
use Data::Dumper;

use constant CTRL_CONNECTION            => 'ipc:///tmp/ctrl';
use constant WORKER_CONNECTION          => 'ipc:///tmp/workers';
use constant WRITER_CONNECTION          => 'ipc:///tmp/writer';

# bi-directional pipe for return counts, figure out when we're done
use constant MSGS_WRITTEN_CONNECTION    => 'ipc:///tmp/msgs_written';

# the lower this is, the higher the chance of 
# threading collisions resulting in a seg fault.
# the higher the thread count, the higher this number needs to be
use constant NSECS_PER_MSEC     => 1_000_000;

# used for SIGINT cleanup
my @pipes = ('msgs_written','workers','writer','ctrl');

my $help;
my $es_host = '127.0.0.1';
my $psql_host = '127.0.0.1';
my $threads = 2;
my $groups = 'everyone';
my $journal = '/tmp/cif-migrate.journal';
my $batch_size = 5000;
my $count;
my $psql_db_name = 'cif';
my $debug;
my $confidence = 65;
my $es_token;

Getopt::Long::Configure("bundling");
GetOptions(
    'help|h'            => \$help,
    'threads|t=i'         => \$threads,
    'journal=s'         => \$journal,
    'batch-size=i'      => \$batch_size,
    'groups=s'          => \$groups,
    'confidence=i'      => \$confidence,

    # storage
    'es-host=s'         => \$es_host,
    'es-token=s'        => \$es_token,
    'psql-host=s'       => \$psql_host,
    'psql-db-name=s'    => \$psql_db_name,
    
    # advanced
    'count=i'           => \$count,
    
    # logging
    'debug|d'       => \$debug,
    
) or die(usage());

die(usage()) if($help);

sub usage {
    return <<EOF;

Usage: $0 [OPTIONS]

 Options
    -d,  --debug             turn on debugging
    -h,  --help              this message
    
    --journal:              journal location, default: $journal
    --batch-size:           default commit size, default: $batch_size
    --groups:               specify groups from a v1 instance (csv)

 Storage:
    --es-host:              default: $es_host
    --psql-host:            default: $psql_host
    
 Threads:
    --threads:              default: $threads

 Examples:
    $0 --es-host 127.0.0.1 --psql-host 192.168.1.1

EOF
}

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

my $loglevel = ($debug) ? 'DEBUG' : 'INFO';

init_logging(
    { 
        level       => $loglevel,
        catagory	=> 'cif-migrate-data',
    }
);

$Logger->info('staring up..');

my $group_map = {
    '8c864306-d21a-37b1-8705-746a786719bf' => 'everyone',
};

my $tlp_map = {
    'private'       => 'red',
    'need-to-know'  => 'amber',
    'default'       => 'amber',
    'public'        => 'green'
};

$Logger->info('starting up ES connection...');
my $storage = CIF::StorageFactory->new_plugin({ 
    plugin => 'elasticsearch',
    nodes  => [ $es_host . ':9200' ],
});

$Logger->info('checking journal: ' . $journal);
my $j = check_journal();

$Logger->info('creating threads...');
threads->create('pager_routine')->join();

$Logger->info('done...');
exit(0);

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

sub init_db {
    my $args = shift;
    
    my $db          = $psql_db_name;
    my $user        = 'postgres';
    my $password    = '';
    my $host        = $psql_host;
    
    my $dbi = 'DBI:Pg:database='.$db.';host='.$host;
    my $ret = CIF::Legacy::Archive->connection($dbi,$user,$password);
    return $ret;
}

sub pager_routine {
    my $context = ZMQ::FFI->new();
    
    my $ctrl = $context->socket(ZMQ_PUB);
    $ctrl->bind(CTRL_CONNECTION());

    $Logger->info('starting workers');
    
    my $workers = $context->socket(ZMQ_PUSH);
    $workers->bind(WORKER_CONNECTION());
    
    my $msgs_written = $context->socket(ZMQ_PULL);
    $msgs_written->bind(MSGS_WRITTEN_CONNECTION());

    my ($ret,$err,$data,$tmp,$sth);
    
    $Logger->debug('connecting to archive..');
    
    my $archive = init_db({
        db          => 'cif',
        user        => 'postgres',
        password    => '',
        host        => $psql_host    
    });
    
    $archive = CIF::Legacy::Archive->new;
    
    $archive->{'limit'} = $batch_size;
    $archive->{'offset'} = 0;
    
    # setup the sql
    my $sql = 'SELECT id,uuid,guid,data FROM archive';
    
    my $jj = check_journal();
    if($jj > 0){ 
       $Logger->debug('starting at id: '.$jj);
       $archive->load_page_info({ sql => qq{ id > $jj } });
       $sql .= ' WHERE id > '.$jj;
    } else {
        $archive->load_page_info();
    }
    
    $sql .= ' ORDER BY id ASC LIMIT '.$archive->{'limit'}.' OFFSET ?';
    
    my $total = $archive->{'total'};
    $Logger->debug('total count: '.$total);
    $Logger->debug('pages: '.$archive->page_count());
    
    if($total){
        $archive->set_sql(custom1 => $sql);
        $sth = $archive->sql_custom1();
        
        # feature of zmq, pub/sub's need a warm up msg
        $Logger->debug('sending ctrl warm-up msg...');
        $ctrl->send('WARMING_UP');
    
        my $writer_t = threads->create('_writer_routine',$total,$archive->{'limit'})->detach();
        nanosleep NSECS_PER_MSEC;
        
        $Logger->debug('creating '.$threads.' worker threads...');
        for (1 ... $threads) {
            threads->create('_worker_routine')->detach();
        }
        nanosleep NSECS_PER_MSEC;
        
        do {
            $Logger->debug('executing sql...');
            $sth->execute($archive->{'offset'});
            $ret = $sth->fetchall_hashref('id');
      
            my @keys = sort map { $_ = $ret->{$_}->{'id'} } keys(%$ret);
            
            $Logger->debug('sending next pages to workers...');
            foreach(keys (%$ret)){
                $workers->send(JSON::XS::encode_json($ret->{$_}));
            }
            
            $Logger->debug('waiting on workers to finish up...');
            my $completed = 0;
            # need to tell the writer process when they should commit between pages
            # send signal or something
            do {
                if($msgs_written->has_pollin()){
                    $ret = $msgs_written->recv();
                    $completed += $ret;
                    $total -= $ret;
                }
            } while(($completed < $archive->{'limit'}) && $total > 0);

            $Logger->debug('remaining: '.$total.' ('.int(($total/$archive->{'total'})*100).'%)');
            
            set_journal($keys[$#keys]);
           
            my $pages_left = $archive->page_count() - $archive->current_page();
            $Logger->debug('pages left: '.$pages_left);
            $Logger->debug('last id: '.$keys[$#keys]);
            $archive->{'offset'} = $archive->next_offset();
        } while($archive->current_page <= $archive->page_count());
    } else {
        $Logger->debug('nothing to do...');
    }
    
    $Logger->debug('sending WRK_DONE...');
    $ctrl->send('WRK_DONE');

    nanosleep NSECS_PER_MSEC;
}

sub _writer_routine {
    my $total       = shift;
    my $commit_size = shift;

    my $context = ZMQ::FFI->new();
    $Logger->info('starting writer thread...');
    
    my $writer = $context->socket(ZMQ_PULL);
    $writer->bind(WRITER_CONNECTION());
    
    my $msgs_written = $context->socket(ZMQ_PUSH);
    $msgs_written->connect(MSGS_WRITTEN_CONNECTION());
    
    my $dbi = init_db();
    
    my ($msg,$tmsg);
    my $tmp_total = 0;
    
    my ($ret,$err);
    my ($done,$total_r,$total_w) = (0,0,0);
    
    my @user_groups;
    foreach (keys(%$group_map)){
        push(@user_groups, $group_map->{$_});
    }
    
    my $sent = 0;
    my $buckets = {};
    do {
        nanosleep NSECS_PER_MSEC;
        if($writer->has_pollin){
            $msg = $writer->recv();
            if($msg ne '-1'){
                $msg = JSON::XS::decode_json($msg);
                if($msg->{'group'}){
                    my $b = DateTime::Format::DateParse->parse_datetime($msg->{'reporttime'})->ymd();
                    $buckets->{$b} = [] unless(exists($buckets->{$b}));
                    push(@{$buckets->{$b}}, $msg);
                    
                    $tmp_total += 1;
                    
                    if($tmp_total % $commit_size == 0){
                        foreach my $k (keys %$buckets){
                            $ret = $storage->_submission({
                                Observables => $buckets->{$k},
                                timestamp => DateTime::Format::DateParse->parse_datetime($k),
                                user => {
                                    groups => \@user_groups
                                },
                            });
                            if(!$ret){
                                die Dumper($buckets->{$k});
                            }
                        }
                        $buckets = undef;
                        $tmp_total = 0;
                    }
                }
            }
            $msgs_written->send('1');
            $sent += 1;
            $Logger->info($sent) if($sent % $commit_size == 0);
        }
    } while(!$done);
    
    $Logger->debug('writer done...');
}

sub _worker_routine {
    my $context = ZMQ::FFI->new();
    
    $Logger->debug('starting worker: '.threads->tid());
    
    my $receiver = $context->socket(ZMQ_PULL);
    $receiver->connect(WORKER_CONNECTION());
    
    my $writer = $context->socket(ZMQ_PUSH);
    $writer->connect(WRITER_CONNECTION());
    
    my $ctrl = $context->socket(ZMQ_SUB);
    $ctrl->subscribe('');
    $ctrl->connect(CTRL_CONNECTION());
       
    my $done = 0;
    my $recs = 0;
    my $tmp_total = 0;
    my $err;
    while(!$done){
        if($ctrl->has_pollin()){
            my $msg = $ctrl->recv();
            $Logger->debug('ctrl sig received: '.$msg) if($msg eq 'WRK_DONE');
            $done = 1 if($msg eq 'WRK_DONE');
        }
        if($receiver->has_pollin()){
            my $msg = $receiver->recv();
           
            try {
                $msg = _process_message($msg);
                $writer->send($msg);
            } catch {
                $err = shift;
                $Logger->error($err);
                $writer->send('-1');
            };
        }
        $tmp_total++;
    }
    $Logger->debug('done...');
    $Logger->debug('worker exiting...');

}

sub _process_message {
    my $rec = shift;
    
    my $err;
    
    $rec = JSON::XS::decode_json($rec);
    my $data = Compress::Snappy::decompress(decode_base64($rec->{'data'}));
    
    $data = IODEFDocumentType->decode($data);
    $data = CIF::Legacy::Pb::Format->new({
        data => $data,
        format => 'raw',
    });
    $data = @$data[0];
    return '-1' unless $data;
    
    if($data->{'address'}){
        $data->{'address'} =~ s/hxxp\:\/\///g;
    }
    
    $data = {
        'observable'    => $data->{'address'},
        'asn'           => $data->{'asn'},
        'firsttime'     => $data->{'detecttime'},
        'lasttime'      => $data->{'detecttime'},
        'reporttime'    => $data->{'reporttime'},
        'group'         => $group_map->{$data->{'guid'}},
        'rdata'         => $data->{'rdata'},
        'description'   => $data->{'description'},
        'tags'          => [split(' ', $data->{'description'})],
        'confidence'    => $data->{'confidence'},
        'prefix'        => $data->{'prefix'},
        'tlp'           => $tlp_map->{$data->{'restriction'}},
        'altid'         => $data->{'alternativeid'},
        'altid_tlp'     => $tlp_map->{$data->{'alternativeid_restriction'} || 'private'},
        'rir'           => $data->{'rir'},
        'cc'            => $data->{'cc'},
    };
    $data->{'otype'} = observable_type($data->{'observable'});
    
    $data = JSON::XS::encode_json($data);
    
    return $data;
}
