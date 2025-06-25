public with sharing class CSVDataController {
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
            // Step 1: Fetch the CSV attachment
            List<Attachment> attachments = [
                SELECT Id, Body, Name
                FROM Attachment
                WHERE ParentId = :caseId 
                  AND Name LIKE '%.csv'
                ORDER BY CreatedDate DESC
            ];

            if (attachments.isEmpty()) {
                System.debug('❌ No attachments found for case: ' + caseId);
                return response;
            }

            for (Attachment csvFile : attachments) {
                Blob csvBlob = csvFile.Body;
                String csvContent = csvBlob.toString();

                List<String> lines = csvContent.split('\n');
                if (lines.isEmpty()) {
                    System.debug('⚠️ Attachment is empty.');
                    continue;
                }

                // Parse headers
                List<String> headers = parseCSVLine(lines[0]);
                List<String> lowercaseHeaders = new List<String>();
                for (String h : headers) {
                    lowercaseHeaders.add(h.trim().toLowerCase());
                }

                // Parse each row
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> values = parseCSVLine(lines[i]);
                    if (values.size() != headers.size()) continue;

                    Map<String, String> rowData = new Map<String, String>();
                    for (Integer j = 0; j < headers.size(); j++) {
                        rowData.put(lowercaseHeaders[j], values[j].trim().replaceAll('^\"|\"$', ''));
                    }

                    // Process file path to detect violation category
                    if (rowData.containsKey('file')) {
                        String filePath = rowData.get('file').toLowerCase();
                        String normalizedPath = filePath.replaceAll('_', '/');

                        System.debug('🔍 File: ' + filePath);
                        System.debug('📁 Normalized: ' + normalizedPath);

                        if (normalizedPath.contains('/classes/')) {
                            response.clsViolationCount++;
                        } else if (normalizedPath.contains('/lwc/')) {
                            response.lwcViolationCount++;
                        } else if (normalizedPath.contains('/aura/')) {
                            response.auraViolationCount++;
                        } else if (normalizedPath.contains('/objects/')) {
                            response.objectsViolationCount++;
                        }
                    }

                    response.csvData.add(rowData);
                }
            }

            // Summary log
            System.debug('✅ CSV Rows: ' + response.csvData.size());
            System.debug('✅ Ap
