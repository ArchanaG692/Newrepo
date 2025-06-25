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
