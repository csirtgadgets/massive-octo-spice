package CIF::Type::Tlp;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;

subtype 'CIF::Type::Tlp',
    as 'Str',
    where { /^(white|green|amber|red)$/ },
    message { "Not a valid TLP color: ".$_ };
    
coerce 'CIF::Type::Tlp',
    from 'Str',
    via { lc() };

no Mouse::Util::TypeConstraints;    
1;


