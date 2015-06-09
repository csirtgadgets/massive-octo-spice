package CIF::REST;
use Mojo::Base 'Mojolicious';

use strict;
use warnings;

require CIF::Client;
use Data::Dumper;

sub random_key {
    my @chars = ("A".."Z", "a".."z", 0..9);
    my $string;
    $string .= $chars[rand @chars] for 1..45;
    return $string;
}

use constant {
    SECRET      => $ENV{'SECRET'}       || random_key(),
    EXPIRATION  => $ENV{'EXPIRATION'}   || 84600, # 1 day
    MODE        => $ENV{'MOJO_MODE'}    || 'production',
    REMOTE      => $ENV{'REMOTE'}       || 'tcp://localhost:' . CIF::DEFAULT_PORT(),
    VERSION     => $ENV{'VERSION'}      || 2,
    CONFIG      => $ENV{'CIF_CONFIG'}   || '/etc/cif/cif-starman.conf',
};

# Connects once for entire application. For real apps, consider using a helper
# that can reconnect on each request if necessary.
#has schema => sub {
#  return Schema->connect('dbi:SQLite:' . ($ENV{TEST_DB} || 'test.db'));
#};

# https://github.com/tempire/mojolicious-plugin-basicauth/blob/master/lib/Mojolicious/Plugin/BasicAuth.pm
# http://daveyshafik.com/archives/35507-mimetypes-and-apis.html
# http://www.troyhunt.com/2014/02/your-api-versioning-is-wrong-which-is.html
# https://developer.github.com/v3/
sub startup {
    my $self = shift;
    
    $self->secrets(SECRET);
    $self->mode(MODE);
    $self->sessions->default_expiration(EXPIRATION);
    
    if(-e '/etc/cif/cif-starman.conf'){
        $self->plugin('Config', {file => CONFIG});
    }
    
    # via https://developer.github.com/v3/media/#request-specific-version
    $self->hook(after_render => sub {
        my ($c, $output, $format) = @_;
        $c->res->headers->append('X-CIF-Media-Type' => 'cif.v'.VERSION);
    });
    
    # http://mojolicio.us/perldoc/Mojolicious/Guides/Rendering#Content-type
    # http://mojolicio.us/perldoc/Mojolicious/Renderer#default_format
    $self->hook(before_routes => sub { ## TODO -- around_action?
        my $c = shift;
        if($c->req->headers->accept =~ /json/ || $c->req->headers->user_agent =~ /curl|wget|^cif/){
            $c->app->renderer->default_format('json');
        } else {
            $c->app->renderer->default_format('html');
        }
    });

    $self->helper(cli => sub {
        CIF::Client->new({
            remote  => REMOTE,
            tlp_map => $self->config('tlp_map'),
        })
    });
    
    $self->helper(auth => sub {
        my $self = shift;
        return 0 unless $self->req->headers->authorization;
    });
    
    $self->helper(token => sub {
        my $self = shift;
        my $token = scalar $self->req->headers->authorization;
        $token =~ /^Token token=(\S+)$/;
        $token = $1;
        return $token
    });
    
    $self->helper(version => sub {
        my $self = shift;
        my $accept = $self->req->headers->accept();
        my $version = VERSION;
        if($accept =~ /vnd\.cif\.v(\d)/){
            $version = $1;
        }
        return $version;
    });

    my $r = $self->routes;
    
    $r->options('*')->to('help#preflight'); # cors pre-flight
    
    $r->get('/')->to('help#index')->name('help#index');
    $r->get('/help')->to('help#index')->name('help#index');
    
    my $protected = $r->under( sub {
        my $self = shift;
        return 1 if $self->auth;
        $self->render(json   => { 'message' => 'missing token' }, status => 401 );
        return;
    });
    
    $protected->get('/ping')->via('GET')->to('ping#index')->name('ping#index');
   
    $protected->get('/observables')->to('observables#index')->name('observables#index');
    $protected->put('/observables')->to('observables#create')->name('observables#create');
    $protected->post('/observables')->to('observables#create')->name('observables#create');
    $protected->get('/observables/:observable')->to('observables#show')->name('observables#show');
}

1;