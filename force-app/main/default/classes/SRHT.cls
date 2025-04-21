@isTest
private class ScannerReportHandlerTest {
    @testSetup
    static void setupTestData() {
        // Create a test ContentVersion with CSV data
        String csvData = 'Problem,Severity,File,Line,Rule,Description\n' +
                         'Unused Variable,High,TestClass.cls,10,AvoidUnusedVariables,Variable is declared but never used\n' +
                         'Hardcoded Id,Medium,TestClass.cls,20,AvoidHardcodingIds,Hardcoded Salesforce ID detected';
        
        ContentVersion testVersion = new ContentVersion(
            Title = 'Test Scanner Report.csv',
            VersionData = Blob.valueOf(csvData),
            PathOnClient = 'Test Scanner Report.csv',
            IsMajorVersion = true
        );
        insert testVersion;
    }

    @isTest
    static void testProcessFiles() {
        Test.startTest();

        // Fetch the inserted ContentVersion and get the associated ContentDocumentId
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];

        // Call the method with the test ContentDocument ID
        Set<Id> documentIds = new Set<Id>{insertedVersion.ContentDocumentId};
        ScannerReportHandler.processFiles(documentIds);

        Test.stopTest();

        // Validate that Cases are created
        List<Case> createdCases = [SELECT Subject, Description, Priority, Status, Origin, Scanner_Report_File_ID__c FROM Case];

        System.assertEquals(2, createdCases.size(), 'Two cases should be created');

        // Verify case details
        System.assertEquals('Scanner Report Violation: Unused Variable', createdCases[0].Subject);
        System.assertEquals('High', createdCases[0].Priority);
        System.assertEquals('New', createdCases[0].Status);
        System.assertEquals(insertedVersion.ContentDocumentId, createdCases[0].Scanner_Report_File_ID__c);
    }
}
