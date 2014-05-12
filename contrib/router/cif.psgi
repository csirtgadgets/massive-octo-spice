#!perl

die 'not working yet';

##TODO http://wiki.nginx.org/HttpPerlModule
##TODO http://mongrel2.org/wiki/quick_start.html
##TODO http://stackoverflow.com/questions/8765385/mongrel2-vs-nginxzeromq
#http://www.matt-peters.com/blog/?p=35

use Getopt::Long;
use CIF::Broker;
use Plack::Runner qw();
use JSON::XS;

use constant DEFAULT_UPSTREAM => 'tcp://localhost:5555';

my $help;
my $man;
my $upstream = DEFAULT_UPSTREAM();

my $config = $ENV{'HOME'}.'/.cif';

Getopt::Long::Configure ("bundling");
GetOptions(
    'upstream|U=s'  => \$upstream,
    'help|h'        => \$help, 
    'config|C=s'    => \$config,
) or die(usage());

die(usage()) if($help);

my $broker = CIF::Broker->new({ upstream => $upstream });

my $app = sub {
    my $env = shift;
    my $path = $env->{'PATH_INFO'};
    $ret = $broker->send({ data => "$path" });
    $ret = $broker->receive('blocking');
    $ret = JSON::XS::encode_json($ret);
    return [
        '200',
        ['Content-Type' => 'application/json'],
        [$ret],
    ];
};

my $runner = Plack::Runner->new();
$runner->run($app);

sub usage {
    return <<EOF;

Usage: $0 [OPTION]

 Options:
    -U, --upstream=STRING   upstream router, default: $upstream
    -C, --config=FILE       specify cofiguration file, default: ~/.cif 
    -h, --help              this message       

 Examples:
    $0 -C /path/to/cif.conf

EOF
}
__END__