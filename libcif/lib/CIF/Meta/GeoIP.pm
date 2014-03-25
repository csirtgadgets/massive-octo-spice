package CIF::Meta::GeoIP;

use strict;
use warnings;
use namespace::autoclean;

use Mouse;
use GeoIP2::Database::Reader;
use CIF qw/is_ip/;
use Try::Tiny;

with 'CIF::Meta';

use constant GEOIP_FILE_LOCATION    => $ENV{'HOME'}."/GeoLite2-Country.mmdb";

has 'handle' => (
    is          => 'rw',
    isa         => 'GeoIP2::Database::Reader',
    lazy_build  => 1,
    reader      => 'get_handle',
    writer      => 'set_handle',
);

sub _build_handle {
    my $self = shift;
    my $args = shift;
    
    my $file = $args->{'file'} || GEOIP_FILE_LOCATION();
    $self->set_handle(
        GeoIP2::Database::Reader->new(file => $file)
    );
}

sub understands {
    my $self = shift;
    my $args = shift;
    return;
    return unless($args->{'observable'});
    return unless(is_ip($args->{'observable'}));
    return unless(-e GEOIP_FILE_LOCATION());
    return 1;
}

sub process {
    my $self = shift;
    my $args = shift;

    my ($err,$ret);
    try {
        $ret = $self->get_handle()->omni(ip => $args->{'observable'});
    } catch {
        $err = shift;
    };
    if($err){
        die $err unless($err =~ /^No record/);
    }
    if($ret){
        $args->{'countrycode'} = $ret->country()->iso_code();
    }
}

__PACKAGE__->meta->make_immutable();

1;