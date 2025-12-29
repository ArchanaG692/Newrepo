/**
* @File Name : PlatformRequestController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On :
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 16, 2025 |   | Initial Version
**/

public without sharing class PlatformRequestController {

    public class FieldConfig {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean required;
        @AuraEnabled public String dataType;     // TEXT, DATE, EMAIL, URL, PICKLIST, TEXTAREA
        @AuraEnabled public String placeholder;
        @AuraEnabled public List<OptionDTO> options; // only for picklists
    }

    public class OptionDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public OptionDTO(String l, String v){ label = l; value = v; }
    }

    public class ConfigDTO {
        @AuraEnabled public Map<String, Id> recordTypeIds;
        @AuraEnabled public List<FieldConfig> fields;
        @AuraEnabled public String recordTypeDevName;
    }

    @AuraEnabled(cacheable=true)
    public static ConfigDTO getConfig(String recordTypeDevName) {
        if (String.isBlank(recordTypeDevName)) {
            recordTypeDevName = 'Design_Review';
        }

        ConfigDTO cfg = new ConfigDTO();
        cfg.recordTypeDevName = recordTypeDevName;
        cfg.recordTypeIds = new Map<String, Id>();

        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Platform_Request__c'
        ]) {
            cfg.recordTypeIds.put(rt.DeveloperName, rt.Id);
        }

        String fsName =
            recordTypeDevName == 'Design_Review'    ? 'FS_Design_Review' :
            recordTypeDevName == 'Data_Model'       ? 'FS_Data_Model' :
                                                      'FS_Release_Request';

        cfg.fields = readFieldSet(fsName);
        return cfg;
    }

    private static List<FieldConfig> readFieldSet(String fieldSetName) {
        List<FieldConfig> outList = new List<FieldConfig>();

        Map<String, Schema.SObjectField> fmap =
            Platform_Request__c.SObjectType.getDescribe().fields.getMap();

        Schema.FieldSet fs = Schema.SObjectType.Platform_Request__c.FieldSets.getMap().get(fieldSetName);
        if (fs == null) {
            return outList;
        }

        for (Schema.FieldSetMember m : fs.getFields()) {
            String api = m.getFieldPath();
            Schema.SObjectField f = fmap.get(api);
            if (f == null) {
                continue;
            }

            Schema.DescribeFieldResult d = f.getDescribe();

            FieldConfig fc = new FieldConfig();
            fc.apiName = api;
            fc.label = m.getLabel();
            fc.required = m.getRequired();
            fc.options = new List<OptionDTO>();

            Schema.DisplayType t = d.getType();
            if (t == Schema.DisplayType.Picklist) {
                fc.dataType = 'PICKLIST';
                for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                    if (!pe.isActive()) {
                        continue;
                    }
                    fc.options.add(new OptionDTO(pe.getLabel(), pe.getValue()));
                }
            } else if (t == Schema.DisplayType.Date) {
                fc.dataType = 'DATE';
            } else if (t == Schema.DisplayType.Email) {
                fc.dataType = 'EMAIL';
            } else if (t == Schema.DisplayType.Url) {
                fc.dataType = 'URL';
            } else if (t == Schema.DisplayType.TextArea) {
                fc.dataType = 'TEXTAREA';
            } else {
                fc.dataType = 'TEXT';
            }

            fc.placeholder = buildPlaceholder(fc.apiName, fc.label, fc.dataType);
            outList.add(fc);
        }
        return outList;
    }

    private static String buildPlaceholder(String api, String label, String type) {
        Map<String, String> special = new Map<String, String>{
            'Requester_Name__c'         => 'John Doe',
            'Requester_Email__c'        => 'john.doe@cvshealth.com',
            'Project_Name__c'           => 'Enter your project name',
            'Request_Title__c'          => 'Brief descriptive title for this request',
            'Design_Summary__c'         => 'Describe the solution you’re proposing, key components, and what you want reviewed…',
            'Business_Justification__c' => 'Explain the business need and expected impact…',
            'Technical_Details__c'      => 'Provide details: object names, field names, data types, relationships, picklists…',
            'Release_Notes__c'          => 'List all components, changes, dependencies, and special instructions…',
            'Design_Document_Link__c'   => 'Link to your design document (Confluence, SharePoint, etc.)',
            'Test_Evidence_Link__c'     => 'Link to test results and UAT sign-off documentation'
        };
        if (special.containsKey(api)) {
            return special.get(api);
        }

        if (type == 'PICKLIST') return 'Select ' + label;
        if (type == 'DATE') return 'mm/dd/yyyy';
        if (type == 'URL') return 'Paste link here';
        if (type == 'TEXTAREA') return 'Enter details…';
        return 'Enter ' + label;
    }

    // =========================
    // NEW: Step-1 Create record
    // =========================
    @AuraEnabled
    public static Id createPlatformRequest(Platform_Request__c req) {
        if (req == null) {
            throw new AuraHandledException('Request payload is empty.');
        }
        if (String.isBlank(req.Requester_Email__c)) {
            throw new AuraHandledException('Requester Email is required.');
        }

        insert req;
        return req.Id;
    }

    // =====================================================
    // NEW: Step-2 Final submit (send email + attachments)
    // =====================================================
    @AuraEnabled
    public static Id finalSubmitRequest(Id requestId, List<Id> contentDocumentIds) {
        if (requestId == null) {
            throw new AuraHandledException('Request Id is missing.');
        }

        Platform_Request__c pr = [
            SELECT Id, Name, Status__c, RecordType.Name,
                   Requester_Name__c, Requester_Email__c, Project_Name__c,
                   Application__c, Review_Type__c, Requested_Review_Date__c
            FROM Platform_Request__c
            WHERE Id = :requestId
            LIMIT 1
        ];

        OrgWideEmailAddress owea = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = :Label.CSV_Health_Service_Request_Email_Address
            LIMIT 1
        ];

        EmailTemplate tpl = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'Platform_Request_Submission_Notification'
            LIMIT 1
        ];

        if (String.isBlank(tpl.HtmlValue)) {
            throw new AuraHandledException('Email template HTML body is empty.');
        }

        String reqNumber = !String.isBlank(pr.Name) ? pr.Name : String.valueOf(pr.Id);
        String recordTypeLabel = (pr.RecordType != null && !String.isBlank(pr.RecordType.Name))
            ? pr.RecordType.Name
            : 'Request';
        String statusLabel = !String.isBlank(pr.Status__c) ? pr.Status__c : 'Submitted';

        String subject = 'Platform Request - ' + reqNumber + ' - ' + recordTypeLabel + ' - ' + statusLabel;

        String body = tpl.HtmlValue
            .replace('{{{RequesterName}}}', pr.Requester_Name__c != null ? pr.Requester_Name__c : '')
            .replace('{{{RequesterEmail}}}', pr.Requester_Email__c != null ? pr.Requester_Email__c : '')
            .replace('{{{ProjectName}}}', pr.Project_Name__c != null ? pr.Project_Name__c : '')
            .replace('{{{Application}}}', pr.Application__c != null ? pr.Application__c : '')
            .replace('{{{ReviewType}}}', pr.Review_Type__c != null ? pr.Review_Type__c : '')
            .replace('{{{RequestedReviewDate}}}', pr.Requested_Review_Date__c != null ? String.valueOf(pr.Requested_Review_Date__c) : '')
            .replace('{{{PlatformRequestNumber}}}', pr.Name != null ? pr.Name : '')
            .replace('{{{DesignReview}}}', recordTypeLabel)
            .replace('{{{Status}}}', statusLabel);

        // Build attachments from uploaded files
        List<Messaging.EmailFileAttachment> atts = new List<Messaging.EmailFileAttachment>();

        // Optional: enforce your limits
        final Integer MAX_EACH_BYTES  = 3 * 1024 * 1024;   // 3MB
        final Integer MAX_TOTAL_BYTES = 12 * 1024 * 1024;  // 12MB

        Integer totalBytes = 0;

        if (contentDocumentIds != null && !contentDocumentIds.isEmpty()) {
            List<ContentVersion> vers = [
                SELECT ContentDocumentId, Title, FileExtension, VersionData, ContentSize
                FROM ContentVersion
                WHERE IsLatest = true
                AND ContentDocumentId IN :contentDocumentIds
            ];

            for (ContentVersion cv : vers) {
                if (cv.ContentSize != null && cv.ContentSize > MAX_EACH_BYTES) {
                    throw new AuraHandledException('One attachment exceeds 3MB: ' + cv.Title);
                }
                totalBytes += (cv.ContentSize == null ? 0 : cv.ContentSize);
                if (totalBytes > MAX_TOTAL_BYTES) {
                    throw new AuraHandledException('Total attachments exceed 12MB. Please remove some files.');
                }

                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                String ext = (cv.FileExtension != null) ? ('.' + cv.FileExtension) : '';
                efa.setFileName(cv.Title + ext);
                efa.setBody(cv.VersionData);
                atts.add(efa);
            }
        }

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new List<String>{ pr.Requester_Email__c });
        msg.setOrgWideEmailAddressId(owea.Id);
        msg.setSubject(subject);
        msg.setHtmlBody(body);
        msg.setWhatId(pr.Id);
        msg.setSaveAsActivity(true);

        if (!atts.isEmpty()) {
            msg.setFileAttachments(atts);
        }

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg });
        return pr.Id;
    }

    // (Optional) Keep your old method name for backward compatibility
    @AuraEnabled
    public static Id submitRequest(Platform_Request__c req) {
        // Old single-step submit kept (no attachments)
        Id idCreated = createPlatformRequest(req);
        return finalSubmitRequest(idCreated, new List<Id>());
    }
}
