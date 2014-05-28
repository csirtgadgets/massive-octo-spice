package CIF::Smrt::Handler::Default;

use warnings;
use strict;

use Mouse;

use CIF::Smrt::FetcherFactory;
use CIF::Smrt::DecoderFactory;
use CIF::Smrt::ParserFactory;
use CIF qw/$Logger/;

with 'CIF::Smrt::Handler';

has 'fetcher'   => (
    is      => 'ro',
    reader  => 'get_fetcher',
);

has 'parser'    => (
    is      => 'ro',
    reader  => 'get_parser',
);

sub understands {
    my $self = shift;
    my $args = shift;
    
    # if there's nothing, it's us
    return 1 unless($args->{'handler'});
    return 1 if($args->{'handler'} eq 'default');
    return 0;
}

around BUILDARGS => sub {
    my $origin  = shift;
    my $self    = shift;
    my $args    = shift;
    
    $args->{'parser'}   = CIF::Smrt::ParserFactory->new_plugin($args);
    $args->{'fetcher'}  = CIF::Smrt::FetcherFactory->new_plugin($args);
    
    return $self->$origin($args);
};

sub fetch {}

sub process {
    my $self = shift;
    my $args = shift;
    
    $Logger->debug('fetching...');
    my $ret = $self->get_fetcher()->process($args);
    return unless($ret);

    $Logger->debug('determining mime-type');
    my $ftype = File::Type->new()->mime_type(@$ret[0]);
    
    $Logger->debug('decoding...');

    ## TODO - fix $ret / Zip malwaredomains (arrayref)
    if(my $decoder = CIF::Smrt::DecoderFactory->new_plugin({ type => $ftype })){
        $ret = $decoder->process({ data => $ret });
    }

    $Logger->debug('parsing...');
    $ret = $self->get_parser()->process({ content => $ret });

    return $ret;
    
}

__PACKAGE__->meta->make_immutable();

1;