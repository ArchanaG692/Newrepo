public with sharing class File {

    public static void processNewFiles(List<ContentVersion> contentVersions) {
        List<Id> contentDocIds = new List<Id>();

        for (ContentVersion file : contentVersions) {
            if (file.ContentDocumentId != null) {
                contentDocIds.add(file.ContentDocumentId);
            }
        }

        if (!contentDocIds.isEmpty()) {
            importVulnerabilityData(contentDocIds);
        }
    }

    public static void importVulnerabilityData(List<Id> contentDocIds) {
        try {
            List<ContentVersion> fileList = [
                SELECT Id, VersionData, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocIds
                ORDER BY CreatedDate DESC
            ];

            if (fileList.isEmpty()) return;

            List<Vulnerability__c> newRecords = new List<Vulnerability__c>();

            for (ContentVersion file : fileList) {
                if (file.VersionData == null) continue;

                String csvContent = file.VersionData.toString();
                List<String> lines = csvContent.split('\n');
                if (lines.isEmpty()) continue;

                // Parse headers
                List<String> headers = parseCSVLine(lines[0]);
                Map<String, Integer> columnMap = new Map<String, Integer>();

                for (Integer i = 0; i < headers.size(); i++) {
                    columnMap.put(headers[i].trim().toLowerCase(), i);  // Case-insensitive mapping
                }

                // V5 field mapping
                Map<String, String> fieldMappings = new Map<String, String>{
                    'rule'         => 'rule',
                    'engine'       => 'engine',
                    'severity'     => 'severity',
                    'tags'         => 'category',
                    'file'         => 'file',
                    'startline'    => 'line',
                    'startcolumn'  => 'column',
                    'message'      => 'description',
                    'resources'    => 'url',
                    'commit'       => 'commit',
                    'actualline'   => 'actual line',
                    'targetbranch' => 'target branch'
                };

                // Validate required headers
                for (String key : fieldMappings.keySet()) {
                    if (!columnMap.containsKey(key)) {
                        System.debug('⚠️ Missing required column: ' + key);
                        return;
                    }
                }

                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> columns = parseCSVLine(lines[i]);
                    if (columns.size() < headers.size()) continue;

                    Vulnerability__c vuln = new Vulnerability__c();
                    vuln.Rule__c          = columns[columnMap.get('rule')].trim();
                    vuln.Engine__c        = columns[columnMap.get('engine')].trim();
                    vuln.Severity__c      = columns[columnMap.get('severity')].trim();
                    vuln.Category__c      = columns[columnMap.get('tags')].trim();
                    vuln.File__c          = columns[columnMap.get('file')].trim();
                    vuln.Line__c          = columns[columnMap.get('startline')].trim();
                    vuln.Column__c        = columns[columnMap.get('startcolumn')].trim();
                    vuln.Description__c   = columns[columnMap.get('message')].trim();
                    vuln.URL__c           = columns[columnMap.get('resources')].trim();
                    vuln.Commit__c        = columns[columnMap.get('commit')].trim();
                    vuln.ActualLine__c    = columns[columnMap.get('actualline')].trim();
                    vuln.TargetBranch__c  = columns[columnMap.get('targetbranch')].trim();

                    newRecords.add(vuln);
                }
            }

            if (!newRecords.isEmpty()) {
                insert newRecords;
            }

        } catch (Exception e) {
            System.debug('⚠️ Error importing vulnerability data: ' + e.getMessage());
        }
    }

    // CSV Parsing Utility - Handles commas inside quoted fields
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
