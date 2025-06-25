@isTest
public class FileTest {

    @isTest
    static void testValidContentVersion() {
        ContentVersion cv = new ContentVersion(
            Title = 'Code Scanner - Valid',
            PathOnClient = 'valid.csv',
            VersionData = Blob.valueOf('test data'),
            IsMajorVersion = true
        );
        insert cv;

        // Fetch inserted CV with ContentDocumentId
        ContentVersion inserted = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        Test.startTest();
        File.processNewFiles(new List<ContentVersion>{ inserted });
        Test.stopTest();
    }

    @isTest
    static void testTitleIsNull() {
        ContentVersion cv = new ContentVersion(
            Title = null,
            PathOnClient = 'nullTitle.csv',
            VersionData = Blob.valueOf('data'),
            IsMajorVersion = true
        );
        insert cv;

        File.processNewFiles(new List<ContentVersion>{ cv });
    }

    @isTest
    static void testTitleMatchesButNoContentDocId() {
        // Simulate ContentVersion without ContentDocumentId
        ContentVersion cv = new ContentVersion(
            Title = 'Code Scanner - Missing DocId',
            PathOnClient = 'nodoc.csv',
            VersionData = Blob.valueOf('data'),
            IsMajorVersion = true
        );
        insert cv;

        // Query before ContentDocumentId is populated
        ContentVersion inserted = [
            SELECT Id, Title
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // Now call method (ContentDocumentId is null)
        File.processNewFiles(new List<ContentVersion>{ inserted });
    }

    @isTest
    static void testUnrelatedTitle() {
        ContentVersion cv = new ContentVersion(
            Title = 'Random File',
            PathOnClient = 'random.csv',
            VersionData = Blob.valueOf('data'),
            IsMajorVersion = true
        );
        insert cv;

        File.processNewFiles(new List<ContentVersion>{ cv });
    }
}
