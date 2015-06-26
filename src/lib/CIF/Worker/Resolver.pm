package CIF::Worker::Resolver;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;

use Mouse;
use CIF qw/is_fqdn is_ip $Logger/;
use CIF::Worker;

with 'CIF::WorkerFqdn';

sub process {
    my $self = shift;
    my $data = shift;

    return unless($data->{'confidence'} && $data->{'confidence'} >= CIF::Worker::CONFIDENCE_MIN);
    
    my @new;
    foreach (qw/A NS MX/){
        push(@new,@{$self->_rr_to_observation($data,$_)});
    }
    return \@new;
}

sub _rr_to_observation {
    my $self    = shift;
    my $data    = shift;
    my $type    = shift || 'A';
    
    my $tags = $data->{'tags'};
    
    if ($tags) {
        $tags = [$tags] unless(ref($tags) && ref($tags) eq 'ARRAY');
    }
    
    my $found = 0;
    foreach my $t (@$tags){
        $found = 1 if($t eq 'rdata');
    }
    unless($found){
        push(@$tags,'rdata');
    }
    
    my $confidence = $self->degrade_confidence($data->{'confidence'});
    
    my $ts = DateTime->from_epoch(epoch => time());
    $ts = $ts->ymd().'T'.$ts->hms().'Z';
    
    my $ret = $self->resolve($data->{'observable'},$type);
    my $app = $data->{'application'};
    my @obs;
    foreach my $rr (@$ret){
        my $thing;
        for($rr->type()){
            if(/^A|IN$/){
                $thing = $rr->address();
                last;
            }
            if(/^CNAME$/){
                $thing = $rr->cname();
                last;
            }
            if(/^NS$/){
                $thing = $rr->nsdname();
                $app = 'dns';
                if($confidence > 35){
                    $confidence = 35;
                } else {
                     $self->degrade_confidence(35);
                }
                last;
            }
            if(/^MX$/){
                $thing = $rr->exchange();
                $app = 'smtp';
                if($confidence > 35){
                    $confidence = 35;
                } else {
                     $self->degrade_confidence(35);
                }
                last;
            }
        }
        unless($thing && (is_ip($thing) || is_fqdn($thing))){
            $Logger->debug('missing/bad thing type: '.Dumper($rr));
            $Logger->debug(Dumper($data));
            
        } else {
            unless($data->{'tlp'}){
                $data->{'tlp'} = CIF::TLP_DEFAULT;
            }
            if($data->{'altid'} && !$data->{'altid_tlp'}){
                 $data->{'altid_tlp'} = $data->{'tlp'} || CIF::TLP_DEFAULT;
            }
                
            my $o = {
                related     => $data->{'id'},
                observable  => $thing,
                confidence  => $confidence,
                tags        => $tags,
                tlp         => $data->{'tlp'},
                group       => $data->{'group'} || CIF::GROUP_DEFAULT,
                provider    => $data->{'provider'},
                rdata       => $data->{'observable'},
                application => $app,
                portlist    => $data->{'portlist'},
                protocol    => $data->{'protocol'} || undef,
                altid       => $data->{'altid'},
                altid_tlp   => $data->{'altid_tlp'},
                rtype       => $type,
                lasttime    => $ts,
                reporttime  => $ts,
            };
            push(@obs,$o);
        }
    }
    return \@obs;
}

__PACKAGE__->meta->make_immutable();

1;