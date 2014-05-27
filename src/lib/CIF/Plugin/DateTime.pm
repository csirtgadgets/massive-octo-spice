package CIF::Plugin::DateTime;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use CIF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    is_datetime normalize_timestamp
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

use DateTime::Format::DateParse;

use constant RE_DATETIME_STR    => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
use constant RE_DATETIME_INT    => qr/^\d{6,}/;

sub is_datetime {
    my $arg = shift || return;
    
    return 'dt_string' if(is_datetime_string($arg));
    return 'dt_int' if(is_datetime_int($arg));
    return 0;
}

sub is_datetime_string {
    my $arg = shift || return;
    
    return 1 if($arg =~ RE_DATETIME_STR());
}

sub is_datetime_int {
    my $arg = shift || return;
    
    return 1 if($arg =~ RE_DATETIME_INT());
}

## TODO: this needs significant re-factoring
sub normalize_timestamp {
    my $dt  = shift;
    my $now = shift || DateTime->from_epoch(epoch => time()); # better perf in loops if we can pass the default now value
    my $asString = shift;

    return DateTime::Format::DateParse->parse_datetime($dt) if(!$asString && $dt =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);

    # already epoch
    if($dt =~ /^\d{10}+/){
        return DateTime->from_epoch(epoch => $dt) unless($asString);
        $dt = DateTime->from_epoch(epoch => $dt);
        return $dt->ymd().'T'.$dt->hms().'Z';
    } 
    
    return DateTime->today() if(lc($dt) =~ /^today$/);
    # something else
    if($dt && ref($dt) ne 'DateTime'){
        if($dt =~ /^(yesterday)$/){
            $dt = DateTime->today()->subtract(days => 1);
        } elsif($dt =~ /^(\d+) days? ago/){
            $dt = DateTime->today()->subtract(days => $1);
        } elsif($dt =~ /^\d+$/){
            if($dt =~ /^\d{8}$/){
                $dt.= 'T00:00:00Z';
                $dt = eval { DateTime::Format::DateParse->parse_datetime($dt) };
                unless($dt){
                    $dt = $now;
                }
            } else {
                $dt = $now;
            }
        } elsif($dt =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\S+)?$/) {
            my ($year,$month,$day,$hour,$min,$sec,$tz) = ($1,$2,$3,$4,$5,$6,$7);
            $dt = DateTime::Format::DateParse->parse_datetime($year.'-'.$month.'-'.$day.' '.$hour.':'.$min.':'.$sec,$tz);
        } else {
            $dt =~ s/_/ /g;
            $dt = DateTime::Format::DateParse->parse_datetime($dt);
            return unless($dt);
        }
    }   
    return $dt->ymd().'T'.$dt->hms().'Z' if($asString);
    return $dt;
}


1;