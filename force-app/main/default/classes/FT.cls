@isTest
private class FileTest {

    @isTest
    static void testProcessNewFiles_and_importVulnerabilityData() {
        // Step 1: Create a valid CSV content string
        String csvData =
            'problem,severity,file,templine,column,rule,description,url,category,engine,commit,actualline,targetbranch\n' +
            'Unused var,3,classes/MyClass.cls,10,5,PMDRule,Unused variable found,http://rule.url,Best Practices,PMD,abc123,10,main';

        // Step 2: Upload as ContentVersion
        ContentVersion version = new ContentVersion(
            Title = 'SecurityReport',
            PathOnClient = 'SecurityReport.csv',
            VersionData = Blob.valueOf(csvData),
            IsMajorVersion = true
        );
        insert version;

        // Step 3: Get ContentDocumentId after insert
        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        // Step 4: Add ContentVersion to list
        List<ContentVersion> versionList = new List<ContentVersion>{ version };

        // Step 5: Call method
        Test.startTest();
        File.processNewFiles(versionList);
        Test.stopTest();

        // Step 6: Assert Vulnerability__c record created
        List<Vulnerability__c> records = [SELECT Id, Problem__c, Severity__c FROM Vulnerability__c];
        System.assertEquals(1, records.size());
        System.assertEquals('Unused var', records[0].Problem__c);
        System.assertEquals('3', records[0].Severity__c);
    }

    @isTest
    static void test_importVulnerabilityData_emptyVersionData() {
        ContentVersion emptyVersion = new ContentVersion(
            Title = 'EmptyFile',
            PathOnClient = 'EmptyFile.csv',
            VersionData = null,
            IsMajorVersion = true
        );
        insert emptyVersion;

        emptyVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :emptyVersion.Id
        ];

        Test.startTest();
        File.importVulnerabilityData(new List<Id>{ emptyVersion.ContentDocumentId });
        Test.stopTest();

        // No records should be created
        List<Vulnerability__c> records = [SELECT Id FROM Vulnerability__c];
        System.assertEquals(0, records.size());
    }

    @isTest
    static void test_importVulnerabilityData_missingRequiredFields() {
        // Missing 'problem' column
        String csvData =
            'severity,file,templine,column,rule,description,url,category,engine,commit,actualline,targetbranch\n' +
            '3,classes/MyClass.cls,10,5,PMDRule,Unused variable found,http://rule.url,Best Practices,PMD,abc123,10,main';

        ContentVersion badVersion = new ContentVersion(
            Title = 'BadFile',
            PathOnClient = 'BadFile.csv',
            VersionData = Blob.valueOf(csvData),
            IsMajorVersion = true
        );
        insert badVersion;

        badVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :badVersion.Id
        ];

        Test.startTest();
        File.importVulnerabilityData(new List<Id>{ badVersion.ContentDocumentId });
        Test.stopTest();

        // Should skip processing due to missing 'problem' column
        List<Vulnerability__c> records = [SELECT Id FROM Vulnerability__c];
        System.assertEquals(0, records.size());
    }

    @isTest
    static void test_parseCSVLine_quotes_and_commas() {
        // A CSV line with quoted value containing a comma
        String line = '"High Severity","This is, a comma inside","TestFile.cls"';

        List<String> result = File.parseCSVLine(line);
        System.assertEquals(3, result.size());
        System.assertEquals('High Severity', result[0]);
        System.assertEquals('This is, a comma inside', result[1]);
        System.assertEquals('TestFile.cls', result[2]);
    }
}
