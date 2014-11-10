package CIF::Type::PortList;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype "CIF::Type::PortList", 
    as 'Maybe[Str]',
    where {
        my $portlist = shift;
        foreach my $part (split(',', $portlist)) {
            if ($part =~ /^(\d+)(?:-(\d+))?$/) {
                my $start = $1;

                #  No end? Just use the start as the end.
                my $end = $2 || $start; 

                # The start should come before the end...
            if (
                    ($start > $end)                 ||
                    ($start < 0 || $start > 65535)  ||
                    ($end < 0 || $end > 65535)  
                ) { 
                    return 0;
                }
            } else {
                return 0;
                }
            }
        return 1;
    };

no Mouse::Util::TypeConstraints;
1;