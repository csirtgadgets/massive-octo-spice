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
    
    $obs = {
        observable  => $obs->host,
        portlist    => $obs->port,
        related     => $data->{'id'},
        tags        => $data->{'tags'} || [],
        tlp         => $data->{'tlp'} || CIF::TLP_DEFAULT,
        group       => $data->{'group'} || CIF::GROUP_DEFAULT,
        provider    => $data->{'provider'} || CIF::PROVIDER_DEFAULT,
        confidence  => $self->degrade_confidence($data->{'confidence'} || 25),
    };
    return [$obs];
}   

__PACKAGE__->meta->make_immutable();

1;