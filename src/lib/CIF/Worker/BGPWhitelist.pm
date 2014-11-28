package CIF::Worker::BGPWhitelist;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;

use Mouse;
use CIF qw/is_ip is_ip_private normalize_timestamp/;

with 'CIF::WorkerRole';

sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'confidence'} && $args->{'confidence'} >= CIF::Worker::CONFIDENCE_MIN);
    
    return unless($self->tag_contains($args->{'tags'},'whitelist'));
    return unless($args->{'prefix'});
    return unless(is_ip($args->{'observable'}));
    return if(is_ip_private($args->{'observable'}));
    return if($args->{'observable'} eq $args->{'prefix'});
    return 1;
}

sub process {
    my $self = shift;
    my $data = shift;
    
    my $ts = DateTime->from_epoch(epoch => time());
    $ts = $ts->ymd().'T'.$ts->hms().'Z';
   
    my $obs = {
        observable  => $data->{'prefix'},
        prefix      => $data->{'prefix'},
        tags        => 'whitelist',
        protocol    => $data->{'protocol'},
        portlist    => $data->{'portlist'},
        tlp         => $data->{'tlp'}   || CIF::TLP_DEFAULT,
        group       => $data->{'group'} || CIF::GROUP_DEFAULT,
        provider    => $data->{'provider'},
        confidence  => $self->degrade_confidence($data->{'confidence'}),
        application => $data->{'application'},
        altid       => $data->{'altid'},
        altid_tlp   => $data->{'altid_tlp'},
        related     => $data->{'id'},
        peers       => $data->{'peers'},
        lasttime    => $data->{'lasttime'},
        reporttime  => $ts,
    };
    
    return [$obs];
}   

__PACKAGE__->meta->make_immutable();

1;