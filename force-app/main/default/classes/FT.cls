@isTest
public with sharing class FileTest {
    
    @testSetup
    static void setupTestData() {
        ContentVersion contentVer = new ContentVersion(
            Title = 'Code Scanner Report',
            PathOnClient = 'scanner_report.csv',
            VersionData = Blob.valueOf('Problem,Severity,File,Line,Column,Rule,Description,URL,Category,Engine,Commit\n' + 
                                       'SQL Injection,High,Account.cls,12,5,SOQL Injection,Avoid Dynamic SOQL,www.example.com,Security,PMD,abc123'),
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert contentVer;
    }

    @isTest
    static void testProcessNewFiles() {
        List<ContentVersion> newFiles = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title LIKE 'Code Scanner%'];
        
        System.assertNotEquals(0, newFiles.size(), 'ContentVersion records should exist');

        Test.startTest();
        File.processNewFiles(newFiles);
        Test.stopTest();

        Integer vulnCount = [SELECT COUNT() FROM Vulnerability__c];
        System.assertEquals(1, vulnCount, 'One unique Vulnerability record should have been created');
    }

    @isTest
    static void testImportVulnerabilityData() {
        ContentVersion fileVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Code Scanner Report' LIMIT 1];

        System.assertNotEquals(null, fileVersion.ContentDocumentId, 'ContentDocumentId should not be null');

        Test.startTest();
        File.importVulnerabilityData(fileVersion.ContentDocumentId);
        Test.stopTest();

        Integer vulnCount = [SELECT COUNT() FROM Vulnerability__c];
        System.assertEquals(1, vulnCount, 'One unique Vulnerability record should have been created');
    }

    @isTest
    static void testImportVulnerabilityDataWithEmptyFile() {
        ContentVersion emptyFile = new ContentVersion(
            Title = 'Code Scanner Empty Report',
            PathOnClient = 'empty_report.csv',
            VersionData = Blob.valueOf(' '), // Ensuring VersionData is not null
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert emptyFile;

        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :emptyFile.Id LIMIT 1];

        Test.startTest();
        File.importVulnerabilityData(insertedFile.ContentDocumentId);
        Test.stopTest();

        Integer vulnCount = [SELECT COUNT() FROM Vulnerability__c];
        System.assertEquals(0, vulnCount, 'No Vulnerability records should be created for empty file');
    }

    @isTest
    static void testImportVulnerabilityDataWithMissingHeaders() {
        ContentVersion invalidFile = new ContentVersion(
            Title = 'Code Scanner Invalid Report',
            PathOnClient = 'invalid_report.csv',
            VersionData = Blob.valueOf('Problem,Severity,File\nSQL Injection,High,Account.cls'), // Ensuring VersionData is present
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert invalidFile;

        ContentVersion insertedFile = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :invalidFile.Id LIMIT 1];

        Test.startTest();
        File.importVulnerabilityData(insertedFile.ContentDocumentId);
        Test.stopTest();

        Integer vulnCount = [SELECT COUNT() FROM Vulnerability__c];
        System.assertEquals(0, vulnCount, 'No Vulnerability records should be created due to missing headers');
    }
}
