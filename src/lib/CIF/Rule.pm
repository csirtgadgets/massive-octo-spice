package CIF::Rule;

use strict;
use warnings;

use Mouse;
use DateTime;
use Carp;
use Carp::Assert;
use CIF::Observable;
use CIF qw/parse_config/;

use constant RE_IGNORE => qw(qr/[\.]$/);

has [qw(store_content skip rule feed remote parser defaults)] => (
    is      => 'ro',
);

has 'not_before'    => (
    is          => 'ro',
    isa         => 'CIF::Type::DateTimeInt',
    coerce      => 1,
    default     => sub { DateTime->today()->epoch() },
);

has '_now' => (
    is          => 'ro', 
    default     => sub { time() },
);

sub process {
    my $self = shift;
    my $args = shift;

    $self->_merge_defaults($args);
    return $args->{'data'};
}

sub _merge_defaults {
    my $self = shift;
    my $args = shift;

    return unless($self->defaults);
    foreach my $k (keys %{$self->defaults}){        
        for($self->defaults->{$k}){
            if($_ && $_ =~ /<(\S+)>/){
                # if we have something that requires expansion
                # < >'s
                my $val;
                
                ##TODO -- work-around
                if($1 =~ /^remote$/){
                    $val = $self->remote;
                } else {
                    $val = $args->{'data'}->{$1};
                }
                unless($val){
                    warn 'missing: '.$k;
                    assert($val);
                }
                
                # replace the 'variable'
                my $default = $_;
                $default =~ s/<\S+>/$val/;
                $args->{'data'}->{$k} = $default;
            } else {
                $args->{'data'}->{$k} = $self->defaults->{$k};
            }
        }
    }
}

sub _ignore {
    my $self = shift;
    my $arg = shift;

    foreach (RE_IGNORE){
        return 1 if($arg =~ $_);
    }
}

__PACKAGE__->meta->make_immutable();

1;
