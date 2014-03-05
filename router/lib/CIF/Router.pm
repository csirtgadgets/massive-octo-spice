package CIF::Router;

use 5.011;
use strict;
use warnings;

use Mouse;
use CIF;
use CIF::Message;
use CIF::Message::Ping; # dont need this
use CIF::Encoder::Json;
use CIF::Router::RequestFactory;
use CIF::Router::AuthFactory;
use CIF::StorageFactory;
use Config::Simple;
use ZMQx::Class;
use Data::Dumper;
use AnyEvent;
use JSON::XS;

# constants
use constant DEFAULT_FRONTEND_PORT          => CIF::DEFAULT_FRONTEND_PORT();
use constant DEFAULT_BACKEND_PORT           => CIF::DEFAULT_BACKEND_PORT();

use constant DEFAULT_FRONTEND_LISTEN        => 'tcp://*:'.DEFAULT_FRONTEND_PORT();
use constant DEFAULT_BACKEND_LISTEN         => 'tcp://*:'.DEFAULT_BACKEND_PORT();

has 'port'      => (
    is      => 'ro',
    isa     => 'Int',
    default => DEFAULT_FRONTEND_PORT(),
);

has 'frontend_listen'   => (
    is      => 'ro',
    isa     => 'Str',
    default => DEFAULT_FRONTEND_LISTEN(),
);

has 'frontend'  => (
    is  => 'rw',
    isa => 'ZMQx::Class::Socket',
);

has 'frontend_watcher'  => (
    is => 'rw',
    isa => 'EV::IO',
);

has 'auth_handle' => (
    is      => 'ro',
    reader  => 'get_auth_handle',
);

has 'storage_handle'    => (
    is      => 'ro',
    reader  => 'get_storage_handle',
);

has 'encoder_pretty'    => (
    is      => 'ro',
    isa     => 'Bool',
);

around BUILDARGS => sub {
    my $orig    = shift;
    my $self    = shift;
    my $args    = shift;
    
    # if we're passed a config file
    if($args->{'config'}){
        unless(ref($args->{'config'})){
            $args->{'config'} = Config::Simple->new($args->{'config'});
        }
        %$args = %{$args->{'config'}->get_block('client')};
    }
    
    $args->{'auth_handle'}      = CIF::Router::AuthFactory->new_plugin($args->{'auth'});
    $args->{'storage_handle'}   = CIF::StorageFactory->new_plugin($args->{'storage'});
    
    return $self->$orig($args);
};

sub debug {
    my $msg = shift;
    $msg = '[router] '.$msg;
    CIF::debug($msg);
}

sub startup {
    my $self = shift;
    my $args = shift;

    $self->frontend(
        ZMQx::Class->socket(
            'REP',
            bind => $self->frontend_listen(),
        )
    );
    debug('frontend started on: '.$self->frontend_listen());
    
    my $ret;
    $self->frontend_watcher(
        $self->frontend->anyevent_watcher(
            sub {
                while (my $msg = $self->frontend->receive()){
                    $msg = $self->process(@$msg);
                    $self->frontend->send($msg);
                }
            }
        )
    );
    debug('started...');
    return 1;
}

sub process {
    my $self = shift;
    my $msg = shift;

    $msg = JSON::XS::decode_json($msg);

    my $r = CIF::Message->new({
        rtype   => $msg->{'@rtype'},
        mtype   => 'response',
        Token   => $msg->{'Token'},
    });
    
    my $ret = $self->get_auth_handle()->process($msg);

    if($ret){
        my $req = CIF::Router::RequestFactory->new_plugin({ 
            msg             => $msg, 
            auth_handle     => $self->get_auth_handle(),
            storage_handle  => $self->get_storage_handle(),
        });
        $r->set_Data($req->process($msg));
        $r->set_stype('success');
    } else {
        $r->set_stype('unauthorized');
        delete($r->{'Data'});
    }
    
    $r = CIF::Encoder::Json->encode({ 
        encoder_pretty  => 1,
        data            => $r 
    });
    return $r;
}

sub shutdown {
    my $self = shift;
    
    debug('shutting down');
    
    $self->{'frontend'}     = undef;
    $self->{'backend'}      = undef;
}

sub DESTROY {
    my $self = shift;
    $self->shutdown();
}

__PACKAGE__->meta->make_immutable(inline_destructor => 0);  

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CIF::Router - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CIF::Router;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for CIF::Router, created by h2xs. It looks like the
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
