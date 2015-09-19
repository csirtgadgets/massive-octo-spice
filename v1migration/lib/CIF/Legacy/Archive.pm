package CIF::Legacy::Archive;
use base 'Class::DBI';

use strict;
use warnings;

__PACKAGE__->table('archive');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw/id uuid guid data format reporttime created/);
__PACKAGE__->columns(Essential => qw/id uuid guid data created/);
__PACKAGE__->sequence('archive_id_seq');

sub load_page_info {
    my $self = shift;
    my $args = shift;
    
    my $sql = $args->{'sql'};
    my $count = 0;
    if($sql){
        $self->set_sql(count_all => "SELECT COUNT(*) FROM __TABLE__ WHERE ".$sql);
    } else {
        $self->set_sql(count_all => "SELECT COUNT(*) FROM __TABLE__");
    }
    $count = $self->sql_count_all->select_val();
    $self->{'total'} = $count;
}

sub has_next {
    my $self = shift;
    return 1 if($self->{'total'} > $self->{'offset'} + $self->{'limit'});
    return 0;
}

sub has_prev {
    my $self = shift;
    return $self->{'offset'} ? 1 : 0;
}

sub next_offset {
    my $self = shift;
    return ($self->{'offset'} + $self->{'limit'});
}

sub prev_offset {
    my $self = shift;
    return ($self->{'offset'} - $self->{'limit'});
}

sub page_count {
    my $self = shift;
    return POSIX::ceil($self->{'total'} / $self->{'limit'});
}

sub current_page {
    my $self = shift;
    return int($self->{'offset'} / $self->{'limit'}) + 1;
}

1;