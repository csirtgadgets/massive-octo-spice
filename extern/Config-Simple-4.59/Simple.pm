package Config::Simple;

# $Id: Simple.pm,v 3.57 2006/09/12 19:15:04 sherzodr Exp $

use strict;
# uncomment the following line while debugging. Otherwise,
# it's too slow for production environment
#use diagnostics;
use Carp;
use Fcntl qw(:DEFAULT :flock);
use Text::ParseWords 'parse_line';
use vars qw($VERSION $DEFAULTNS $LC $USEQQ $errstr);
use AutoLoader 'AUTOLOAD';


$VERSION   = '4.59';
$DEFAULTNS = 'default';

sub import {
    my $class = shift;
    for ( @_ ) {
        if ( $_ eq '-lc'      ) { $LC = 1;    next; }
        if ( $_ eq '-strict'  ) { $USEQQ = 1; next; }
    }
}



# delimiter used by Text::ParseWords::parse_line()
sub READ_DELIM () { return '\s*,\s*' }
# delimiter used by as_string()
sub WRITE_DELIM() { return ', '      }
sub DEBUG      () { 0 }


sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    _FILE_HANDLE    => undef,   # holds a reference to an opened cfg file
    _FILE_NAME      => undef,   # holds the name of the read configuration file
    _STACK          => [],      # currently not implemented
    _DATA           => {},      # actual key/value pairs are stored in _DATA
    _SYNTAX         => undef,   # holds the syntax of the read cfg file
    _SUB_SYNTAX     => undef,   # holds the sub-syntax (like for simplified ini)
    _ARGS           => {},      # holds all key/values passed to new()
    _OO_INTERFACE   => 1,       # currently not implemented
    _IS_MODIFIED    => 0,       # to prevent writing file back if they were not modified
  };
  bless ($self, $class);
  $self->_init(@_) or return;
  return $self;
}




sub DESTROY {
  my $self = shift;
  
  # if it was an auto save mode, write the changes
  # back only if the values have been modified.
  if ( $self->autosave() && $self->_is_modified() ) {
    $self->write();
  }
}




# initialize the object
sub _init {
  my $self = shift;

  if ( @_ == 1 ) {
    return $self->read($_[0]);
  } elsif ( @_ % 2 ) {
    croak "new(): Illegal arguments detected";
  } else {
    $self->{_ARGS} = { @_ };
  }
  # if syntax was given, call syntax()
  if ( exists $self->{_ARGS}->{syntax} ) {
    $self->syntax($self->{_ARGS}->{syntax});
  }
  # if autosave was set, call autosave
  if ( exists $self->{_ARGS}->{autosave} ) {
    $self->autosave($self->{_ARGS}->{autosave});
  }
  # If filename was passed, call read()
  if ( exists ($self->{_ARGS}->{filename}) ) {
    return $self->read( $self->{_ARGS}->{filename} );
  }  
  return 1;
}



sub _is_modified {
  my ($self, $bool) = @_;

  if ( defined $bool ) {
    $self->{_IS_MODIFIED} = $bool;
  }
  return $self->{_IS_MODIFIED};
}



sub autosave {
  my ($self, $bool) = @_;

  if ( defined $bool ) {
    $self->{_ARGS}->{autosave} = $bool;
  }
  return $self->{_ARGS}->{autosave};
}


sub syntax {
  my ($self, $syntax) = @_;  

  if ( defined $syntax ) {
    $self->{_SYNTAX} = $syntax;
  }  
  return $self->{_SYNTAX};
}


# takes a filename or a file handle and returns a filehandle
sub _get_fh {
  my ($self, $arg, $mode) = @_;  
  
  unless ( defined $arg ) {
    croak "_get_fh(): filename is missing";
  }
  if ( ref($arg) && (ref($arg) eq 'GLOB') ) {
    return ($arg, 0);
  }
  unless ( defined $mode ) {
      $mode = O_RDONLY;
  }
  unless ( sysopen(FH, $arg, $mode) ) {
    $self->error("couldn't open $arg: $!");
    return undef;
  }
  return (\*FH, 1);
}



sub read {
  my ($self, $file) = @_;
  
  # making sure one object doesn't work on more than one
  # file at a time
  if ( defined $self->{_FILE_HANDLE} ) {
    croak "Open file handle detected. If you're trying to parse another file, close() it first.";
  }
  unless ( defined $file ) {
    croak "Usage: OBJ->read(\$file_name)";
  }  
  
  $self->{_FILE_NAME}   = $file;
  $self->{_FILE_HANDLE} = $self->_get_fh($file, O_RDONLY) or return undef;
    
  $self->{_SYNTAX} = $self->guess_syntax(\*FH) or return undef;

  # call respective parsers

  if ( $self->{_SYNTAX} eq 'ini' ) {
        $self->{_DATA} = $self->parse_ini_file($file);
  } elsif ( $self->{_SYNTAX} eq 'simple' ) {
        $self->{_DATA} = $self->parse_cfg_file(\*FH);
  } elsif ( $self->{_SYNTAX} eq 'http' ) {
        $self->{_DATA} = $self->parse_http_file(\*FH);
  }

    if ( $self->{_DATA} ) {
        return $self->{_DATA};
    }

  die "Something went wrong. No supported configuration file syntax found. Either the file is of wrong syntax, or there is a bug in guess_syntax() method.";
}


