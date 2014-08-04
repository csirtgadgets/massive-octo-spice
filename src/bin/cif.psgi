#!/usr/bin/env perl

# http://mojocasts.com/e3
use strict;
use warnings;

BEGIN {
    use FindBin;
    use local::lib "$FindBin::Bin/..";
}

use CIF;
require CIF::Client;
use Mojolicious::Lite;
use Time::HiRes qw(gettimeofday);
use Module::Refresh;
use Data::Dumper;

use constant REMOTE_DEFAULT  => 'tcp://localhost:' . CIF::DEFAULT_PORT();

my $cli = CIF::Client->new({
        remote => REMOTE_DEFAULT(),
});

helper auth => sub {
    my $self = shift;
    
    return 1 if
        $self->param('token');
};

## TODO -- make this more dynamic (eg: /cif/v2...)
get '/' => sub {
    shift->redirect_to('/v2/help');
} => 'help';

get '/:version/help' => sub {
    shift->render('help');
} => 'help';

under sub {
    my $self = shift;
    return 1 if $self->auth;
    
    $self->render(json   => { 'message' => 'missing token' }, status => 401 );
    return;
};

get '/:version/ping' => sub {
    my $self  = shift;

    $self->render( json => { timestamp => [ gettimeofday() ] } );
} => 'ping#index';

get '/:version/observables/:observable' => sub {
	my $self = shift;
	
	my $token      = $self->param('token');
    my $query      = $self->param('observable');
    
    my $res = $cli->search({
        Token      => $token,
        Id         => $query,
    });

    $self->render( json => $res );
	
} => 'observable#show';

get '/:version/observables' => sub {
    my $self       = shift;
    
    my $token      	= $self->param('token');
    my $query      	= $self->param('q') || $self->param('observable');
    
    my $res = $cli->search({
        Token      	=> $token,
        Query      	=> $query,
        Filters     => {
        	otype          => $self->param('otype')        || undef,
        	cc             => $self->param('cc')           || undef,
        	confidence     => $self->param('confidence')   || 0,
        	starttime      => $self->param('starttime')    || undef,
        	groups         => $self->param('groups')       || undef,
        	limit          => $self->param('limit')        || undef,
        	tags           => $self->param('tags')         || undef,
        	applications   => $self->param('applications') || undef,
        	asns           => $self->param('asns')         || undef,
        	providers      => $self->param('providers')    || undef,
        	## TODO - TLP?
        },
    });

    $self->render( json => $res );
    
} => 'observables#index';

put '/:version/observables/new' => sub {
    my $self  = shift;
    my $token = $self->param('token');

    my $obs = $self->req->json();
    $obs = [$obs] unless ( ref($obs) eq 'ARRAY' );
    
    my $res = $cli->submit({
            Token       => $token,
            Observables => $obs,
    });

    if($#{$res} == 0){ # single
        $self->res->headers->add('X-Location' => $self->req->url->to_string());
        $self->res->headers->add('X-Id' => @{$res}[0]);
        
    } else {
        $res = [ map { $_ = { id => $_ } } @$res ];
    }
    $self->render(json => $res, status => 201);
} => 'observables#create';

app->start();

__DATA__

