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
            System.debug('🔍 Fetching latest CSV file from Case ID: ' + caseId);

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
            System.debug('✅ Found ContentDocumentId: ' + contentDocumentId);

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
            System.debug('✅ Found CSV file: ' + csvFile.Title);

            // Step 3: Read CSV content
            Blob csvBlob = csvFile.VersionData;
            String csvContent = csvBlob.toString();

            // Step 4: Parse CSV content
            List<String> lines = csvContent.split('\n');

            if (lines.isEmpty()) {
                System.debug('⚠️ CSV file is empty.');
                return response;
            }

            List<String> headers = lines[0].split(',');

            System.debug('✅ CSV Headers: ' + headers);

            // Process CSV rows
            for (Integer i = 1; i < lines.size(); i++) {
                List<String> values = lines[i].split(',');

                if (values.size() == headers.size()) {
                    Map<String, String> rowData = new Map<String, String>();
                    for (Integer j = 0; j < headers.size(); j++) {
                        rowData.put(headers[j].trim(), values[j].trim());
                    }

                    // Count violations based on file path
                    if (rowData.containsKey('File')) {
                        String filePath = rowData.get('File').trim();
                        if (filePath.contains('classes')) {
                            response.clsViolationCount++;
                        } else if (filePath.contains('lwc')) {
                            response.lwcViolationCount++;
                        } else if (filePath.contains('aura')) {
                            response.auraViolationCount++;
                        } else if (filePath.contains('objects')) {
                            response.objectsViolationCount++;
                        }
                    }

                    response.csvData.add(rowData);
                }
            }

            System.debug('✅ Successfully processed CSV data.');

        } catch (Exception e) {
            System.debug('❌ Error processing CSV: ' + e.getMessage());
        }

        return response;
    }
}
