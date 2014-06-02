package CIF::Plugin::Debug;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    debug
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use DateTime;

sub debug {
    return unless($::debug);

    my $msg = shift;
    my $v   = shift;
    
    my ($pkg,$f,$line,$sub) = caller(1);
    
    unless($f){
        ($pkg,$f,$line) = caller();
    }
    
    $sub = '' unless($sub);
    my $ts = DateTime->from_epoch(epoch => time());
    $ts = $ts->ymd().'T'.$ts->hms().'Z';
    
    if($CIF::Logger){
         if($::debug > 5){
            $CIF::Logger->debug("[DEBUG][$ts][$f:$sub:$line]: $msg");
        } elsif($::debug > 1) {
            $CIF::Logger->debug("[DEBUG][$ts][$sub]: $msg");
        } else {
            $CIF::Logger->debug("[DEBUG][$ts]: $msg");
        }
    } else {
        if($::debug > 5){
            print("[DEBUG][$ts][$f:$sub:$line]: $msg\n");
        } elsif($::debug > 1) {
            print("[DEBUG][$ts][$sub]: $msg\n");
        } else {
            print("[DEBUG][$ts]: $msg\n");
        }
    }
}

1;