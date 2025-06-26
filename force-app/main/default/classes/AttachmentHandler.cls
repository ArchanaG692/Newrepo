/**
* @File Name : AttachmentHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 7, 2025 |   | Initial Version
**/

public with sharing class AttachmentHandler {
    @AuraEnabled
    public static void createAttachmentForCase(String caseId) {
        try {
            // Fetch the related Scanner Report Case record
            Scanner_Report_Case__c caseRecord = [
                SELECT Id, File_Id__c, File_Name__c 
                FROM Scanner_Report_Case__c 
                WHERE Id = :caseId 
                LIMIT 1
            ];

            if (caseRecord.File_Id__c == null) {
                //System.debug(' No file associated with this case.');
                return;
            }

            // Retrieve the CSV file from ContentVersion
            List<ContentVersion> fileVersions = [
                SELECT VersionData, Title, FileExtension
                FROM ContentVersion 
                WHERE ContentDocumentId = :caseRecord.File_Id__c 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            if (fileVersions.isEmpty()) {
                //System.debug(' File not found for ContentDocumentId: ' + caseRecord.File_Id__c);
                return;
            }

            ContentVersion fileVersion = fileVersions[0];

            // Ensure the file is a CSV before creating an attachment
            if (fileVersion.FileExtension != 'csv') {
                //System.debug('Skipping non-CSV file: ' + fileVersion.Title);
                return;
            }

            // Ensure the file name has a .csv extension
            String fileName = fileVersion.Title;
            if (!fileName.toLowerCase().endsWith('.csv')) {
                fileName += '.csv';
            }

            // Convert file data into a Blob
            Blob fileBlob = fileVersion.VersionData;

            // Create an Attachment record with a CSV format
            Attachment attachment = new Attachment();
            attachment.Name = fileName; // Ensure correct file extension
            attachment.Body = fileBlob; // Store CSV content correctly
            attachment.ParentId = caseRecord.Id; // Attach to Scanner Report Case record
            attachment.ContentType = 'application/octet-stream'; // Ensure it downloads correctly as a CSV

            insert attachment;


        } catch (Exception e) {
            //System.debug(' Error creating CSV attachment: ' + e.getMessage());
        }
    }
}
