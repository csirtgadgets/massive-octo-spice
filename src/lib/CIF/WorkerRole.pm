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

1;