sub close {
  my $self = shift;

  my $fh = $self->{_FILE_HANDLE} or return;
  unless ( close($fh) ) {
    $self->error("couldn't close the file: $!");
    return undef;
  }
  return 1;
}





# tries to guess the syntax of the configuration file.
# returns 'ini', 'simple' or 'http'.
sub guess_syntax {
  my ($self, $fh) = @_;

  unless ( defined $fh ) {
    $fh = $self->{_FILE_HANDLE} or die "'_FILE_HANDLE' is not defined";
  }
  unless ( seek($fh, 0, 0) ) {
    $self->error("Couldn't seek($fh, 0, 0): $!");
    return undef;
  }

  # now we keep reading the file line by line until we can identify the
  # syntax
  verbose("Trying to guess the file syntax...");
  my ($syntax, $sub_syntax);
  while ( <$fh> ) {
    # skipping empty lines and comments. They don't tell much anyway
    /^(\n|\#|;)/ and next;

    # If there's no alpha-numeric value in this line, ignore it
    /\w/ or next;

    # trim $/
    chomp();

    # If there's a block, it is an ini syntax
    /^\s*\[\s*[^\]]+\s*\]\s*$/  and $syntax = 'ini', last;

    # If we can read key/value pairs separated by '=', it still
    # is an ini syntax with a default block assumed
    /^\s*[\w-]+\s*=\s*.*\s*$/    and $syntax = 'ini', $self->{_SUB_SYNTAX} = 'simple-ini', last;

    # If we can read key/value pairs separated by ':', it is an
    # http syntax
    /^\s*[\w-]+\s*:\s*.*\s*$/   and $syntax = 'http', last;

    # If we can read key/value pairs separated by just whites,
    # it is a simple syntax.
    /^\s*[\w-]+\s+.*$/          and $syntax = 'simple', last;    
  }

  if ( $syntax ) {
    return $syntax;
  }

  $self->error("Couldn't identify the syntax used");
  return undef;

}





sub parse_ini_file {
  my ($class, $file) = @_;

  my ($fh, $close_fh) = $class->_get_fh($file, O_RDONLY) or return;
  unless(flock($fh, LOCK_SH) ) {
    $errstr = "couldn't acquire shared lock on $fh: $!";
    return undef;
  }
  
  unless ( seek($fh, 0, 0) ) {
    $errstr = "couldn't seek to the beginning of the file: $!";
    return undef;
  }

  my $bn = $DEFAULTNS;
  my %data = ();
  my $line;
  while ( defined($line=<$fh>) ) {
    # skipping comments and empty lines:

    $line =~ /^\s*(\n|\#|;)/  and next;
    $line =~ /\S/          or  next;

    chomp $line;
    
    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;
    
    # parsing the block name:
    $line =~ /^\s*\[\s*([^\]]+)\s*\]$/       and $bn = lcase($1), next;
    # parsing key/value pairs
    $line =~ /^\s*([^=]*\w)\s*=\s*(.*)\s*$/  and $data{$bn}->{lcase($1)}=[parse_line(READ_DELIM, 0, $2)], next;
    # if we came this far, the syntax couldn't be validated:
    $errstr = "syntax error on line $. '$line'";
    return undef;    
  }
  unless(flock($fh, LOCK_UN) ) {
    $errstr = "couldn't unlock file: $!";
    return undef;
  }
  if ( $close_fh ) {
    CORE::close($fh);
  }
  return \%data;
}


sub lcase {
  my $str = shift;
  $LC or return $str;
  return lc($str);
}




