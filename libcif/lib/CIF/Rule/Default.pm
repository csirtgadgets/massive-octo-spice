package CIF::Rule::Default;

use strict;
use warnings;

use Mouse;

use Carp;
use Carp::Assert;
use CIF::Observable;

with 'CIF::Rule';

#use constant RE_IGNORE => qw/(<.+?>|\/|\.[a-z]{2,})/;
use constant RE_IGNORE => qw//;

has 'pattern'   => (
    is  => 'ro',
    reader  => 'get_pattern',
);

has 'parser'    => (
    is      => 'ro',
    default => 'default',
    reader  => 'get_parser',
);

has 'fields'    => (
    is          => 'ro',
    isa         => 'ArrayRef',
    coerce      => 1,
    reader      => 'get_fields',
);

has 'values'    => (
    is          => 'ro',
    isa         => 'ArrayRef',
    coerce      => 1,
    reader      => 'get_values',
);

has 'limit' => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_limit',
);

has 'skip_first' => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_skip_first',
);


has 'not_before' => (
    is          => 'rw', 
    isa         => 'CIF::Type::DateTimeInt',
);

has '_now' => (
    is          => 'ro', 
    isa         => 'CIF::Type::DateTimeInt',
    default     => sub { time() },
);

has 'skip_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
    reader  => 'get_skip_comments',
);

has 'ignore'    => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { 
        [
            RE_IGNORE(),
        ]
    },
    reader  => 'get_ignore',
);

has 'replace'   => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {
        'hxxp://'   => 'http://',
    }},
    reader  => 'get_replace',
);

has 'store_content' => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'get_store_content',
);

has 'feed' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_feed',
);

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;

    if($args->{'config'}){
        die "config file doesn't exist: ".$args->{'config'} unless(-e $args->{'config'});
        $args->{'config'} = Config::Simple->new($args->{'config'});
        $args->{'defaults'} = $args->{'config'}->get_block('default');
        $args->{'config'} = $args->{'config'}->get_block($args->{'feed'});
        $args->{'override'} = {} unless($args->{'override'});
        $args = { %{$args->{'config'}}, %{$args->{'defaults'}}, %{$args->{'override'}}, feed => $args->{'feed'} };
    }
    
    return $self->$orig($args);
};

sub understands {
    my $self = shift;
    my $args = shift;

    return 1 unless($args->{'pluign'});
    return 1 if($args->{'plugin'} eq 'default');
    return 0;
}

sub process {
    my $self = shift;
    my $args = shift;

    $self->_merge_defaults($args);
    
}

sub _merge_defaults {
    my $self = shift;
    my $args = shift;

    return unless($self->get_defaults());

    foreach my $k (keys %{$self->get_defaults()}){        
        for($self->get_defaults()->{$k}){
            if($_ && $_ =~ /<(\S+)>/){
                # if we have something that requires expansion
                # < >'s
                my $val = $args->{'data'}->{$1};
                unless($val){
                    warn 'missing: '.$k;
                    assert($val);
                }
                
                # replace the 'variable'
                my $default = $_;
                $default =~ s/<\S+>/$val/;
                $args->{'data'}->{$k} = $default;
            } else {
                $args->{'data'}->{$k} = $self->get_defaults()->{$k};
            }
        }
    }
}

sub _ignore {
    my $self = shift;
    my $arg = shift;
  
    foreach (@{$self->get_ignore()}){
        return 1 if($arg =~ $_);
    }
}

sub _replace {
    my $self = shift;
    my $arg = shift;
    
    foreach (keys %{$self->get_replace()}){
        next unless($arg =~ $_);
        my $r = $self->get_replace->{$_};
        $arg =~ s/$_/$r/;
    }
    return $arg;
}

__PACKAGE__->meta->make_immutable();

1;
