package CIF::Message::Search;

use strict;
use warnings;

use Mouse;

has 'confidence'    => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_confidence',
);

has 'limit' => (
    is      => 'ro',
    isa     => 'Int',
    reader  => 'get_limit',
);

has 'group' => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_group',
    coerce  => 1,
);

has 'Tags'  => (
    is      => 'ro',
    isa     => 'ArrayRef',
    reader  => 'get_tags',
    coerce  => 1,
);

has 'Id'	=> (
	is		=> 'ro',
	isa		=> 'Str',
	reader	=> 'get_Id',
);

has 'Query' => (
    is          => 'rw',
    isa         => 'Str',
    reader      => 'get_Query',
    writer      => 'set_Query',
);

has 'Id' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_Id',
    writer  => 'set_Id',
);

has 'Country' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_Country',
    writer  => 'set_Country',
);

has 'Results'   => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => 'get_Results',
    writer  => 'set_Results',
);

has 'StartTime' => (
	is	=> 'rw',
	reader	=> 'get_StartTime',
	writer	=> 'set_StartTime',
);

has 'EndTime' => (
	is	=> 'rw',
	reader	=> 'get_EndTime',
	writer	=> 'set_EndTime',
);

has 'otype' => (
	is		=> 'ro',
	reader	=> 'get_otype',
);
	   
sub understands {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'rtype'});
    return 1 if($args->{'rtype'} eq 'search');
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = shift;
    
    $args->{'group'}        = '' unless($args->{'group'});
    $args->{'Tags'}         = [] unless($args->{'Tags'});
    $args->{'confidence'}   = 0 unless(defined($args->{'confidence'}));
    $args->{'limit'}        = 500 unless(defined($args->{'limit'}));
    
    
    return $self->$orig($args);
};

sub TO_JSON {
    my $self = shift;

    my $ret = {
        'confidence'   	=> $self->get_confidence(),
        'limit'        	=> $self->get_limit(),
        'group'        	=> $self->get_group(),
        'Query'         => $self->get_Query(),
        'Id'			=> $self->get_Id(),
        'Country'       => $self->get_Country(),
        'Results'       => $self->get_Results(),
        'StartTime'		=> $self->get_StartTime(),
        'EndTime'		=> $self->get_EndTime(),
        'otype'			=> $self->get_otype(),
    };
    return $ret;
}

__PACKAGE__->meta()->make_immutable();

1;
