@isTest
private class ScannerReportHandlerTest {

    @isTest
    static void testProcessFiles_withValidCSV() {
        String csvContent = 'Problem,Severity,TargetBranch\nViolation 1,High,main';

        ContentVersion version = new ContentVersion(
            Title = 'Code Scanner Report',
            PathOnClient = 'CodeScannerReport.csv',
            VersionData = Blob.valueOf(csvContent),
            IsMajorVersion = true
        );
        insert version;

        version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];

        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        List<Case> createdCases = [SELECT Id, File_Name__c, Target_Environment__c FROM Case];
        System.assertEquals(1, createdCases.size());
        System.assertEquals('main', createdCases[0].Target_Environment__c);

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink 
            WHERE LinkedEntityId = :createdCases[0].Id AND ContentDocumentId = :version.ContentDocumentId
        ];
        System.assertEquals(1, links.size());
    }

    @isTest
    static void testProcessFiles_withEmptySet() {
        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void testProcessFiles_withInvalidTitle() {
        ContentVersion version = new ContentVersion(
            Title = 'Random File',
            PathOnClient = 'Random.csv',
            VersionData = Blob.valueOf('Header1,Header2\nVal1,Val2'),
            IsMajorVersion = true
        );
        insert version;

        version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void testProcessFiles_withEmptyTargetBranch() {
        String csvContent = 'Problem,Severity,TargetBranch\nViolation,High,'; // Empty TargetBranch value

        ContentVersion version = new ContentVersion(
            Title = 'Code Scanner Delta',
            PathOnClient = 'delta.csv',
            VersionData = Blob.valueOf(csvContent),
            IsMajorVersion = true
        );
        insert version;

        version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        List<Case> createdCases = [SELECT Id, Target_Environment__c FROM Case];
        System.assertEquals(1, createdCases.size());
        System.assertEquals('', createdCases[0].Target_Environment__c); // Target_Environment will be blank
    }

    @isTest
    static void testProcessFiles_whenCSVParsingFails() {
        // This blob will cause an exception (simulate malformed content)
        ContentVersion version = new ContentVersion(
            Title = 'Code Scanner Report',
            PathOnClient = 'BadFile.csv',
            VersionData = Blob.valueOf(''),
            IsMajorVersion = true
        );
        insert version;

        version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        // It should still insert a Case even if CSV parsing fails
        System.assertEquals(1, [SELECT COUNT() FROM Case]);
    }

    @isTest
    static void testProcessFiles_duplicateContentDocumentLink() {
        // Valid CSV
        String csvContent = 'Problem,Severity,TargetBranch\nViolation,High,main';

        ContentVersion version = new ContentVersion(
            Title = 'Code Scanner Report',
            PathOnClient = 'Report.csv',
            VersionData = Blob.valueOf(csvContent),
            IsMajorVersion = true
        );
        insert version;

        version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        // Run once
        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        // Run again — should skip duplicate ContentDocumentLink creation
        Test.startTest();
        ScannerReportHandler.processFiles(new Set<Id>{ version.ContentDocumentId });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Case]);
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink]);
    }

    @isTest
    static void testProcessFiles_multipleContentVersions() {
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Integer i = 0; i < 2; i++) {
            versions.add(new ContentVersion(
                Title = 'Code Scanner Report ' + i,
                PathOnClient = 'file' + i + '.csv',
                VersionData = Blob.valueOf('Problem,Severity,TargetBranch\nV,Low,dev'),
                IsMajorVersion = true
            ));
        }
        insert versions;

        Set<Id> docIds = new Set<Id>();
        for (ContentVersion v : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versions]) {
            docIds.add(v.ContentDocumentId);
        }

        Test.startTest();
        ScannerReportHandler.processFiles(docIds);
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM Case]);
        System.assertEquals(2, [SELECT COUNT() FROM ContentDocumentLink]);
    }
}
