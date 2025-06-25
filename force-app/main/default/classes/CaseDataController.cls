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
            List<Attachment> attachments = [
                SELECT Id, Body, Name
                FROM Attachment
                WHERE ParentId = :caseId 
                AND Name LIKE '%.csv'
                ORDER BY CreatedDate DESC
            ];

            if (attachments.isEmpty()) return response;

            for (Attachment csvFile : attachments) {
                Blob csvBlob = csvFile.Body;
                String csvContent = csvBlob.toString();
                List<String> lines = csvContent.split('\n');
                if (lines.isEmpty()) continue;

                // Parse headers and normalize case
                List<String> headers = parseCSVLine(lines[0]);
                List<String> lowercaseHeaders = new List<String>();
                for (String h : headers) lowercaseHeaders.add(h.trim().toLowerCase());

                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> values = parseCSVLine(lines[i]);
                    if (values.size() != headers.size()) continue;

                    Map<String, String> rowData = new Map<String, String>();
                    for (Integer j = 0; j < headers.size(); j++) {
                        rowData.put(lowercaseHeaders[j], values[j].trim().replaceAll('^\"|\"$', ''));
                    }

                    // Count violations
                    if (rowData.containsKey('file')) {
                        String filePath = rowData.get('file').toLowerCase();
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

        } catch (Exception e) {
            System.debug('❌ Error parsing CSV: ' + e.getMessage());
        }

        return response;
    }

    private static List<String> parseCSVLine(String csvLine) {
        List<String> columns = new List<String>();
        Boolean insideQuote = false;
        String currentValue = '';

        for (Integer i = 0; i < csvLine.length(); i++) {
            String currentChar = csvLine.substring(i, i + 1);
            if (currentChar == '"') {
                insideQuote = !insideQuote;
            } else if (currentChar == ',' && !insideQuote) {
                columns.add(currentValue.trim());
                currentValue = '';
            } else {
                currentValue += currentChar;
            }
        }
        columns.add(currentValue.trim());
        return columns;
    }
}
