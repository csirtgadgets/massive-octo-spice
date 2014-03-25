package CIF::Format::Stix;

use Inline Python;

use 5.011000;
use strict;
use warnings;

##TODO
## https://github.com/akreffett/cif_json2stix/blob/master/cif-json2stix.py

our $VERSION = '1.99_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use CIF qw/observable_type/;
use Mouse;

with 'CIF::Format';

use constant DEFAULT_DESCRIPTION    => 'cif';

has 'description' => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_DESCRIPTION(),
    reader  => 'get_description',
);

sub understands {
    my $self = shift;
    my $args = shift;

    return unless($args->{'format'});
    return 1 if($args->{'format'} eq 'stix');
}

sub process {
    my $self = shift;
    my $data = shift;
    
    $data = [ $data ] unless(ref($data) eq 'ARRAY');
    
    my $stix = _create_stix($self->get_description());
    foreach (@$data){
        my $i = _create_indicator({%$_}); # convert to a plain hash for python
        $stix->add_indicator($i);
    }
    return $stix->to_xml();
}

__PACKAGE__->meta()->make_immutable();

=head1 NAME

CIF::Format::Stix - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CIF::Format::Stix;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for CIF::Format::Stix, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Wesley Young, E<lt>wes@macports.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Wesley Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__DATA__
__Python__
import time
from stix.indicator import Indicator
from stix.core import STIXPackage, STIXHeader
from cybox.common import Hash
from cybox.objects.file_object import File
from cybox.objects.address_object import Address

import pprint
pp = pprint.PrettyPrinter(indent=4)
import re

def _create_stix(description):
    stix_package = STIXPackage()
    stix_header = STIXHeader()
    stix_header.description = description
    stix_package.stix_header = stix_header
        
    return stix_package;
    
def _create_indicator(keypair):
    indicator = Indicator()
    indicator.set_producer_identity(keypair.get('provider'))
    indicator.set_produced_time(time.strftime('%Y-%m-%dT%H:%M:%SZ', time.localtime(keypair.get('reporttime'))))

    indicator.description = ','.join(keypair.get('tags'))
    
    otype = keypair.get('otype')

    if otype == 'md5':
        f = _md5(keypair)
    elif otype == 'sha1':
        f = _sha1(keypair)
    elif otype == 'sha256':
        f = _sha256(keypair)
    else:
        f = _address(keypair)
        
    indicator.add_object(f)
    
    return indicator
    
def _md5(keypair):
    shv = Hash()
    shv.simple_hash_value = keypair.get('observable')
    
    f = File()
    h = Hash(shv, Hash.TYPE_MD5)
    f.add_hash(h)
    return f
    
def _sha1(keypair):
    shv = Hash()
    shv.simple_hash_value = keypair.get('observable')
    
    f = File()
    h = Hash(shv, Hash.TYPE_SHA1)
    f.add_hash(h)
    return f

def _sha256(keypair):
    shv = Hash()
    shv.simple_hash_value = keypair.get('observable')
    
    f = File()
    h = Hash(shv, Hash.TYPE_SHA256)
    f.add_hash(h)
    return f

def _address(keypair):
    address = keypair.get('observable')
    if _address_fqdn(address):
        return Address(address,'fqdn')
    elif _address_ipv4(address):
        return Address(address,'ipv4-addr')
    elif _address_url(address):
        return Address(address,'url')

def _address_ipv4(address):
    if re.search('^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}',address):
        return 1  

def _address_fqdn(address):
    if re.search('^[a-zA-Z0-9.\-_]+\.[a-z]{2,6}$',address):
        return 1

def _address_url(address):
    if re.search('^(ftp|https?):\/\/',address):
        return 1
