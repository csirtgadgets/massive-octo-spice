package CIF::Legacy::Pb;

use strict;
use warnings;
use Google::ProtocolBuffers;
{
    unless (SeverityType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'SeverityType',
            [
               ['severity_type_high', 1],
               ['severity_type_low', 2],
               ['severity_type_medium', 3],

            ]
        );
    }
    
    unless (ImpactType::ImpactType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ImpactType::ImpactType',
            [
               ['Impact_type_admin', 1],
               ['Impact_type_dos', 2],
               ['Impact_type_ext_value', 3],
               ['Impact_type_extortion', 4],
               ['Impact_type_file', 5],
               ['Impact_type_info_leak', 6],
               ['Impact_type_misconfiguration', 7],
               ['Impact_type_policy', 8],
               ['Impact_type_recon', 9],
               ['Impact_type_social_engineering', 10],
               ['Impact_type_unknown', 11],
               ['Impact_type_user', 12],
               ['Impact_type_other', 13],

            ]
        );
    }
    
    unless (NodeRoleType::NodeRoleCategory->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'NodeRoleType::NodeRoleCategory',
            [
               ['NodeRole_category_application', 1],
               ['NodeRole_category_client', 2],
               ['NodeRole_category_credential', 3],
               ['NodeRole_category_database', 4],
               ['NodeRole_category_directory', 5],
               ['NodeRole_category_ext_value', 6],
               ['NodeRole_category_file', 7],
               ['NodeRole_category_ftp', 8],
               ['NodeRole_category_infra', 9],
               ['NodeRole_category_log', 10],
               ['NodeRole_category_mail', 11],
               ['NodeRole_category_messaging', 12],
               ['NodeRole_category_name', 13],
               ['NodeRole_category_p2p', 14],
               ['NodeRole_category_print', 15],
               ['NodeRole_category_server_internal', 16],
               ['NodeRole_category_server_public', 17],
               ['NodeRole_category_streaming', 18],
               ['NodeRole_category_voice', 19],
               ['NodeRole_category_www', 20],

            ]
        );
    }
    
    unless (IncidentType::IncidentPurpose->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'IncidentType::IncidentPurpose',
            [
               ['Incident_purpose_ext_value', 1],
               ['Incident_purpose_mitigation', 2],
               ['Incident_purpose_other', 3],
               ['Incident_purpose_reporting', 4],
               ['Incident_purpose_traceback', 5],

            ]
        );
    }
    
    unless (AddressType::AddressCategory->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'AddressType::AddressCategory',
            [
               ['Address_category_asn', 1],
               ['Address_category_atm', 2],
               ['Address_category_e_mail', 3],
               ['Address_category_ext_value', 4],
               ['Address_category_ipv4_addr', 5],
               ['Address_category_ipv4_net', 6],
               ['Address_category_ipv4_net_mask', 7],
               ['Address_category_ipv6_addr', 8],
               ['Address_category_ipv6_net', 9],
               ['Address_category_ipv6_net_mask', 10],
               ['Address_category_mac', 11],
               ['Address_category_fqdn', 12],
               ['Address_category_url', 13],

            ]
        );
    }
    
    unless (ExtensionType::DtypeType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ExtensionType::DtypeType',
            [
               ['dtype_type_boolean', 1],
               ['dtype_type_byte', 2],
               ['dtype_type_character', 3],
               ['dtype_type_csv', 4],
               ['dtype_type_date_time', 5],
               ['dtype_type_ext_value', 6],
               ['dtype_type_file', 7],
               ['dtype_type_frame', 8],
               ['dtype_type_integer', 9],
               ['dtype_type_ipv4_packet', 10],
               ['dtype_type_ipv6_packet', 11],
               ['dtype_type_ntpstamp', 12],
               ['dtype_type_packet', 13],
               ['dtype_type_path', 14],
               ['dtype_type_portlist', 15],
               ['dtype_type_real', 16],
               ['dtype_type_string', 17],
               ['dtype_type_url', 18],
               ['dtype_type_winreg', 19],
               ['dtype_type_xml', 20],

            ]
        );
    }
    
    unless (DurationType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'DurationType',
            [
               ['duration_type_day', 1],
               ['duration_type_ext_value', 2],
               ['duration_type_hour', 3],
               ['duration_type_minute', 4],
               ['duration_type_month', 5],
               ['duration_type_quarter', 6],
               ['duration_type_second', 7],
               ['duration_type_year', 8],

            ]
        );
    }
    
    unless (SystemType::SystemSpoofed->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'SystemType::SystemSpoofed',
            [
               ['System_spoofed_no', 1],
               ['System_spoofed_unknown', 2],
               ['System_spoofed_yes', 3],

            ]
        );
    }
    
    unless (ContactType::ContactRole->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ContactType::ContactRole',
            [
               ['Contact_role_admin', 1],
               ['Contact_role_cc', 2],
               ['Contact_role_creator', 3],
               ['Contact_role_ext_value', 4],
               ['Contact_role_irt', 5],
               ['Contact_role_tech', 6],

            ]
        );
    }
    
    unless (ContactType::ContactType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ContactType::ContactType',
            [
               ['Contact_type_ext_value', 1],
               ['Contact_type_organization', 2],
               ['Contact_type_person', 3],

            ]
        );
    }
    
    unless (CounterType::CounterType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'CounterType::CounterType',
            [
               ['Counter_type_alert', 1],
               ['Counter_type_byte', 2],
               ['Counter_type_event', 3],
               ['Counter_type_ext_value', 4],
               ['Counter_type_flow', 5],
               ['Counter_type_host', 6],
               ['Counter_type_message', 7],
               ['Counter_type_organization', 8],
               ['Counter_type_packet', 9],
               ['Counter_type_session', 10],
               ['Counter_type_site', 11],

            ]
        );
    }
    
    unless (AssessmentType::AssessmentOccurrence->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'AssessmentType::AssessmentOccurrence',
            [
               ['Assessment_occurrence_actual', 1],
               ['Assessment_occurrence_potential', 2],

            ]
        );
    }
    
    unless (ActionType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ActionType',
            [
               ['action_type_block_host', 1],
               ['action_type_block_network', 2],
               ['action_type_block_port', 3],
               ['action_type_contact_sender', 4],
               ['action_type_contact_source_site', 5],
               ['action_type_contact_target_site', 6],
               ['action_type_ext_value', 7],
               ['action_type_investigate', 8],
               ['action_type_nothing', 9],
               ['action_type_other', 10],
               ['action_type_rate_limit_host', 11],
               ['action_type_rate_limit_network', 12],
               ['action_type_rate_limit_port', 13],
               ['action_type_remediate_other', 14],
               ['action_type_status_new_info', 15],
               ['action_type_status_triage', 16],

            ]
        );
    }
    
    unless (RecordPatternType::RecordPatternOffsetunit->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'RecordPatternType::RecordPatternOffsetunit',
            [
               ['RecordPattern_offsetunit_byte', 1],
               ['RecordPattern_offsetunit_ext_value', 2],
               ['RecordPattern_offsetunit_line', 3],

            ]
        );
    }
    
    unless (TimeImpactType::TimeImpactMetric->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'TimeImpactType::TimeImpactMetric',
            [
               ['TimeImpact_metric_downtime', 1],
               ['TimeImpact_metric_elapsed', 2],
               ['TimeImpact_metric_ext_value', 3],
               ['TimeImpact_metric_labor', 4],

            ]
        );
    }
    
    unless (ConfidenceType::ConfidenceRating->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ConfidenceType::ConfidenceRating',
            [
               ['Confidence_rating_high', 1],
               ['Confidence_rating_low', 2],
               ['Confidence_rating_medium', 3],
               ['Confidence_rating_numeric', 4],

            ]
        );
    }
    
    unless (RestrictionType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'RestrictionType',
            [
               ['restriction_type_default', 1],
               ['restriction_type_need_to_know', 2],
               ['restriction_type_private', 3],
               ['restriction_type_public', 4],

            ]
        );
    }
    
    unless (SystemType::SystemCategory->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'SystemType::SystemCategory',
            [
               ['System_category_ext_value', 1],
               ['System_category_infrastructure', 2],
               ['System_category_intermediate', 3],
               ['System_category_sensor', 4],
               ['System_category_source', 5],
               ['System_category_target', 6],

            ]
        );
    }
    
    unless (RecordPatternType::RecordPatternType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'RecordPatternType::RecordPatternType',
            [
               ['RecordPattern_type_binary', 1],
               ['RecordPattern_type_ext_value', 2],
               ['RecordPattern_type_regex', 3],
               ['RecordPattern_type_xpath', 4],

            ]
        );
    }
    
    unless (ImpactType::ImpactCompletion->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'ImpactType::ImpactCompletion',
            [
               ['Impact_completion_failed', 1],
               ['Impact_completion_succeeded', 2],

            ]
        );
    }
    
    unless (RegistryHandleType::RegistryHandleRegistry->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_enum(
            'RegistryHandleType::RegistryHandleRegistry',
            [
               ['RegistryHandle_registry_afrinic', 1],
               ['RegistryHandle_registry_apnic', 2],
               ['RegistryHandle_registry_arin', 3],
               ['RegistryHandle_registry_ext_value', 4],
               ['RegistryHandle_registry_internic', 5],
               ['RegistryHandle_registry_lacnic', 6],
               ['RegistryHandle_registry_local', 7],
               ['RegistryHandle_registry_ripe', 8],

            ]
        );
    }
    
    unless (CounterType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'CounterType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'CounterType::CounterType', 
                    'type', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_type', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'meaning', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'DurationType', 
                    'duration', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_duration', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_FLOAT(), 
                    'content', 6, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (TimeImpactType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'TimeImpactType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SeverityType', 
                    'severity', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'TimeImpactType::TimeImpactMetric', 
                    'metric', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_metric', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'DurationType', 
                    'duration', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_duration', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_FLOAT(), 
                    'content', 6, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (PostalAddressType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'PostalAddressType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'meaning', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'lang', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (SystemType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'SystemType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'NodeType', 
                    'Node', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ServiceType', 
                    'Service', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'SoftwareType', 
                    'OperatingSystem', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'CounterType', 
                    'Counter', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SystemType::SystemSpoofed', 
                    'spoofed', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'interface', 8, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 9, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_category', 10, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'SystemType::SystemCategory', 
                    'category', 11, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (RecordPatternType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'RecordPatternType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'RecordPatternType::RecordPatternType', 
                    'type', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_type', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'offset', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RecordPatternType::RecordPatternOffsetunit', 
                    'offsetunit', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_offsetunit', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'instance', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 7, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (HistoryType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'HistoryType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'HistoryItemType', 
                    'HistoryItem', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 2, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ContactMeansType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ContactMeansType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'meaning', 2, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (RelatedActivityType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'RelatedActivityType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'IncidentIDType', 
                    'IncidentID', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'UrlType', 
                    'URL', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (AddressType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'AddressType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'AddressType::AddressCategory', 
                    'category', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_category', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'vlan_name', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'vlan_num', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 5, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (HistoryItemType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'HistoryItemType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'DateTime', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'IncidentIDType', 
                    'IncidentID', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'ContactType', 
                    'Contact', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_action', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'ActionType', 
                    'action', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 8, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (NodeRoleType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'NodeRoleType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'lang', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_category', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'NodeRoleType::NodeRoleCategory', 
                    'category', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (NodeType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'NodeType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'NodeName', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'AddressType', 
                    'Address', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'MLStringType', 
                    'Location', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'DateTime', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'NodeRoleType', 
                    'NodeRole', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'CounterType', 
                    'Counter', 6, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (EventDataType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'EventDataType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'DetectTime', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'StartTime', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'EndTime', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ContactType', 
                    'Contact', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'AssessmentType', 
                    'Assessment', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MethodType', 
                    'Method', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'FlowType', 
                    'Flow', 8, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExpectationType', 
                    'Expectation', 9, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RecordType', 
                    'Record', 10, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    Google::ProtocolBuffers::Constants::TYPE_BYTES(), 
                    'EventData', 11, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 12, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 13, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (RecordDataType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'RecordDataType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'DateTime', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SoftwareType', 
                    'Application', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'RecordPatternType', 
                    'RecordPattern', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'RecordItem', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 7, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ExtensionType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ExtensionType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_dtype', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'formatid', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'meaning', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'ExtensionType::DtypeType', 
                    'dtype', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 8, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 9, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (SoftwareType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'SoftwareType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'UrlType', 
                    'URL', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'vendor', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'version', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'configid', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'name', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'patch', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'family', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'swid', 8, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ServiceType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ServiceType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'Port', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'Portlist', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'ProtoType', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'ProtoCode', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'ProtoField', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SoftwareType', 
                    'Application', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_INT32(), 
                    'ip_protocol', 7, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (IODEFDocumentType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'IODEFDocumentType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_FLOAT(), 
                    'version', 1, 1.0
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'IncidentType', 
                    'Incident', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'formatid', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'lang', 4, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (AlternativeIDType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'AlternativeIDType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'IncidentIDType', 
                    'IncidentID', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 2, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (UrlType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'UrlType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_BYTES(), 
                    'content', 1, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (IncidentType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'IncidentType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'IncidentIDType', 
                    'IncidentID', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'AlternativeIDType', 
                    'AlternativeID', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RelatedActivityType', 
                    'RelatedActivity', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'DetectTime', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'StartTime', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'EndTime', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ReportTime', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 8, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'AssessmentType', 
                    'Assessment', 9, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MethodType', 
                    'Method', 10, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ContactType', 
                    'Contact', 11, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'EventDataType', 
                    'EventData', 12, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'HistoryType', 
                    'History', 13, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 14, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'IncidentType::IncidentPurpose', 
                    'purpose', 15, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_purpose', 16, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'lang', 17, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 18, 3
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ConfidenceType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ConfidenceType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'ConfidenceType::ConfidenceRating', 
                    'rating', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_FLOAT(), 
                    'content', 2, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (RecordType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'RecordType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'RecordDataType', 
                    'RecordData', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 2, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ExpectationType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ExpectationType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'StartTime', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'EndTime', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'ContactType', 
                    'Contact', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_action', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'ActionType', 
                    'action', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SeverityType', 
                    'severity', 8, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (MethodType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'MethodType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ReferenceType', 
                    'Reference', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 4, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (RegistryHandleType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'RegistryHandleType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RegistryHandleType::RegistryHandleRegistry', 
                    'registry', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_registry', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ImpactType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ImpactType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'ImpactType::ImpactType', 
                    'type', 1, 13
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'ImpactType::ImpactCompletion', 
                    'completion', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'lang', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_type', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SeverityType', 
                    'severity', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'MLStringType', 
                    'content', 6, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (IncidentIDType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'IncidentIDType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'name', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'instance', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 4, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (MLStringType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'MLStringType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'lang', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'content', 2, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (MonetaryImpactType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'MonetaryImpactType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'SeverityType', 
                    'severity', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'currency', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    Google::ProtocolBuffers::Constants::TYPE_FLOAT(), 
                    'content', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ContactType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ContactType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'MLStringType', 
                    'ContactName', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'RegistryHandleType', 
                    'RegistryHandle', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'PostalAddressType', 
                    'PostalAddress', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ContactMeansType', 
                    'Email', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ContactMeansType', 
                    'Telephone', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'ContactMeansType', 
                    'Fax', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'Timezone', 8, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ContactType', 
                    'Contact', 9, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 10, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'ContactType::ContactType', 
                    'type', 11, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'ContactType::ContactRole', 
                    'role', 12, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 13, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_type', 14, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    Google::ProtocolBuffers::Constants::TYPE_STRING(), 
                    'ext_role', 15, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (AssessmentType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'AssessmentType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ImpactType', 
                    'Impact', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'TimeImpactType', 
                    'TimeImpact', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MonetaryImpactType', 
                    'MonetaryImpact', 3, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'CounterType', 
                    'Counter', 4, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'ConfidenceType', 
                    'Confidence', 5, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'ExtensionType', 
                    'AdditionalData', 6, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'AssessmentType::AssessmentOccurrence', 
                    'occurrence', 7, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_OPTIONAL(), 
                    'RestrictionType', 
                    'restriction', 8, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (FlowType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'FlowType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'SystemType', 
                    'System', 1, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

    unless (ReferenceType->can('_pb_fields_list')) {
        Google::ProtocolBuffers->create_message(
            'ReferenceType',
            [
                [
                    Google::ProtocolBuffers::Constants::LABEL_REQUIRED(), 
                    'MLStringType', 
                    'ReferenceName', 1, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'UrlType', 
                    'URL', 2, undef
                ],
                [
                    Google::ProtocolBuffers::Constants::LABEL_REPEATED(), 
                    'MLStringType', 
                    'Description', 3, undef
                ],

            ],
            { 'create_accessors' => 1, 'follow_best_practice' => 1,  }
        );
    }

}
1;