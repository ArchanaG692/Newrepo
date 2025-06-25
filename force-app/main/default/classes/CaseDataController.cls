public with sharing class CaseDataController {
    public class CSVDataResponse {
        @AuraEnabled public List<Map<String, String>> csvData = new List<Map<String, String>>();
        @AuraEnabled public Integer clsViolationCount = 0;
        @AuraEnabled public Integer lwcViolationCount = 0;
        @AuraEnabled public Integer auraViolationCount = 0;
        @AuraEnabled public Integer objectsViolationCount = 0;
    }

    @AuraEnabled(cacheable=true)
    public static CSVDataResponse getCSVData(String caseId) {
        CSVDataResponse response = new CSVDataResponse();

        try {
            // Step 1: Get latest ContentDocumentId from Case's Files Related List
            List<ContentDocumentLink> contentLinks = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :caseId
                ORDER BY ContentDocumentId DESC
                LIMIT 1
            ];

            if (contentLinks.isEmpty()) {
                System.debug('⚠️ No files found in Case Related List.');
                return response;
            }

            Id contentDocumentId = contentLinks[0].ContentDocumentId;

            // Step 2: Get latest ContentVersion (CSV file)
            List<ContentVersion> contentVersions = [
                SELECT Id, VersionData, Title 
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                AND FileType = 'CSV'
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            if (contentVersions.isEmpty()) {
                System.debug('⚠️ No CSV file found.');
                return response;
            }

            ContentVersion csvFile = contentVersions[0];

            // Step 3: Read CSV content
            Blob csvBlob = csvFile.VersionData;
            String csvContent = csvBlob.toString();

            // Step 4: Parse CSV content
            List<String> lines = csvContent.split('\n');
            if (lines.isEmpty()) {
                System.debug('⚠️ CSV file is empty.');
                return response;
            }

            // Convert headers to lowercase for consistency
            List<String> headers = lines[0].toLowerCase().split(',');

            // Step 5: Process each row
            for (Integer i = 1; i < lines.size(); i++) {
                List<String> values = lines[i].split(',');

                if (values.size() == headers.size()) {
                    Map<String, String> rowData = new Map<String, String>();
                    for (Integer j = 0; j < headers.size(); j++) {
                        rowData.put(headers[j].trim(), values[j].trim());
                    }

                    // Count violations and add category
                    String category = '';
                    if (rowData.containsKey('file')) {
                        String filePath = rowData.get('file').toLowerCase().trim();
                        String normalizedPath = filePath.replaceAll('_', '/');

                        System.debug('📁 Normalized path: ' + normalizedPath);

                        if (normalizedPath.contains('/classes/')) {
                            response.clsViolationCount++;
                            category = 'Apex Class';
                        } else if (normalizedPath.contains('/lwc/')) {
                            response.lwcViolationCount++;
                            category = 'LWC';
                        } else if (normalizedPath.contains('/aura/')) {
                            response.auraViolationCount++;
                            category = 'Aura';
                        } else if (normalizedPath.contains('/objects/')) {
                            response.objectsViolationCount++;
                            category = 'Objects';
                        }
                    }

                    // ✅ Inject category so LWC modal filters work
                    rowData.put('category', category);
                    response.csvData.add(rowData);
                }
            }

            // Summary logging
            System.debug('✅ Rows parsed: ' + response.csvData.size());
            System.debug('✅ Apex Violations: ' + response.clsViolationCount);
            System.debug('✅ LWC Violations: ' + response.lwcViolationCount);
            System.debug('✅ Aura Violations: ' + response.auraViolationCount);
            System.debug('✅ Object Violations: ' + response.objectsViolationCount);

        } catch (Exception e) {
            System.debug('❌ Error processing CSV: ' + e.getMessage());
        }

        return response;
    }
}
