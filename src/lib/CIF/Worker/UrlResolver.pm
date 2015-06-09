package CIF::Worker::UrlResolver;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;

use Mouse;
use CIF qw/is_url $Logger/;
use URI;

with 'CIF::WorkerFqdn';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless(is_url($args->{'observable'}));
    return 1;
}

sub process {
    my $self = shift;
    my $data = shift;
    
    my $obs = $data->{'observable'};
    $obs = URI->new($obs);
    
    my $ts = DateTime->from_epoch(epoch => time());
    $ts = $ts->ymd().'T'.$ts->hms().'Z';
    
    unless($data->{'tlp'}){
        $data->{'tlp'} = CIF::TLP_DEFAULT;
    }
    
    if($data->{'altid'} && !$data->{'altid_tlp'}){
        $data->{'altid_tlp'} = $data->{'tlp'} || CIF::TLP_DEFAULT;
    }
    
    $obs = {
        observable  => $obs->host,
        portlist    => $obs->port,
        related     => $data->{'id'},
        tags        => $data->{'tags'} || [],
        tlp         => $data->{'tlp'},
        group       => $data->{'group'} || CIF::GROUP_DEFAULT,
        provider    => $data->{'provider'},
        confidence  => $self->degrade_confidence($data->{'confidence'} || 25),
        application => $data->{'application'},
        portlist    => $data->{'portlist'},
        protocol    => $data->{'protocol'},
        altid       => $data->{'altid'},
        altid_tlp   => $data->{'altid_tlp'},
        lasttime    => $ts,
        reporttime  => $ts,
    };
    return [$obs];
}   

__PACKAGE__->meta->make_immutable();

1;