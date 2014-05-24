package CIF::Format::Table;

use strict;
use warnings;

use Mouse;
use Text::Table;
use DateTime;

with 'CIF::Format';

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'format'});
    return 1 if($args->{'format'} eq 'table');
}

sub process {
    my $self = shift;
    my $data = shift;

    my @header = map { $_, { is_sep => 1, title => '|' } } @{$self->get_columns()};
    pop(@header);
    my $table = Text::Table->new(@header);
    
    foreach my $d (@$data){
        my @array;
        foreach my $c (@{$self->get_columns()}){
            my $x = $d->{$c};
            $x = join(',',@$x) if(ref($x) eq 'ARRAY');
            for($c){
                if(/time$/){
                    $x = DateTime->from_epoch(epoch => $x);
                    $x = $x->ymd().'T'.$x->hms().'Z';
                }
                last();
            }
            push(@array,$x);
        }
        $table->load(\@array);
    }
    return $table;
}

__PACKAGE__->meta()->make_immutable();

1;