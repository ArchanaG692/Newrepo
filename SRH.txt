public with sharing class ScannerReportHandler {
    private static Boolean isProcessing = false;
    private static final String RECORD_TYPE_DEVELOPER_NAME = 'MCSE_Code_Scan'; 

    @future
    public static void processFiles(Set<Id> contentDocumentIds) {
        if (isProcessing) {
            //System.debug(' Process already running. Skipping to prevent recursion.');
            return;
        }

        isProcessing = true;
        

        if (contentDocumentIds.isEmpty()) {
            isProcessing = false;
            return;
        }

        //  Fetch RecordTypeId dynamically
        Id caseRecordTypeId;
        try {
            caseRecordTypeId = [
                SELECT Id FROM RecordType 
                WHERE SObjectType = 'Case' 
                AND DeveloperName = :RECORD_TYPE_DEVELOPER_NAME 
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            isProcessing = false;
            return;
        }

        // Fetch ContentVersion records
        List<ContentVersion> contentVersions = [ 
            SELECT Id, ContentDocumentId, Title, PathOnClient 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
        ];

        if (contentVersions.isEmpty()) {
            isProcessing = false;
            return;
        }

        List<Case> casesToInsert = new List<Case>();
        Map<Id, Id> caseToFileMap = new Map<Id, Id>();

        for (ContentVersion cv : contentVersions) {

            if (cv.Title.contains('Code Scanner') || cv.Title.contains('Code Scanner Delta')) {

                Case newCase = new Case();
                newCase.RecordTypeId = caseRecordTypeId;
                newCase.File_Name__c = cv.Title;
                newCase.Status = 'New';
                newCase.Origin = 'Code Scan';   

                String commitAuthor = '';         

                try {
                    ContentVersion cvWithData = [
                        SELECT VersionData 
                        FROM ContentVersion 
                        WHERE Id = :cv.Id 
                        LIMIT 1
                    ];
                    Blob csvBlob = cvWithData.VersionData;
                    String csvContent = csvBlob.toString();

                    List<String> csvLines = csvContent.split('\n');
                    if (csvLines.size() > 1) {
                        String headerLine = csvLines[0];
                        List<String> headers = headerLine.split(',');

                        Integer targetBranchIndex = headers.indexOf('TargetBranch');
                        Integer commitIndex = headers.indexOf('Commit');
                        Integer severityIndex = headers.indexOf('Severity');

                        Boolean setPriority = false;
                        for (Integer i = 1; i < csvLines.size(); i++) {
                            List<String> values = csvLines[i].split(',');

                            if (targetBranchIndex != -1 && values.size() > targetBranchIndex) {
                                String targetBranchValue = values[targetBranchIndex].trim();
                                newCase.Target_Environment__c = targetBranchValue;
                            }

                            if (commitIndex != -1 && values.size() > commitIndex) {
                                String commitValue = values[commitIndex].trim();
                                newCase.Case_Created_By__c = commitValue;
                                commitAuthor = commitValue;
                            }
							
                            if (!setPriority && severityIndex != -1 && values.size() > severityIndex) {
                                String severityValue = values[severityIndex].trim();
                                if (severityValue == '1' || severityValue == '2') {
                                    newCase.Priority = 'High';
                                    setPriority = true;
                                } else if (severityValue == '3') {
                                    newCase.Priority = 'Medium';
                                    setPriority = true;
                                } else if (severityValue == '4' || severityValue == '5') {
                                    newCase.Priority = 'Low';
                                    setPriority = true;
                                }
                            }
                            if (newCase.Target_Environment__c != null || newCase.Case_Created_By__c != null) {
                                break;
                            }
                        }
                    }
                } catch (Exception e) {
                    //System.debug(' Error reading CSV content: ' + e.getMessage());
                }

                newCase.Subject = commitAuthor + ' - ' + cv.Title;  

                casesToInsert.add(newCase);
                caseToFileMap.put(cv.ContentDocumentId, null);
            }
        }

        if (!casesToInsert.isEmpty()) {
            try {
                insert casesToInsert;

                Integer index = 0;
                for (Case createdCase : casesToInsert) {
                    Id docId = contentVersions[index].ContentDocumentId;
                    caseToFileMap.put(docId, createdCase.Id);
                    index++;
                }

            } catch (DmlException e) {
                isProcessing = false;
                return;
            }
        } else {
            isProcessing = false;
            return;
        }

        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

        for (Id contentDocId : caseToFileMap.keySet()) {
            Id caseId = caseToFileMap.get(contentDocId);

            if (caseId != null) {
                List<ContentDocumentLink> existingLinks = [
                    SELECT Id FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :caseId 
                    AND ContentDocumentId = :contentDocId
                ];

                if (existingLinks.isEmpty()) {
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentId = contentDocId;
                    link.LinkedEntityId = caseId;
                    link.ShareType = 'V';
                    link.Visibility = 'AllUsers';

                    linksToInsert.add(link);
                }
            }
        }

        if (!linksToInsert.isEmpty()) {
            try {
                insert linksToInsert;
            } catch (DmlException e) {
                //System.debug(' Error linking files to Case: ' + e.getMessage());
            }
        }

        isProcessing = false;
    }
}
