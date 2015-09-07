package CIF::Legacy::Pb::Format;
use base 'Class::Accessor';

use strict;
use warnings;

use Module::Pluggable require => 1, search_path => [__PACKAGE__];
use Try::Tiny;

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(qw(restriction_map group_map config));

# have to do this to load the drivers
our @plugins = __PACKAGE__->plugins();

sub new {
    my $class = shift;
    my $args = shift;
     
    my $driver  = $args->{'format'} || 'Table';
    $driver = ucfirst($driver);
    $driver     = __PACKAGE__.'::'.$driver;
   
    my $data;
    try {
        $driver = $driver->SUPER::new($args);
        $driver->init($args);
        $data   = $driver->write_out($args);
    } catch {
        my $err = shift;
        warn $err;
    };

    return $data;
}

sub init {
    my $self = shift;
    my $args = shift;
    
    $self->set_config($args->{'config'});
    $self->init_restriction_map($args);
    $self->init_group_map($args);
}

sub init_restriction_map {
    my $self = shift;
    my $args = shift;
    
    return unless($args->{'restriction_map'});
    
    my $map;
    foreach (@{$args->{'restriction_map'}}){
        $map->{$_->{'key'}} = $_->{'value'};
    }
    $self->set_restriction_map($map);
}

sub init_group_map {
    my $self = shift;
    my $args = shift;
    return unless($args->{'group_map'});
    
    my $map;
    foreach (@{$args->{'group_map'}}){
        $map->{$_->{'key'}} = $_->{'value'};
    }
    $self->set_group_map($map);
}

sub convert_restriction {
    my $self = shift;
    my $r = shift;
    return unless($r && $r =~ /^\d+$/);

    return 'private'        if($r == RestrictionType::restriction_type_private());
    return 'need-to-know'   if($r == RestrictionType::restriction_type_need_to_know());
    return 'public'         if($r == RestrictionType::restriction_type_public());
    return 'default'        if($r == RestrictionType::restriction_type_default());
}

sub convert_severity {
    my $self = shift;
    my $r = shift;
    return unless($r && $r =~ /^\d+$/);

    return 'low'        if($r == SeverityType::severity_type_low());
    return 'medium'     if($r == SeverityType::severity_type_medium());
    return 'high'       if($r == SeverityType::severity_type_high());
}

sub convert_purpose {
    my $self = shift;
    my $r = shift;
    return unless($r && $r =~ /^\d+$/);

    return 'mitigation'     if($r == IncidentType::IncidentPurpose::Incident_purpose_mitigation());
    return 'other'          if($r == IncidentType::IncidentPurpose::Incident_purpose_other());
    return 'reporting'      if($r == IncidentType::IncidentPurpose::Incident_purpose_reporting());
    return 'traceback'      if($r == IncidentType::IncidentPurpose::Incident_purpose_traceback());
}

