@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PullRequestCaseLinker {

    // ✅ Now we support BOTH file fields on PR
    private static final String PR_CODE_FILE_FIELD = 'Check1_Report_File__c';
    private static final String PR_LWC_FILE_FIELD  = 'Check1_LWC_Report_File__c';

    public static void handleAfter(
        List<Pull_Request__c> newList,
        Map<Id, Pull_Request__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        System.debug('=== PullRequestCaseLinker.handleAfter START ===');
        System.debug('isInsert=' + isInsert + ', isUpdate=' + isUpdate + ', prCount=' + (newList == null ? 0 : newList.size()));

        if (newList == null || newList.isEmpty()) {
            System.debug('No PR records. Exiting.');
            return;
        }

        // 1) Collect file names to query + map normalized file -> PR Id
        Set<String> fileNamesForQuery = new Set<String>();
        Map<String, Id> normalizedFileToPrId = new Map<String, Id>();

        for (Pull_Request__c pr : newList) {
            if (pr == null) continue;

            // Read both fields
            List<String> rawFiles = new List<String>{
                (String) pr.get(PR_CODE_FILE_FIELD),
                (String) pr.get(PR_LWC_FILE_FIELD)
            };

            for (String rawFile : rawFiles) {
                System.debug('PR Id=' + pr.Id + ' raw file=' + rawFile);

                String normalized = normalize(rawFile);
                if (String.isBlank(normalized)) {
                    continue;
                }

                // Query Cases using ORIGINAL trimmed value (text IN comparisons)
                String trimmedOriginal = rawFile.trim();
                fileNamesForQuery.add(trimmedOriginal);

                // first PR wins for same filename in this transaction
                if (!normalizedFileToPrId.containsKey(normalized)) {
                    normalizedFileToPrId.put(normalized, pr.Id);
                }
            }
        }

        System.debug('Collected fileNamesForQuery=' + fileNamesForQuery);

        if (fileNamesForQuery.isEmpty()) {
            System.debug('No file names found in either PR field. Exiting.');
            return;
        }

        // 2) Query Cases matching either Code or LWC file names
        List<Case> matchingCases = [
            SELECT Id, File_Name__c, Pull_Request__c
            FROM Case
            WHERE File_Name__c IN :fileNamesForQuery
        ];

        System.debug('matchingCases size=' + matchingCases.size());

        if (matchingCases.isEmpty()) {
            System.debug('No cases found with File_Name__c IN collected file names. Exiting.');
            return;
        }

        // 3) Update Cases to link PR
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : matchingCases) {
            String caseFileNorm = normalize(c.File_Name__c);
            Id prId = normalizedFileToPrId.get(caseFileNorm);

            System.debug('Case Id=' + c.Id + ' caseFile=' + c.File_Name__c + ' norm=' + caseFileNorm + ' matchedPrId=' + prId);

            if (prId != null && c.Pull_Request__c != prId) {
                c.Pull_Request__c = prId;
                casesToUpdate.add(c);
            }
        }

        System.debug('casesToUpdate size=' + casesToUpdate.size());

        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
                System.debug('✅ Cases updated successfully.');
            } catch (DmlException dmle) {
                System.debug('❌ Failed to update Cases: ' + dmle.getMessage());
                for (Integer i = 0; i < dmle.getNumDml(); i++) {
                    System.debug('Row ' + i + ' error: ' + dmle.getDmlMessage(i));
                }
                throw dmle;
            }
        } else {
            System.debug('No Case needed update (already linked or no match).');
        }

        System.debug('=== PullRequestCaseLinker.handleAfter END ===');
    }

    private static String normalize(String s) {
        return String.isBlank(s) ? '' : s.trim().toLowerCase();
    }
}
