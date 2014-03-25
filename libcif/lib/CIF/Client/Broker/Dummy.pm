package CIF::Client::Broker::Dummy;

use strict;
no warnings;
use namespace::autoclean;

use Mouse;
use JSON::XS;
use CIF::MessageFactory;
use CIF::Encoder::Json;

with 'CIF::Client::Broker';

sub understands {
    my ($self,$args) = @_;
    
    return 0 unless($args->{'remote'});
    return 0 unless($args->{'remote'} =~ /^dummy/);
    return 1;
}

sub init { return 1; }

sub get_fd {}
sub receive {}

sub send {
    my $self    = shift;
    my $msg     = shift;

    $msg = JSON::XS::decode_json($msg);
    $msg = @$msg[0] if(ref($msg) eq 'ARRAY'); #TODO?

    my $r = CIF::Message->new({
        rtype   => $msg->{'@rtype'},
        mtype   => 'response',
        stype   => 'success',
        Token   => $msg->{'Token'},
    });
    for($msg->{'@rtype'}){
        if(/^ping$/){
            $r->{'Data'} = CIF::Message::Ping->new({
                    Timestamp   => $msg->{'Data'}->{'Timestamp'},
            });
            last();
        }
        if(/^query$/){
            $r->{'Data'} = CIF::Message::Query->new({
                Query   => $msg->{'Data'}->{'Query'},
                Results => [
                    { 
                        provider    => 'example.org',
                        tlp         => 'amber',
                        group       => 'testgroup',
                        observable  => $msg->{'Data'}->{'Query'},
                        confidence  => 65,
                        reporttime  => (time() - 3600),
                        tags        => ['zeus','botnet'],
                        rdata       => ['10.0.0.1','10.0.2.1'],
                        portlist    => 8080,
                        protocol    => 'tcp',
                        type        => 'A',
                        altid       => 'http://example.org?id=1234',
                        altid_tlp   => 'green',
                    }
                ],
            });
            last();
        }
        if(/^submission$/){
            $r->{'Data'} = CIF::Message::Submission->new({
                Results => [ map { $_->{'id'} } @{$msg->{'Data'}->{'Observables'}} ],
            });
            last();
        }
        $r->{'stype'} = 'unauthorized';
                         
    }
    my $ret = CIF::Encoder::Json->encode({ 
        encoder_pretty  => 1,
        data            => $r 
    });
    return $ret;
}

sub shutdown {
    return 1;
}

__PACKAGE__->meta->make_immutable();

1;