sub to_keypair {
    my $self = shift;
    my $args = shift;
    
    my $data = $args->{'data'};
    
    my @array;
    
    # we do this in case we're handed an array of IODEF Documents
    if(ref($data) eq 'IODEFDocumentType'){
        $data = [$data];
    }
    
    foreach my $doc (@$data){
        next unless(ref($doc) eq 'IODEFDocumentType');
        foreach my $i (@{$doc->get_Incident()}){
            my $detecttime = $i->get_DetectTime();
            my $reporttime = $i->get_ReportTime();

            my $description = @{$i->get_Description}[0]->get_content();

            my $id = $i->get_IncidentID->get_content();
        
            # TODO -- convert assessment into an if/then block, in case we don't have one?
            # check to see if IODEF requires it
            my $assessment = @{$i->get_Assessment()}[0];
        
            my $confidence = $assessment->get_Confidence->get_rating();
            if($confidence == ConfidenceType::ConfidenceRating::Confidence_rating_numeric()){
                $confidence = $assessment->get_Confidence->get_content() || 0;
                unless($confidence =~ /^\d+$/){
                    if($args->{'round_confidence'}){
                        # we round down, always, error on the side of caution
                        $confidence = int($confidence);
                    } else {
                        $confidence = sprintf("%.3f",$confidence) ;
                    }
                
                }
            }
            my $severity = @{$assessment->get_Impact}[0]->get_severity();
            $severity = $self->convert_severity($severity);
            $assessment = @{$assessment->get_Impact}[0]->get_content->get_content();
        
            ## TODO -- restriction needs to be mapped down to event recursively where it exists in IODEF
            my $restriction = $i->get_restriction() || RestrictionType::restriction_type_private();
            my $purpose     = $i->get_purpose()     || IncidentType::IncidentPurpose::Incident_purpose_other();
            $purpose = $self->convert_purpose($purpose);
        
            my ($altid,$altid_restriction);
            if(my $x = $i->get_AlternativeID()){
                if(ref($x) eq 'ARRAY'){
                    $altid               = @{$x}[0];
                } else {
                    $altid               = $x;
                }
                $altid_restriction  = @{$altid->get_IncidentID}[0]->get_restriction() || $altid->get_restriction() || RestrictionType::restriction_type_private();
                $altid              = @{$altid->get_IncidentID}[0]->get_content();
            }
            
            # TODO -- only grab the first one for now
            my ($relatedid,$relatedid_restriction);
            if($i->get_RelatedActivity()){
                $relatedid = @{$i->get_RelatedActivity()->get_IncidentID()}[0]->get_content();
                $relatedid_restriction  = @{$i->get_RelatedActivity()->get_IncidentID()}[0]->get_restriction();
            }
            
            my $guid;
            my %additional_data;
            if(my $iad = $i->get_AdditionalData()){
                my $i = 1;
                foreach (@$iad){
                    if($_->get_meaning() =~ /^guid/){
                        $guid = $_->get_content();
                    } else {
                        my ($ad,$meaning) = ($_->get_content(),$_->get_meaning());
                        $additional_data{$i++} = { data => $ad, meaning => $meaning };
                    }
                }
            }
            
            $restriction            = $self->convert_restriction($restriction);
            $altid_restriction      = $self->convert_restriction($altid_restriction);
            $relatedid_restriction  = $self->convert_restriction($relatedid_restriction);
            
            if(my $map = $self->get_restriction_map()){
                if(my $r = $map->{$restriction}){
                    $restriction = $r;
                }
                if($altid_restriction && (my $r = $map->{$altid_restriction})){
                    $altid_restriction = $r;
                }
                if($relatedid_restriction && (my $r = $map->{$relatedid_restriction})){
                    $relatedid_restriction = $r;
                }
            }

            if($self->get_group_map && $self->get_group_map->{$guid}){
                $guid = $self->get_group_map->{$guid};
            }
            
            my $carboncopy;
            my $carboncopy_restriction = 'private';
            if($#{$i->get_Contact()} > 0){
                my @tmp;
                foreach my $contact (@{$i->get_Contact()}){
                    next unless($contact->get_type == ContactType::ContactRole::Contact_role_cc());
                    push(@tmp,$contact->get_ContactName->get_content());
                }
                $carboncopy = join(',',@tmp);
            }
            
            my $hash = {
                id          => $id,
                guid        => $guid,
                description => $description,
                detecttime  => $detecttime,
                reporttime  => $reporttime,
                confidence  => $confidence,
                assessment  => $assessment,
                restriction => $restriction,
                severity    => $severity,
                purpose     => $purpose,
                alternativeid               => $altid,
                alternativeid_restriction   => $altid_restriction,
                relatedid                   => $relatedid,
                relatedid_restriction       => $relatedid_restriction,
            };
            if(keys %additional_data){
                foreach my $k (keys %additional_data){
                    my $kk = 'additional_data'.$k;
                    $hash->{"$kk"} = $additional_data{$k}->{'data'};
                    $hash->{$kk.'_meaning'} = $additional_data{$k}->{'meaning'};
                }
                
            }
            if($i->get_EventData()){
                foreach my $e (@{$i->get_EventData()}){
                    my @flows = (ref($e->get_Flow()) eq 'ARRAY') ? @{$e->get_Flow()} : $e->get_Flow();
                    foreach my $f (@flows){
                        my @systems = (ref($f->get_System()) eq 'ARRAY') ? @{$f->get_System()} : $f->get_System();
                        foreach my $s (@systems){
                            my ($asn,$asn_desc,$prefix,$cc,$rir,$malware_hash,$rdata);
                            my $ad = $s->get_AdditionalData();
                            if($ad){
                                foreach my $e (@$ad){
                                    next unless($e->get_meaning());
                                    for(lc($e->get_meaning())){
                                        if(/^asn$/){
                                            $asn = $e->get_content();
                                            last;
                                        }
                                        if(/^asn_desc$/){
                                            $asn_desc = $e->get_content();
                                            last;
                                        }
                                        if(/^prefix$/){
                                            $prefix = $e->get_content();
                                            last;
                                        }
                                        if(/^cc$/){
                                            $cc = $e->get_content();
                                            last;
                                        }
                                        if(/^rir$/){
                                            $rir = $e->get_content();
                                            last;
                                        }
                                        if(/^(rdata)$/){
                                            ## todo -- make this work for many diff additional datat formatids (NS, CNAME, A, etc)
                                            #push(@$rdata),$e->get_content());
                                            $rdata = $e->get_content() if($e->get_formatid() eq 'A');
                                            last;
                                        }
                                    }
                                }
                            }
                            
                            my @nodes = (ref($s->get_Node()) eq 'ARRAY') ? @{$s->get_Node()} : $s->get_Node();
                            my $service = $s->get_Service();
                            foreach my $n (@nodes){
                                my $addresses = $n->get_Address();
                                $addresses = [$addresses] if(ref($addresses) eq 'AddressType');
                                foreach my $a (@$addresses){
                                    $hash->{'address'}      = $a->get_content();
                                    $hash->{'restriction'}  = $restriction;
                                    $hash->{'asn'}          = $asn;
                                    $hash->{'asn_desc'}     = $asn_desc;
                                    $hash->{'cc'}           = $cc;
                                    $hash->{'rir'}          = $rir;
                                    $hash->{'prefix'}       = $prefix;
                                    $hash->{'rdata'}        = $rdata;                           
                                    
                                    if($service){
                                        my ($portlist,$protocol);
                                        foreach my $srv (@$service){
                                            $hash->{'portlist'} = $srv->get_Portlist();
                                            $hash->{'protocol'} = $srv->get_ip_protocol();
                                            push(@array,$hash);
                                        }
                                    } else {
                                        push(@array,$hash);
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if(my $ad = $i->get_AdditionalData()){
                    my $found = 0;
                    foreach my $a (@$ad){
                        for(lc($a->get_meaning())){
                            if(/^malware hash$/){
                                $found = 1;
                                $hash->{'malware_hash'} = $a->get_content();
                                last;
                            }
                            if(/^tc malware registry detection rate$/){
                                $hash->{'malware_detection_rate'} = $a->get_content().'%';
                                last;
                            }
                        }
                    }
                    push(@array,$hash) if($found);
                }
            }
        }
    }
    
    if(my $new = $args->{'new_only'}){
        my @tmp;
        my $now = DateTime->from_epoch(epoch => time());
        foreach (@array){
            my $dt = DateTime::Format::DateParse->parse_datetime($_->{'detecttime'});
            next unless(($dt->ymd().'T'.$dt->hms().'Z') gt ($now->ymd().'T00:00:00Z'));
            push(@tmp,$_);
        }
        @array = @tmp;
    }
    
    if(my $f = $args->{'exclude_assessment'}){
        $f = lc($f);
        my @tmp;
        foreach (@array){
            next if($_->{'assessment'} eq $f);
            push(@tmp,$_);
        }
        @array = @tmp;
    }
    ## TODO -- multi column sort?
    if(my $s = $args->{'sortby'}){
        if(uc($args->{'sortby_direction'}) eq 'ASC'){
            @array = sort { $a->{$s} cmp $b->{$s} } @array;
        } else {
            @array = sort { $b->{$s} cmp $a->{$s} } @array;
        }
    }
    # http://code.google.com/p/collective-intelligence-framework/issues/detail?id=206
    # we should do this in the client, but sort/order might matter on the limit
    if($args->{'limit'} && $args->{'limit'} < ($#array+1)){
        my $limit = $args->{'limit'};
        splice(@array,0,($#array-$limit)+1);
    }
    
    return(\@array); 
}

# confor($conf, ['infrastructure/botnet', 'client'], 'massively_cool_output', 0)
#
# search the given sections, in order, for the given config param. if found, 
# return its value or the default one specified.

sub confor {
    my $self        = shift;
    my $conf        = shift;
    my $sections    = shift;
    my $name        = shift;
    my $def         = shift;
    
    return unless($conf);

    # handle
    # snort_foo = 1,2,3
    # snort_foo = "1,2,3"

    foreach my $s (@$sections) { 
        my $sec = $conf->param(-block => $s);
        next if isempty($sec);
        next if !exists $sec->{$name};
        if (defined($sec->{$name})) {
            return ref($sec->{$name} eq "ARRAY") ? join(', ', @{$sec->{$name}}) : $sec->{$name};
        } else {
            return $def;
        }
    }
    return $def;
}

sub isempty {
    my $h = shift;
    return 1 unless ref($h) eq "HASH";
    my @k = keys %$h;
    return 1 if $#k == -1;
    return 0;
}


1;
  
__END__

=head1 NAME

Iodef::Pb - Perl extension for formatting an array of IODEFDocumentType (IODEF protocol buffer objects) messages into things like tab-delmited tables, csv and snort rules

=head1 SYNOPSIS
    
  use Iodef::Pb::Simple;
  use Iodef::Pb::Format;

  my $i = Iodef::Pb::Simple->new({
    address         => '1.2.3.4',
    confidence      => 50,
    severity        => 'high',
    restriction     => 'need-to-know',
    contact         => 'Wes Young',
    assessment      => 'botnet',
    description     => 'spyeye',
    alternativeid   => 'example2.com',
    id              => '1234',
    portlist        => '443,8080',
    protocol        => 'tcp',
    asn             => '1234',
  });

  my $ret = Iodef::Pb::Format->new({
    driver  => 'Table', # or 'Snort'
    data    => $i,
  });

  warn $ret;

=head1 DESCRIPTION

This is a helper library for Iodef::Pb. It'll take a single (or array of) IODEFDocumentType messages and transform them to a number of different outputs (Table, Snort, etc).

=head2 EXPORT

None by default. Object Oriented.

=head1 SEE ALSO

 http://github.com/collectiveintel/iodef-pb-simple-perl
 http://collectiveintel.net

=head1 AUTHOR

Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2012 by Wes Young <claimid.com/wesyoung>
  Copyright (C) 2012 the REN-ISAC <ren-isac.net>
  Copyright (C) 2012 the trustee's of Indiana University <iu.edu>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
