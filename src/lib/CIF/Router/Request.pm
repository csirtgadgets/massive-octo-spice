package CIF::Router::Request;

use strict;
use warnings;

use Mouse::Role;

requires qw(process);

has [qw/user storage nolog msg/] => (
    is  => 'ro',
);

sub in_group {
    my $self    = shift;
    my $group   = shift;
    
    my $found = 0;
    foreach (@{$self->user->{'groups'}}){
        next unless($group eq $_);
        $found = 1;   
    }
    return $found;
}

sub in_groups {
    my $self    = shift;
    my $groups  = shift;
    
    $groups = [ $groups ] unless(ref($groups) && ref($groups) eq 'ARRAY');
    
    # only return success if we're in all the groups we're asking for
    # ie: fail hard if the user isn't in ALL the groups they're requesting
    foreach (@{$groups}){
        return 0 unless($self->in_group($_));
    }
    return 1;
}

1;