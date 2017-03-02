package CIF::Worker::Spamhaus;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Net::Abuse::Utils::Spamhaus qw(check_ip check_fqdn);

use constant {
    CONFIDENCE  => 95,
    PROVIDER    => 'spamhaus.org',
};

use Mouse;
use CIF qw/is_fqdn is_ip is_ip_private $Logger/;

with 'CIF::WorkerFqdn';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'provider'} && $args->{'provider'} ne PROVIDER);
    return if($args->{'provider'} && $args->{'provider'} eq PROVIDER);

    return unless(is_fqdn($args->{'observable'}) || (is_ip($args->{'observable'}) && !is_ip_private($args->{'observable'})));
    return 1;
}

sub process {
    my $self = shift;
    my $data = shift;
    
    my $obs = $data->{'observable'};
    my (@array,$ret);
    
    if(is_ip($obs)){
        $ret = check_ip($obs,2);
    } else {
        # is fqdn
        $ret = check_fqdn($obs,2);
    }

    return unless($ret);
    
    my $ts = DateTime->from_epoch(epoch => time());
    $ts = $ts->ymd().'T'.$ts->hms().'Z';
    
    foreach my $rr (@$ret){
        next if(is_ip_private($obs));
        my $confidence = CONFIDENCE;
        if($rr->{'description'} =~ / legit /){
            $confidence = 65;
        }
        push(@array, {
            observable  => $obs,
            rdata       => $data->{'observable'},
            portlist    => $data->{'portlist'},
            protocol    => $data->{'protocol'},
            tags        => $rr->{'assessment'},
            description => $rr->{'description'},
            tlp         => $data->{'tlp'} || CIF::TLP_DEFAULT,
            group       => $data->{'group'} || CIF::GROUP_DEFAULT,
            provider    => PROVIDER,
            confidence  => $confidence,
            application => $data->{'application'},
            altid       => $rr->{'id'},
            altid_tlp   => 'white',
            related     => $data->{'id'},
            lasttime    => $ts,
            reporttime  => $ts,
        });
    }
    return \@array;
}   

__PACKAGE__->meta->make_immutable();

1;