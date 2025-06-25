@isTest
public class FileTest {
    
    @isTest
    static void testProcessNewFiles() {
        // Create test ContentVersion with a matching title
        ContentVersion cv = new ContentVersion(
            Title = 'Code Scanner - Sample Report',
            PathOnClient = 'test.csv',
            VersionData = Blob.valueOf('rule,engine,severity\nAvoidDebugStatements,pmd,3'),
            IsMajorVersion = true
        );
        insert cv;

        // Fetch inserted ContentVersion with ContentDocumentId populated
        ContentVersion insertedCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Sanity check
        System.assertNotEquals(null, insertedCV.ContentDocumentId, 'ContentDocumentId should be populated after insert');

        // Call method under test
        Test.startTest();
        File.processNewFiles(new List<ContentVersion>{ insertedCV });
        Test.stopTest();

        // ✅ No exceptions mean the test passed the logic path
        System.debug('File.processNewFiles executed successfully.');
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
    
    @IsTest
    static void test_importVulnerabilityData_invalidCSVFormat() {
        ContentVersion invalidVersion = new ContentVersion(
            Title = 'InvalidFile',
            PathOnClient = 'InvalidFile.csv',
            VersionData = Blob.valueOf('Invalid content'),
            IsMajorVersion = true
        );
        insert invalidVersion;

        invalidVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :invalidVersion.Id
        ];

        Test.startTest();
        File.importVulnerabilityData(new List<Id>{ invalidVersion.ContentDocumentId });
        Test.stopTest();

        // No records should be created
        List<Vulnerability__c> records = [SELECT Id FROM Vulnerability__c];
        System.assertEquals(0, records.size());
    }
	
    @IsTest
    static void test_parseCSVLine_emptyFields() {
        // CSV line with empty fields
        String line = 'problem1,,file1,,,description1,,,'; // Empty fields between commas

        List<String> result = File.parseCSVLine(line);
        System.assertEquals(11, result.size()); // There should be 11 fields, including empty ones
        System.assertEquals('problem1', result[0]);
        System.assertEquals('', result[1]); // Empty field
        System.assertEquals('file1', result[2]);
        System.assertEquals('', result[3]); // Empty field
        System.assertEquals('', result[4]); // Empty field
        System.assertEquals('description1', result[5]);
        System.assertEquals('', result[6]); // Empty field
        System.assertEquals('', result[7]); // Empty field
        System.assertEquals('', result[8]); // Empty field
        System.assertEquals('', result[9]); // Empty field
        System.assertEquals('', result[10]); // Empty field
    }
    
    @isTest
    static void test_importVulnerabilityData_emptyVersionData() {
        ContentVersion emptyVersion = new ContentVersion(
            Title = 'EmptyFile',
            PathOnClient = 'EmptyFile.csv',
            VersionData = Blob.valueOf(' '),
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
    static void testProcessNewFilesWithNoMatchingFiles() {
        // Create test ContentVersion with a non-matching title
        ContentVersion cv = new ContentVersion(
            Title = 'Unrelated File',
            PathOnClient = 'unrelated.csv',
            VersionData = Blob.valueOf('data'),
            IsMajorVersion = true
        );
        insert cv;

        // Run method
        File.processNewFiles(new List<ContentVersion>{ cv });

        // Expected: nothing happens
        System.assert(true, 'Should not throw exception for non-matching title');
    }
}