sub parse_cfg_file {
  my ($class, $file) = @_;

  my ($fh, $close_fh) = $class->_get_fh($file, O_RDONLY) or return;
    
  unless ( flock($fh, LOCK_SH) ) {
    $errstr = "couldn't get shared lock on $fh: $!";
    return undef;
  }

  unless ( seek($fh, 0, 0) ) {
    $errstr = "couldn't seek to the start of the file: :$!";
  }

  my %data = ();
  my $line;
  while ( defined($line=<$fh>) ) {
    # skipping comments and empty lines:
    $line =~ /^(\n|\#)/  and next;
    $line =~ /\S/        or  next;    
    chomp $line;
    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;
    # parsing key/value pairs
    $line =~ /^\s*([\w-]+)\s+(.*)\s*$/ and $data{lcase($1)}=[parse_line(READ_DELIM, 0, $2)], next;
    # if we came this far, the syntax couldn't be validated:
    $errstr = "syntax error on line $.: '$line'";
    return undef;
  }
  unless ( flock($fh, LOCK_UN) ) {
    $errstr = "couldn't unlock the file: $!";
    return undef;
  }
  
  if ( $close_fh ) {
    CORE::close($fh);
  }
  return \%data;
}



sub parse_http_file {
  my ($class, $file) = @_;

  my ($fh, $close_fh) = $class->_get_fh($file, O_RDONLY) or return;    
  unless ( flock($fh, LOCK_SH) ) {
    $errstr = "couldn't get shared lock on file: $!";
    return undef;
  }

  unless( seek($fh, 0, 0) ) {
    $errstr = "couldn't seek to the start of the file: $!";
    return undef;
  }
  my %data = ();
  my $line;
  while ( defined($line= <$fh>) ) {
    # skipping comments and empty lines:
    $line =~ /^(\n|\#)/  and next;
    $line =~ /\S/        or  next;
    # stripping $/:
    chomp $line;
    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;
    # parsing key/value pairs:
    $line =~ /^\s*([\w-]+)\s*:\s*(.*)$/  and $data{lcase($1)}=[parse_line(READ_DELIM, 0, $2)], next;
    # if we came this far, the syntax couldn't be validated:
    $errstr = "syntax error on line $.: '$line'";
    return undef;
  }
  unless ( flock($fh, LOCK_UN) ) {
    $errstr = "couldn't unlock file: $!";
    return undef;
  }
  if ( $close_fh ) {
    CORE::close($fh);
  }
  return \%data;
}


sub param {
  my $self = shift;

  # If called with no arguments, return all the
  # possible keys
  unless ( @_ ) {
    my $vars = $self->vars();
    return keys %$vars;
  }
  # if called with a single argument, return the value
  # matching this key
  if ( @_ == 1) {
    return $self->get_param(@_);    
  }
  # if we come this far, we were called with multiple
  # arguments. Go figure!
  my $args = {
    '-name',   undef,
    '-value',  undef,
    '-values', undef,
    '-block',  undef,
    @_
  };
  if ( defined $args->{'-name'} && (defined($args->{'-value'}) || defined($args->{'-values'})) ) {
    # OBJ->param(-name=>'..', -value=>'...') syntax:
    return $self->set_param($args->{'-name'}, $args->{'-value'}||$args->{'-values'});

  }
  if ( defined($args->{'-name'}) ) {
    # OBJ->param(-name=>'...') syntax:
    return $self->get_param($args->{'-name'});
     
  }
  if ( defined($args->{'-block'}) && (defined($args->{'-values'}) || defined($args->{'-value'})) ) {
    return $self->set_block($args->{'-block'}, $args->{'-values'}||$args->{'-value'});
  }
  if ( defined($args->{'-block'}) ) {
    return $self->get_block($args->{'-block'});
  }
    
  if ( @_ % 2 ) {
    croak "param(): illegal syntax";
  }
  my $nset = 0;
  for ( my $i = 0; $i < @_; $i += 2 ) {
    $self->set_param($_[$i], $_[$i+1]) && $nset++;
  }
  return $nset;
}




sub get_param {
  my ($self, $arg) = @_;

  unless ( $arg ) {
    croak "Usage: OBJ->get_param(\$key)";
  }
  $arg = lcase($arg);
  my $syntax = $self->{_SYNTAX} or die "'_SYNTAX' is undefined";
  # If it was an ini-style, we should first
  # split the argument into its block name and key
  # components:
  my $rv = undef;
  if ( $syntax eq 'ini' ) {
    my ($block_name, $key) = $arg =~ m/^([^\.]+)\.(.*)$/;
    if ( defined($block_name) && defined($key) ) {
      $rv = $self->{_DATA}->{$block_name}->{$key};
    } else {
      $rv = $self->{_DATA}->{$DEFAULTNS}->{$arg};
    }
  } else {
    $rv = $self->{_DATA}->{$arg};
  }

  defined($rv) or return;

  for ( my $i=0; $i < @$rv; $i++ ) {
    $rv->[$i] =~ s/\\n/\n/g;
  }  
  return @$rv==1 ? $rv->[0] : (wantarray ? @$rv : $rv);
}




sub get_block {
  my ($self, $block_name)  = @_;

  unless ( $self->syntax() eq 'ini' ) {
    croak "get_block() is supported only in 'ini' files";
  }
  unless ( defined $block_name ) {
    return keys %{$self->{_DATA}};
  }
  my $rv = {};
  while ( my ($k, $v) = each %{$self->{_DATA}->{$block_name}} ) {
    $v =~ s/\\n/\n/g;
    $rv->{$k} = $v->[1] ? $v : $v->[0];
  }
  return $rv;
}





sub set_block {
  my ($self, $block_name, $values) = @_;

  unless ( $self->syntax() eq 'ini' ) {
    croak "set_block() is supported only in 'ini' files";
  }
  my $processed_values = {};
  while ( my ($k, $v) = each %$values ) {
    $v =~ s/\n/\\n/g;
    $processed_values->{$k} = (ref($v) eq 'ARRAY') ? $v : [$v];
    $self->_is_modified(1);
  }

  $self->{_DATA}->{$block_name} = $processed_values;
  $self->_is_modified(1);
}





sub set_param {
  my ($self, $key, $value) = @_;

  my $syntax = $self->{_SYNTAX} or die "'_SYNTAX' is not defined";  
  if ( ref($value) eq 'ARRAY' ) {
    for (my $i=0; $i < @$value; $i++ ) {
      $value->[$i] =~ s/\n/\\n/g;
    }
  } else {
    $value =~ s/\n/\\n/g;
  }
  unless ( ref($value) eq 'ARRAY' ) {
    $value = [$value];
  }
  $key = lcase($key);
  # If it was an ini syntax, we should first split the $key
  # into its block_name and key components
  if ( $syntax eq 'ini' ) {
    my ($bn, $k) = $key =~ m/^([^\.]+)\.(.*)$/;
    if ( $bn && $k ) {
      $self->_is_modified(1);
      return $self->{_DATA}->{$bn}->{$k} = $value;
    }
    # most likely the user is assuming default name space then?
    # Let's hope!
    $self->_is_modified(1);
    return $self->{_DATA}->{$DEFAULTNS}->{$key} = $value;
  }
  $self->_is_modified(1);
  return $self->{_DATA}->{$key} = $value;
}








sub write {
  my ($self, $file) = @_;

  $file ||= $self->{_FILE_NAME} or die "Neither '_FILE_NAME' nor \$filename defined";

  unless ( sysopen(FH, $file, O_WRONLY|O_CREAT, 0666) ) {
    $self->error("'$file' couldn't be opened for writing: $!");
    return undef;
  }
  unless ( flock(FH, LOCK_EX) ) {
    $self->error("'$file' couldn't be locked: $!");
    return undef;
  }
  unless ( truncate(FH, 0) ) {
      $self->error("'$file' couldn't be truncated: $!");
      return undef;
  }
  print FH $self->as_string();
  unless ( CORE::close(FH) ) {
    $self->error("Couldn't write into '$file': $!");
    return undef;
  }
  return 1;
}



sub save {
  my $self = shift;
  return $self->write(@_);
}


# generates a writable string
sub as_string {
    my $self = shift;

    my $syntax = $self->{_SYNTAX} or die "'_SYNTAX' is not defined";
    my $sub_syntax = $self->{_SUB_SYNTAX} || '';
    my $currtime = localtime;
    my $STRING = undef;
    if ( $syntax eq 'ini' ) {
        $STRING .= "; Config::Simple $VERSION\n";
        $STRING .= "; $currtime\n\n";
        while ( my ($block_name, $key_values) = each %{$self->{_DATA}} ) {
            unless ( $sub_syntax eq 'simple-ini' ) {
                $STRING .= sprintf("[%s]\n", $block_name);
            }
            while ( my ($key, $value) = each %{$key_values} ) {
                my $values = join (WRITE_DELIM, map { quote_values($_) } @$value);
                $STRING .= sprintf("%s=%s\n", $key, $values );
            }
            $STRING .= "\n";
        }
    } elsif ( $syntax eq 'http' ) {
        $STRING .= "# Config::Simple $VERSION\n";
        $STRING .= "# $currtime\n\n";
        while ( my ($key, $value) = each %{$self->{_DATA}} ) {
            my $values = join (WRITE_DELIM, map { quote_values($_) } @$value);
            $STRING .= sprintf("%s: %s\n", $key, $values);
        }
    } elsif ( $syntax eq 'simple' ) {
        $STRING .= "# Config::Simple $VERSION\n";
        $STRING .= "# $currtime\n\n";
        while ( my ($key, $value) = each %{$self->{_DATA}} ) {
            my $values = join (WRITE_DELIM, map { quote_values($_) } @$value);
            $STRING .= sprintf("%s %s\n", $key, $values);
        }
    }
    $STRING .= "\n";
    return $STRING;
}





# quotes each value before saving into file
sub quote_values {
    my $string = shift;

    if ( ref($string) ) {   $string = $_[0] }
    $string =~ s/\\/\\\\/g;

    if ( $USEQQ && ($string =~ m/\W/) ) {
        $string =~ s/"/\\"/g;
        $string =~ s/\n/\\n/g;
        return sprintf("\"%s\"", $string);
    }
    return $string;
}



# deletes a variable
sub delete {
  my ($self, $key) = @_;

  my $syntax = $self->syntax() or die "No 'syntax' is defined";
  if ( $syntax eq 'ini' ) {
    my ($bn, $k) = $key =~ m/([^\.]+)\.(.*)/;
    if ( defined($bn) && defined($k) ) {
      delete $self->{_DATA}->{$bn}->{$k};
    } else {
      delete $self->{_DATA}->{$DEFAULTNS}->{$key};
    }
    return 1;
  }
  delete $self->{_DATA}->{$key};
}



# clears the '_DATA' entirely.
sub clear {
  my $self = shift;
  map { $self->delete($_) } $self->param;
}




1;
__END__;

=pod

=head1 NAME

Config::Simple - simple configuration file class

=head1 SYNOPSIS

  use Config::Simple;

  # --- Simple usage. Loads the config. file into a hash:
  Config::Simple->import_from('app.ini', \%Config);


  # --- OO interface:
  $cfg = new Config::Simple('app.ini');

  # accessing values:
  $user = $cfg->param('User');

  # getting the values as a hash:
  %Config = $cfg->vars();

  # updating value with a string
  $cfg->param('User', 'sherzodR');

  # updating a value with an array:
  $cfg->param('Users', ['sherzodR', 'geek', 'merlyn']);

  # adding a new block to an ini-file:
  $cfg->param(-block=>'last-access', -values=>{'time'=>time()});

  # accessing a block of an ini-file;
  $mysql = $cfg->param(-block=>'mysql');

  # saving the changes back to file:
  $cfg->save();


  # --- tie() interface
  tie %Config, "Config::Simple", 'app.ini';


=head1 ABSTRACT

Reading and writing configuration files is one of the most frequent
tasks of any software design. Config::Simple is the library that helps
you with it.

Config::Simple is a class representing configuration file object. 
It supports several configuration file syntax and tries to identify the 
file syntax automatically. Library supports parsing, updating and creating 
configuration files.

=head1 ABOUT CONFIGURATION FILES

Keeping configurable variables in your program source code is ugly, really.
And for people without much of a programming experience, configuring
your programs is like performing black magic. Besides, if you need to
access these values from within multiple files, want your programs
to be able to update configuration files or want to provide a friendlier
user interface for your configuration files, you just have to store them in 
an external file. That's where Config::Simple comes into play, making it
very easy to read and write configuration files.

If you have never used configuration files before, here is a brief
overview of various syntax to choose from. Otherwise you can jump to
L</PROGRAMMING STYLE>.

=head2 SIMPLE CONFIGURATION FILE

Simple syntax is what you need for most of your projects. These
are, as the name asserts, the simplest. File consists of key/value
pairs, delimited by nothing but white space. Keys (variables) should
be strictly alpha-numeric with possible dashes (-). Values can hold
any arbitrary text. Here is an example of such a configuration file:

  Alias     /exec
  TempFile  /usr/tmp

Comments start with a pound ('#') sign and cannot share the same
line with other configuration data.

=head2 HTTP-LIKE SYNTAX

This format of separating key/value pairs is used by HTTP messages.
Each key/value is separated by semi-colon (:). Keys are alphanumeric
strings with possible '-'. Values can be any arbitrary text:

Example:

  Alias: /exec
  TempFile: /usr/tmp

It is OK to have spaces around ':'. Comments start with '#' and cannot
share the same line with other configuration data.

=head2 INI-FILE

These configuration files are more native to Win32 systems. Data
is organized in blocks. Each key/value pair is delimited with an
equal (=) sign. Blocks are declared on their own lines enclosed in
'[' and ']':

  [BLOCK1]
  KEY1=VALUE1
  KEY2=VALUE2


  [BLOCK2]
  KEY1=VALUE1
  KEY2=VALUE2

Your Winamp 2.x play list is an example of such a configuration file.

This is the perfect choice if you need to organize your configuration
file into categories:

  [site]
  url="http://www.handalak.com"
  title="Web site of a \"Geek\""
  author=sherzodr

  [mysql]  
  dsn="dbi:mysql:db_name;host=handalak.com"
  user=sherzodr
  password=marley01

=head2 SIMPLIFIED INI-FILE

These files are pretty much similar to traditional ini-files, except they don't
have any block declarations. This style is handy if you do not want any categorization
in your configuration file, but still want to use '=' delimited key/value pairs. 
While working with such files, Config::Simple assigns them to a default block, 
called 'default' by default :-).

  url = "http://www.handalak.com"

Comments can begin with either pound ('#') or semi-colon (';'). Each comment
should reside on its own line

=head1 PROGRAMMING STYLE

Most of the programs simply need to be able to read settings from a configuration
file and assign them to a hash. If that's all you need, you can simply use
its import_from() - class method with the name of the configuration file
and a reference to an existing (possibly empty) hash:

  Config::Simple->import_from('myconf.cfg', \%Config);

Now your hash %Config holds all the configuration file's key/value pairs.
Keys of a hash are variable names inside your configuration file, and values
are their respective values. If "myconf.cfg" was a traditional ini-file, 
keys of the hash consist of block name and variable delimited with a dot, such
as "block.var".

If that's all you need, you can stop right here. Otherwise, read on. There is
much more Config::Simple offers.

=head2 READING THE CONFIGURATION FILE

To be able to use more features of the library, you will need to use its object
interface:

  $cfg = new Config::Simple('app.cfg');

The above line reads and parses the configuration file accordingly.
It tries to guess which syntax is used by passing the file to guess_syntax() method.
Alternatively, you can create an empty object, and only then read the configuration file in:

  $cfg = new Config::Simple();
  $cfg->read('app.cfg');

As in the first example, read() also calls guess_syntax() method on the file.

If, for any reason, it fails to guess the syntax correctly (which is less likely),
you can try to debug by using its guess_syntax() method. It expects
file handle for a  configuration file and returns the name of a syntax. Return
value is one of "ini", "simple" or "http".

  open(FH, "app.cfg");
  printf("This file uses '%s' syntax\n", $cfg->guess_syntax(\*FH));

=head2 ACCESSING VALUES

After you read the configuration file in successfully, you can use param() 
method to access the configuration values. For example:

  $user = $cfg->param("User");

will return the value of "User" from either simple configuration file, or
http-styled configuration as well as simplified ini-files. To access the
value from a traditional ini-file, consider the following syntax:

  $user = $cfg->param("mysql.user");

The above returns the value of "user" from within "[mysql]" block. Notice the
use of dot "." to delimit block and key names.

Config::Simple also supports vars() method, which, depending on the context
used, returns all the values either as hashref or hash:

  my %Config = $cfg->vars();
  print "Username: $Config{User}";

  # If it was a traditional ini-file:
  print "Username: $Config{'mysql.user'}";

If you call vars() in scalar context, you will end up with a reference to a hash:

  my $Config = $cfg->vars();
  print "Username: $Config->{User}";

If you know what you're doing, you can also have an option of importing all the
names from the configuration file into your current name space as global variables.
All the block/key names will be uppercased and will be converted to Perl's valid
variable names; that is, all the dots (block-key separator) and other '\W' characters will be 
substituted with underscore '_':

  $cfg = new Config::Simple('app.cfg');
  $cfg->import_names();

  # or, with a single line:
  Config::Simple->new('app.cfg')->import_names();
  
  print STDERR "Debugging mode is on" if $DEBUG_MODE;

In the above example, if there was a variable 'mode' under '[debug]' block,
it will be now accessible via $DEBUG_MODE, as opposed to $cfg->param('debug.mode');

C<import_names()> by default imports the values to its caller's name space. 
Optionally, you can specify where to import the values by passing the name of the 
name space as the first argument. It also prevents potential name collisions:

  Config::Simple->new('app.cfg')->import_names('CFG');
  print STDERR "Debugging mode is on" if $CFG::DEBUG_MODE;

If all you want is to import values from a configuration file, the above syntax may still
seem longer than necessary. That's why Config::Simple supports import_from() - class method,
which is called with the name of the configuration file. It will call import_names() for you:
  
  Config::Simple->import_from('app.cfg');

The above line imports all the variables into the caller's name space. It's similar to
calling import_names() on an object. If you pass a string as the second argument,
it will treat it as the alternative name space to import the names into. As we 
already showed in the very first example, you can also pass a reference to an existing
hash as the second argument. In this case, that hash will be modified with the values
of the configuration file.

  # import into $CFG name space:
  Config::Simple->import_from('app.cfg', 'CFG');

  # import into %Config hash:
  Config::Simple->import_from('app.cfg', \%Config);

The above line imports all the values to 'CFG' name space. import_from() returns
underlying Config::Simple object (which you may not even need anymore):

  $cfg = Config::Simple->import_from('app.cfg', \my %Config);
  $cfg->write('app.cfg.bak');

=head2 UPDATING THE VALUES

Configuration values, once read into Config::Simple, can be updated from within
your program by using the same param() method used for accessing them. For example:

  $cfg->param("User", "sherzodR");

The above line changes the value of "User" to "sherzodR". Similar syntax is applicable
for ini-files as well:

  $cfg->param("mysql.user", "sherzodR");

If the key you're trying to update does not exist, it will be created. For example,
to add a new "[session]" block to your ini-file, assuming this block doesn't already
exist:

  $cfg->param("session.life", "+1M");

You can also delete values calling delete() method with the name of the variable:

  $cfg->delete('mysql.user'); # deletes 'user' under [mysql] block


=head2 SAVING/WRITING CONFIGURATION FILES

The above updates to the configuration values are in-memory operations. They
do not reflect in the file itself. To modify the files accordingly, you need to
call either "write()" or "save()" methods on the object:

  $cfg->write();

The above line writes the modifications to the configuration file. Alternatively,
you can pass a name to either write() or save() to indicate the name of the
file to create instead of modifying existing configuration file:

  $cfg->write("app.cfg.bak");

If you want the changes saved at all times, you can turn C<autosave> mode on
by passing true value to $cfg->autosave(). It will make sure before your program
is terminated, all the configuration values are written back to its file:

  $cfg = new Config::Simple('aff.cfg');
  $cfg->autosave(1);

=head2 CREATING CONFIGURATION FILES

Occasionally, your programs may want to create their own configuration files
on the fly, possibly from a user input. To create a configuration file from
scratch using Config::Simple, simply create an empty configuration file object
and define your syntax. You can do it by either passing "syntax" option to new(),
or by calling syntax() method. Then play with param() method as you normally would.
When you're done, call write() method with the name of the configuration file:

  $cfg = new Config::Simple(syntax=>'ini');
  # or you could also do:
  # $cfg->autosave('ini')

  $cfg->param("mysql.dsn", "DBI:mysql:db;host=handalak.com");
  $cfg->param("mysql.user", "sherzodr");
  $cfg->param("mysql.pass", 'marley01');
  $cfg->param("site.title", 'sherzodR "The Geek"');
  $cfg->write("new.cfg");

This creates a file "new.cfg" with the following content:

  ; Config::Simple 4.43
  ; Sat Mar  8 00:32:49 2003

  [site]
  title=sherzodR "The Geek"

  [mysql]
  pass=marley01
  dsn=DBI:mysql:db;host=handalak.com
  user=sherzodr

Neat, huh? Supported syntax keywords are "ini", "simple" or "http". Currently
there is no support for creating simplified ini-files.

=head2 MULTIPLE VALUES

Ever wanted to define array of values in your single configuration variable? I have!
That's why Config::Simple supports this fancy feature as well. Simply separate your values
with a comma:

  Files hp.cgi, template.html, styles.css

Now param() method returns an array of values:

  @files = $cfg->param("Files");
  unlink $_ for @files;

If you want a comma as part of a value, enclose the value(s) in double quotes:

  CVSFiles "hp.cgi,v", "template.html,v", "styles.css,v"

In case you want either of the values to hold literal quote ("), you can
escape it with a backlash:

  SiteTitle "sherzod \"The Geek\""

=head2 TIE INTERFACE

If OO style intimidates you, and C<import_from()> is too simple for you,
Config::Simple also supports tie() interface. This interface allows you to tie()
an ordinary Perl hash to the configuration file. From that point on, you can use 
the variable as an ordinary Perl hash. 

  tie %Config, "Config::Simple", 'app.cfg';

  # Using %Config as an ordinary hash
  print "Username is '$Config{User}'\n";
  $Config{User} = 'sherzodR';

The difference between C<import_from($file, \%Hash)> is, all the changes you make
to the hash after tie()ing it, will also reflect in the configuration file object.
If autosave() was turned on, they will also be written back to file:

  tie %Config, "Config::Simple", "app.cfg";
  tied(%Config)->autosave(1);  

To access the method provided in OO syntax, you need to get underlying Config::Simple
object. You can do so with tied() function:
  
  tied(%Config)->write();

WARNING: tie interface is experimental and not well tested yet. Let me know if you 
encounter a problem.

=head1 MISCELLANEOUS

=head2 CASE SENSITIVITY

By default, configuration file keys and values are case sensitive. Which means,
$cfg->param("User") and $cfg->param("user") are referring to two different values.
But it is possible to force Config::Simple to ignore cases all together by enabling
C<-lc> switch while loading the library:

  use Config::Simple ('-lc');

WARNING: If you call write() or save(), while working on C<-lc> mode, all the case
information of the original file will be lost. So use it if you know what you're doing.

=head2 USING QUOTES

Some people suggest if values consist of none alpha-numeric strings, they should be
enclosed in double quotes. Well, says them! Although Config::Simple supports parsing
such configuration files already, it doesn't follow this rule while writing them. 
If you really need it to generate such compatible configuration files, C<-strict>
switch is what you need:

  use Config::Simple '-strict';

Now, when you write the configuration data back to files, if values hold any none alpha-numeric
strings, they will be quoted accordingly. All the double quotes that are part of the
value will be escaped with a backslash.

=head2 EXCEPTION HANDLING

Config::Simple doesn't believe in dying that easily (unless you insult it using wrong syntax).
It leaves the decision to the programmer implementing the library. You can use its error() -
class method to access underlying error message. Methods that require you to check
for their return values are read() and write(). If you pass filename to new(), you will
need to check its return value as well. They return any true value indicating success,
undef otherwise:

  # following new() always returns true:
  $cfg = new Config::Simple();

  # read() can fail:
  $cfg->read('app.cfg') or die $cfg->error();

  # following new() can fail:
  $cfg = new Config::Simple('app.cfg') or die Config::Simple->error();

  # import_from() calls read(), so it can fail:
  Config::Simple->import_from('app.cfg', \%Config) or die Config::Simple->error();

  # write() may fail:
  $cfg->write() or die $cfg->error();

  # tie() may fail, since it calls new() with a filename
  tie %Config, "Config::Simple", 'app.cfg' or die Config::Simple->error();

=head1 METHODS

=over 4

=item new()

- constructor. Optionally accepts several arguments. Returns Config::Simple object.
Supported arguments are B<filename>, B<syntax>, B<autosave>. If there is a single
argument, will be treated as the name of the configuration file.

=item autosave([$bool])

- turns 'autosave' mode on if passed true argument. Returns current autosave mode
if used without arguments. In 'autosave' mode Config::Simple writes all the changes
back to its file without you having to call write() or save()

=item read()

- accepts name  of the configuration file to parse. Before that, it tries to 
guess the syntax of the file by calling guess_syntax() method. Then calls either of
parse_ini_file(), parse_cfg_file() or parse_http_file() accordingly. If the name
of the file is provided to the constructor - new(), there is no need to call read().

=item param([$name], [$value])

- used for accessing and updating configuration variables. If used with no arguments
returns all the available names from the configuration file.

=item delete($name)

- deletes a variable from a configuration file. $name has the same meaning and syntax
as it does in param($name)

=item clear() 

- clears all the data from the object. Calling save() or turning autosave() on results
in an empty configuration file as well.

=item vars()

- depending on the context used, returns all the values available in the configuration
file either as a hash or a reference to a hash

=item import_names([$NS])

- imports all the names from the configuration file to the caller's name space. Optional
argument, if passed, will be treated as the name space variables to be imported into.
All the names will be uppercased. Non-alphanumeric strings in the values will be underscored

=item import_from($file, \%hash | $NS)

- class method. If the second argument is a reference to an existing hash, it will
load all the configuration contents into that hash. If the second argument is a 
string, it will be treated as the name space variables should be imported into, just
like import_names() does.

=item get_block($name)

is mostly used for accessing blocks in ini-styled configuration files. 
Returns a hashref of all the key/value pairs of a given block. Also supported by param()
method with the help of "-block" option:

  $hash = $cfg->get_block('Project');
  # is the same as saying:
  $hash = $cfg->param(-block=>'Project');

=item set_block($name, $values)

used in assigning contents to a block in ini-styled configuration files. $name should
be the name of a [block], and $values is assumed to be a hashref mapping key/value pairs.
Also supported by param() method with the help of "-block" and "-value" (or "-values") options:

  $cfg->set_block('Project', {Count=>3, 'Multiple Column' => 20});
  # is the same as:
  $cfg->param(-block=>'Project', -value=>{Count=>3, 'Multiple Column' => 20});

Warning: all the contents of a block, if previously existed will be wiped out.
If you want to set specific key/value pairs, use explicit method:

  $cfg->param('Project.Count', 3);

=item as_string()

- returns the configuration file as a chunk of text. It is the same text used by
write() and save() to store the new configuration file back to file.

=item write()

- writes the configuration file into disk. Argument, if passed, will be treated
as the name of the file configuration variables should be saved in.

=item save()

- same as write().

=item dump()

- for debugging only. Dumps the whole Config::Simple object using Data::Dumper.
Argument, if passed, will be treated as the name of the file object should be dumped in.
The second argument specifies amount of indentation as documented in L<Data::Dumper|Data::Dumper>
manual. Default indent size is 2.

=item error()

- returns the last error message from read/write or import_* operations.

=back

=head1 TODO

=over 4

=item *

Support for lines with continuation character, '\'. Currently its support
is restricted and quite possibly buggy.

=item *

Retaining comments while writing the configuration files back and/or methods for
manipulating comments. Everyone loves comments!

=item *

Retain the order of the blocks and other variables in the configuration files.

=back

=head1 BUGS

Submit bugs and possibly patches to Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>.

=head1 CREDITS

=over 4

=item Michael Caldwell (mjc@mjcnet.com)

whitespace support, C<-lc> switch and for various bug fixes

=item Scott Weinstein (Scott.Weinstein@lazard.com)

bug fix in TIEHASH

=item Ruslan U. Zakirov <cubic@wr.miee.ru>

default name space suggestion and patch

=item Hirosi Taguti

import_names() and import_from() idea.

=item Vitaly Kushneriuk

for bug fixes and suggestions

=back

=head1 COPYRIGHT

  Copyright (C) 2002-2003 Sherzod B. Ruzmetov.

  This software is free library. You can modify and/or distribute it
  under the same terms as Perl itself

=head1 AUTHOR

  Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>
  URI: http://author.handalak.com

=head1 SEE ALSO 

L<Config::General>, L<Config::Simple>, L<Config::Tiny>

=cut

# Following methods are loaded on demand.



# returns all the keys as a hash or hashref
sub vars {
  my $self = shift;

  # it might seem we should have used get_param() or param()
  # methods to make the task easier, but param() itself uses 
  # vars(), so it will result in a deep recursion
  my %vars = ();
  my $syntax = $self->{_SYNTAX} or die "'_SYNTAX' is not defined";
  if ( $syntax eq 'ini' ) {
    while ( my ($block, $values) = each %{$self->{_DATA}} ) {
      while ( my ($k, $v) = each %{$values} ) {
        $vars{"$block.$k"} = (@{$v} > 1) ? $v : $v->[0];
      }
    }
  } else {
    while ( my ($k, $v) = each %{$self->{_DATA}} ) {
      $vars{$k} = (@{$v} > 1) ? $v : $v->[0];
    }
  }
  return wantarray ? %vars : \%vars;
}





# imports names into the caller's namespace as global variables.
# I'm not sure how secure this method is. Hopefully someone will
# take a look at it for me
sub import_names {
  my ($self, $namespace) = @_;

  unless ( defined $namespace ) {    
    $namespace = (caller)[0];
  }
  if ( $namespace eq 'Config::Simple') {
    croak "You cannot import into 'Config::Simple' package";
  }
  my %vars = $self->vars();
  no strict 'refs';
  while ( my ($k, $v) = each %vars ) {
    $k =~ s/\W/_/g;
    ${$namespace . '::' . uc($k)} = $v;
  }
}



# imports names from a file. Compare with import_names.
sub import_from {
  my ($class, $file, $arg) = @_;

  if ( ref($class) ) {
    croak "import_from() is not an object method.";
  }
  # this is a hash support
  if ( defined($arg) && (ref($arg) eq 'HASH') ) {
    my $cfg = $class->new($file) or return;
    map { $arg->{$_} = $cfg->param($_) } $cfg->param();
    return $cfg;
  }
  # following is the original version of our import_from():
  unless ( defined $arg ) {
    $arg = (caller)[0];
  }  
  my $cfg = $class->new($file) or return;
  $cfg->import_names($arg);
  return $cfg;
}




sub error {
  my ($self, $msg) = @_;

  if ( $msg ) {
    $errstr = $msg;
  }
  return $errstr;
}





sub dump {
  my ($self, $file, $indent) = @_;

  require Data::Dumper;
  my $d = new Data::Dumper([$self], [ref $self]);
  $d->Indent($indent||2);
  if ( defined $file ) {
    sysopen(FH, $file, O_WRONLY|O_CREAT|O_TRUNC, 0666) or die $!;
    print FH $d->Dump();
    CORE::close(FH) or die $!;
  }
  return $d->Dump();
}


sub verbose {
  DEBUG or return;
  carp "****[$0]: " .  join ("", @_);
}




#------------------
# tie() interface
#------------------

sub TIEHASH {
  my ($class, $file, $args) = @_;

  unless ( defined $file ) {
    croak "Usage: tie \%config, 'Config::Simple', \$filename";
  }  
  return $class->new($file);
}


sub FETCH {
  my $self = shift;

  return $self->param(@_);
}


sub STORE {
  my $self = shift;

  return $self->param(@_);
}



sub DELETE {
  my $self = shift;

  return $self->delete(@_);
}


sub CLEAR {
  my $self = shift;
  map { $self->delete($_) } $self->param();
}


sub EXISTS {
  my ($self, $key) = @_;

  my $vars = $self->vars();
  return exists $vars->{$key};
}



sub FIRSTKEY {
  my $self = shift;

  # we make sure that tied hash is created ONLY if the program
  # needs to use this functionality.
  unless ( defined $self->{_TIED_HASH} ) {    
    $self->{_TIED_HASH} = $self->vars();
  }
  my $temp = keys %{ $self->{_TIED_HASH} };
  return scalar each %{ $self->{_TIED_HASH} };
}


sub NEXTKEY {
  my $self = shift;

  unless ( defined $self->{_TIED_HASH} ) {
    $self->{_TIED_HASH} = $self->vars();
  }
  return scalar each %{ $self->{_TIED_HASH} };
}





# -------------------
# deprecated methods
# -------------------

sub write_string {
  my $self = shift;

  return $self->as_string(@_);
}

sub hashref {
  my $self = shift;

  return scalar( $self->vars() );
}

sub param_hash {
  my $self = shift;

  return ($self->vars);
}

sub errstr {
  my $self = shift;
  return $self->error(@_);
}


sub block {
  my $self = shift;
  return $self->get_block(@_);
}

