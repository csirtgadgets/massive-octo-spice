package CIF::Type::DateTime;

use strict;
use warnings;


use Mouse::Util::TypeConstraints;
use CIF qw/normalize_timestamp is_datetime/;

subtype 'CIF::Type::DateTimeString',
    as 'Str',
    where { is_datetime($_) eq 'dt_string' },
    message { "Must be of the format YYYY-MM-DDTHH:MM:SSZ" };
    
coerce 'CIF::Type::DateTimeString',
    from 'Str',
    via { normalize_timestamp($_,,1) };
    
subtype 'CIF::Type::DateTimeInt',
    as 'Int',
    where { is_datetime($_) eq 'dt_int' },
    message { "Must be formated as Epoch (Int)" };
    
coerce 'CIF::Type::DateTimeInt',
    from 'Str',
    via { normalize_timestamp($_)->epoch() };
    
subtype 'CIF::Type::DateTimeHiRes',
    as 'Num',
    where { $_ =~ /^([0-9]*\.[0-9]+)$/ },
    message { "Must be of the format 1234566.123123123" };

1;