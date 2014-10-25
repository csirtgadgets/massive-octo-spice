package CIF::Type::Uri;

use strict;
use warnings;

use Mouse::Util::TypeConstraints;
use URI;
use URI::Escape;

use constant RE_URL_SCHEME => qr/^[-+.a-zA-Z0-9]+:\/\//;
our @ALLOWED_SCHEMES = qw(
    http
    https
    ftp
);

our $RESTR_ALLOWED_SCHEMES = join('|', @ALLOWED_SCHEMES);
our $RE_ALLOWED_SCHEMES = qr/^($RESTR_ALLOWED_SCHEMES)$/;

# We want an absolute URL
subtype 'CIF::Type::Uri',
    as 'Str',
    where { 
        my $url_text = shift;
        $url_text = uri_escape_utf8($url_text,'\x00-\x1f\x7f-\xff');
        $url_text = lc($url_text);
        my $url = URI->new($url_text);
        return (
            defined($url->scheme) # must have a scheme
            && ($url->scheme() =~ $RE_ALLOWED_SCHEMES)
            && $url->can('host') # must have a host component 
            && $url->can('port') # must respond to port
        );
    },
    message { "Invalid URL '" . ($_ || '(undef)') . "'"} ;

no Mouse::Util::TypeConstraints;
1;