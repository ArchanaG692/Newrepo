public with sharing class File {
    
    public static void processNewFiles(List<ContentVersion> contentVersions) {
        List<Id> contentDocIds = new List<Id>();

        for (ContentVersion file : contentVersions) {
            if (file.ContentDocumentId != null) {
                contentDocIds.add(file.ContentDocumentId);
            }
        }

        if (!contentDocIds.isEmpty()) {
            importVulnerabilityData(contentDocIds);  // ✅ Call correctly defined method
        }
    }

    // ✅ Ensure this method exists with the correct signature
    public static void importVulnerabilityData(List<Id> contentDocIds) {
        try {
            // Fetch ContentVersion records for the given ContentDocumentIds
            List<ContentVersion> fileList = [SELECT Id, VersionData, ContentDocumentId
                                             FROM ContentVersion
                                             WHERE ContentDocumentId IN :contentDocIds
                                             ORDER BY CreatedDate DESC];

            if (fileList.isEmpty()) {
                return;
            }

            List<Vulnerability__c> newRecords = new List<Vulnerability__c>();

            for (ContentVersion file : fileList) {
                if (file.VersionData == null) {
                    continue;
                }


                // Convert the file content (CSV) to string
                String csvContent = file.VersionData.toString();
                List<String> lines = csvContent.split('\\n');

                if (lines.isEmpty()) {
                    continue;
                }

                // Extract headers
                List<String> headers = parseCSVLine(lines[0]);
                Map<String, Integer> columnMap = new Map<String, Integer>();

                for (Integer i = 0; i < headers.size(); i++) {
                    columnMap.put(headers[i].trim().toLowerCase(), i);
                }


                // Required field mappings
                Map<String, String> fieldMappings = new Map<String, String>{
                    'problem' => 'problem', 
                    'severity' => 'severity', 
                    'file' => 'file', 
                    'templine' => 'line', 
                    'column' => 'column', 
                    'rule' => 'rule',
                    'description' => 'description', 
                    'url' => 'url', 
                    'category' => 'category', 
                    'engine' => 'engine', 
                    'commit' => 'commit', 
                    'actualline' => 'actual line',
                    'targetbranch' => 'target branch'
                };

                // Validate all required fields exist in CSV
                for (String field : fieldMappings.keySet()) {
                    if (!columnMap.containsKey(field)) {
                        return;
                    }
                }

                // Process CSV lines and create Vulnerability__c records
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> columns = parseCSVLine(lines[i]);

                    if (columns.size() < headers.size()) {
                        continue;
                    }

                    Vulnerability__c vuln = new Vulnerability__c();
                    vuln.Problem__c = columns[columnMap.get('problem')].trim();
                    vuln.Severity__c = columns[columnMap.get('severity')].trim();
                    vuln.File__c = columns[columnMap.get('file')].trim();
                    vuln.Line__c = columns[columnMap.get('templine')].trim();
                    vuln.Column__c = columns[columnMap.get('column')].trim();
                    vuln.Rule__c = columns[columnMap.get('rule')].trim();
                    vuln.Description__c = columns[columnMap.get('description')].trim();
                    vuln.URL__c = columns[columnMap.get('url')].trim();
                    vuln.Category__c = columns[columnMap.get('category')].trim();
                    vuln.Engine__c = columns[columnMap.get('engine')].trim();
                    vuln.Commit__c = columns[columnMap.get('commit')].trim();
                    vuln.ActualLine__c = columns[columnMap.get('actualline')].trim();
                    vuln.TargetBranch__c = columns[columnMap.get('targetbranch')].trim();

                    newRecords.add(vuln);
                }

                // Insert records in bulk
                if (!newRecords.isEmpty()) {
                    insert newRecords;
                } else {
                    //System.debug(' No valid records found.');
                }
            }

        } catch (Exception e) {
            //System.debug(' Error processing file: ' + e.getMessage());
        }
    }

    // CSV Parsing Function (Handles Quoted Values)
    public static List<String> parseCSVLine(String csvLine) {
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
