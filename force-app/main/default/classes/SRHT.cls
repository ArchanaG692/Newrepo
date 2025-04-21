@isTest
private class ScannerReportHandlerTest {

    @isTest
    static void testProcessFiles_withValidCSV() {
        // Step 1: Create mock CSV content with a TargetBranch column
        String csvContent =
            'Problem,Severity,TargetBranch\n' +
            'Violation 1,High,main';

        // Step 2: Insert ContentVersion with "Code Scanner" in the title
        ContentVersion version = new ContentVersion(
            Title = 'Code Scanner Report',
            PathOnClient = 'CodeScannerReport.csv',
            VersionData = Blob.valueOf(csvContent),
            IsMajorVersion = true
        );
        insert version;

        // Step 3: Retrieve ContentDocumentId after insert
        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
            LIMIT 1
        ];

        // Step 4: Wrap in future context using Test.startTest/stopTest
        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        // Step 5: Validate Case created with proper values
        List<Case> createdCases = [
            SELECT Id, File_Name__c, Target_Environment__c
            FROM Case
            WHERE File_Name__c = 'Code Scanner Report'
        ];

        System.assertEquals(1, createdCases.size(), 'Expected 1 Case record');
        System.assertEquals('main', createdCases[0].Target_Environment__c, 'Target_Environment__c should be mapped');

        // Step 6: Validate ContentDocumentLink created
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :createdCases[0].Id
            AND ContentDocumentId = :version.ContentDocumentId
        ];

        System.assertEquals(1, links.size(), 'File should be linked to Case via ContentDocumentLink');
    }

    @isTest
    static void testProcessFiles_withEmptySet() {
        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>());
        Test.stopTest();

        // No records should be created
        System.assertEquals(0, [SELECT COUNT() FROM Case], 'No Case should be created for empty input');
    }

    @isTest
    static void testProcessFiles_withInvalidTitle() {
        // CSV Title does NOT contain "Code Scanner" or "Code Scanner Delta"
        ContentVersion version = new ContentVersion(
            Title = 'SomeOtherReport',
            PathOnClient = 'OtherReport.csv',
            VersionData = Blob.valueOf('Header1,Header2\nVal1,Val2'),
            IsMajorVersion = true
        );
        insert version;

        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case], 'No case should be created for irrelevant file title');
    }
}
