package CIF::WorkerRole;

use Mouse::Role;

sub degrade_confidence {
    my $class       = shift;
    my $confidence  = shift;
    
    for(lc($confidence)){
        if(/^\d+/){
            my $log = log($confidence) / log(500);
            $confidence = sprintf('%.3f',($confidence * $log));
            return($confidence);
        }
    }
}

sub tag_contains {
    my $self = shift;
    my $tags = shift;
    my $arg = shift;
    
    return 0 unless $tags;
    
    $tags = [$tags] unless(ref($tags) && ref($tags) eq 'ARRAY');
 
    my $found = 0;
    foreach (@$tags){
        next unless($_ eq $arg);
        $found = 1;
    }
    return $found;
}

1;