@@ help.html.ep
% layout 'default';
% my $API_VERSION = 'v2';

       <div id="wrapperlicious">
      <div id="routes" class="box infobox spaced">
            <h3><a href='https://github.com/csirtgadgets/p5-cif-sdk'>Perl SDK</a> :: <a href='https://github.com/csirtgadgets/py-cif-sdk'>Python SDK</a> :: <a href='https://github.com/csirtgadgets/rb-cif-sdk'>Ruby SDK</a></h3>
            <h3>Examples</h3>
            <table>
                <tr>
                    <td class="striped value">
                        <pre>GET /<%= $API_VERSION %>/ping?token=1234</pre>
                    </td>
                </tr>
                <tr>
                    <td class="striped value">
                        <pre>GET /<%= $API_VERSION %>/observables?token=1234&q=example.com</pre>
                    </td>
                </tr>
                <tr>
                    <td class="striped value">
                        <pre>GET /<%= $API_VERSION %>/observables?token=1234&cc=RU&tags=scanner,botnet</pre>
                    </td>
                </tr>
                <tr>
                    <td class="striped value">
                        <pre>GET /<%= $API_VERSION %>/observables/dd7610037ea0c3d68dd73634bee223bbdaedce14c707cbadbb1f90688d6312dd?token=1234</pre>
                    </td>
                </tr>
                <tr>
                    <td class="striped value">
                        <pre>PUT /<%= $API_VERSION %>/observables/new?token=1234 # body is JSON string</pre>
                    </td>
                </tr>
                
            </table>
       </div>
       </div>
    <div id="wrapperlicious">
      <div id="routes" class="box infobox spaced">
            <h3>Parameters</h3>
            <table>
                <thead align="left">
                    <tr>
                        <th>Param</th>
                        <th>Type</th>
                        <th>Examples</th>
                    </tr>
                </thead>
                % my $enabled_params = [ 
                % { param => 'q', type => 'STRING', example => 'example.com, 1.2.3.4, 1.2.3.0/24' },
                % { param => 'token', type => 'STRING', example => '1234' }, 
                % { param => 'limit', type => 'INT32', example => '500' },
                % { param => 'confidence', type => 'INT32', example => '65' },
                % { param => 'groups', type => 'STRING', example => 'group1,group2' },
                % { param => 'cc', type => 'STRING', example => 'RU' },
                % { param => 'tags', type => 'STRING', example => 'botnet,scanner' },
                % { param => 'otype', type => 'STRING', example => 'ipv4,fqdn' },
                % ];
                % foreach my $p (@{$enabled_params}){
                <tr align="left">
                    <td class="striped value">
                        <pre><%= $p->{'param'} %></pre>
                    </td>
                    <td class="striped value">
                        <pre><%= $p->{'type'} %></pre>
                    </td>
                    <td class="striped value">
                       <pre><%= $p->{'example'} %></pre>
                    </td>
                </tr>
                % }
            </table>
       </div>
       </div>
       
       <div id="wrapperlicious">
      <div id="routes" class="box infobox spaced">
      <h3>Routes</h3>
          % my $walk = begin
            % my ($walk, $route, $depth) = @_;
            <tr>
              <td class="striped value">
                % my $pattern = $route->pattern->pattern || '/';
                % $pattern = "+$pattern" if $depth;
                <pre><%= '  ' x $depth %><%= $pattern %></pre>
              </td>
              <td class="striped value">
                <pre><%= uc(join ',', @{$route->via || []}) || '*' %></pre>
              </td>
              <td class="striped value">
                % my $name = $route->name;
                <pre><%= $route->has_custom_name ? qq{"$name"} : $name %></pre>
              </td>
            </tr>
            % $depth++;
            %= $walk->($walk, $_, $depth) for @{$route->children};
            % $depth--;
          % end
          <table>
            <thead align="left">
              <tr>
                <th>Pattern</th>
                <th>Methods</th>
                <th>Name</th>
              </tr>
            </thead>
            %= $walk->($walk, $_, 0) for @{app->routes->children};
          </table>
        </div>
    </div>
     
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>CIF API Documentation (<%= app->mode %> mode)</title>
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="-1">
    %= javascript '/mojo/jquery/jquery.js'
    %= javascript '/mojo/prettify/run_prettify.js'
    %= stylesheet '/mojo/prettify/prettify-mojo-dark.css'
    <style>
      a img { border: 0 }
      body {
        background: url(<%= url_for '/mojo/pinstripe-light.png' %>);
        color: #445555;
        font: 0.9em 'Helvetica Neue', Helvetica, sans-serif;
        font-weight: normal;
        line-height: 1.5em;
        margin: 0;
      }
      code {
        background-color: #eef9ff;
        border: solid #cce4ff 1px;
        border-radius: 5px;
        color: #333;
        font: 0.9em Consolas, Menlo, Monaco, Courier, monospace;
        padding: 0.4em;
      }
      h1 {
        color: #2a2a2a;
        font-size: 1.5em;
        margin: 0;
      }
      pre {
        font: 0.9em Consolas, Menlo, Monaco, Courier, monospace;
        margin: 0;
        white-space: pre-wrap;
      }
      table {
        border-collapse: collapse;
        width: 100%;
      }
      td { padding: 0.5em; }
      .box {
        background-color: #fff;
        box-shadow: 0px 0px 2px #999;
        overflow: hidden;
        padding: 1em;
      }
      .code {
        background-color: #1a1a1a;
        background: url(<%= url_for '/mojo/pinstripe-dark.png' %>);
        color: #eee;
        text-shadow: #333 0 1px 0;
      }
      .important { background-color: rgba(47, 48, 50, .75) }
      .infobox { color: #333 }
      .infobox tr:nth-child(odd) .value { background-color: #ddeeff }
      .infobox tr:nth-child(even) .value { background-color: #eef9ff }
      .key { text-align: right }
      .more table { margin-bottom: 1em }
      .spaced {
        margin-left: 5em;
        margin-right: 5em;
      }
      .striped { border-top: solid #cce4ff 1px }
      .tap {
        font: 0.5em Verdana, sans-serif;
        text-align: center;
      }
      .value { padding-left: 1em }
      .wide { width: 100% }
      #error {
        font: 1.5em 'Helvetica Neue', Helvetica, sans-serif;
        font-weight: 300;
        margin: 0;
        text-shadow: #333 0 1px 0;
      }
      #footer {
        padding-top: 1em;
        text-align: center;
      }
      #nothing { padding-top: 60px }
      #showcase table { margin-top: 1em }
      #showcase td {
        padding-top: 0;
        padding-bottom: 0;
      }
      #showcase .key { padding-right: 0 }
      #request {
        border-top-left-radius: 5px;
        border-top-right-radius: 5px;
        margin-top: 1em;
      }
      #routes {
        border-bottom-left-radius: 5px;
        border-bottom-right-radius: 5px;
        padding-top: 5px;
      }
      #wrapperlicious {
        max-width: 1000px;
        margin: 0 auto;
      }
    </style>
  </head>
  <body>
  <%== content %>
  </body>
</html>

