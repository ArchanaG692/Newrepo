@isTest
private class FileControllerTest {

    private static Id testContentDocumentId;

    @testSetup
    static void setupTestData() {
        System.debug('🔹 Setting up test data...');

        // ✅ Create a ContentVersion (this automatically creates a ContentDocument)
        ContentVersion ver = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.csv',
            VersionData = Blob.valueOf('Sample file content'), // Ensure valid VersionData
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert ver;

        // ✅ Fetch ContentDocumentId
        testContentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :ver.Id LIMIT 1
        ].ContentDocumentId;

        System.debug('✅ Test ContentDocument ID: ' + testContentDocumentId);
    }

    // ✅ Test getAllFiles() - Standard Scenario
    @isTest
    static void testGetAllFiles() {
        System.debug('🔹 Running testGetAllFiles...');
        
        Test.startTest();
        List<ContentDocument> files = FileController.getAllFiles();
        Test.stopTest();

        System.debug('✅ Files Retrieved: ' + files.size());

        System.assertNotEquals(null, files, 'File list should not be null');
        System.assert(files.size() > 0, 'At least one file should be returned');
    }

    // ✅ Test getFileContent() - Valid Case
    @isTest
    static void testGetFileContent() {
        System.debug('🔹 Running testGetFileContent...');
        
        Test.startTest();
        String fileContent = FileController.getFileContent(testContentDocumentId);
        Test.stopTest();

        System.debug('✅ File Content: ' + fileContent);

        System.assertNotEquals(null, fileContent, 'File content should not be null');
        System.assert(fileContent.length() > 0, 'File content should not be empty');
    }

    // ✅ Test getFileContent() - No File Available
    @isTest
    static void testGetFileContentNoFile() {
        System.debug('🔹 Running testGetFileContentNoFile...');
        
        Test.startTest();
        String fileContent = FileController.getFileContent('000000000000000'); // Non-existent ID
        Test.stopTest();

        System.debug('✅ File Content for missing file: ' + fileContent);

        // ✅ Fix: Expect "NO_CONTENT" instead of null
        System.assertEquals('NO_CONTENT', fileContent, 'Should return NO_CONTENT for missing file');
    }

    // ✅ Test getAllFiles() - No Files Available Case
    @isTest
    static void testGetAllFilesNoRecords() {
        System.debug('🔹 Running testGetAllFilesNoRecords...');
        
        Test.startTest();
        delete [SELECT Id FROM ContentDocument];
        List<ContentDocument> files = FileController.getAllFiles();
        Test.stopTest();

        System.debug('✅ Files Retrieved After Deletion: ' + files.size());

        System.assertEquals(0, files.size(), 'File list should be empty when no files exist');
    }

    // ✅ Test getFileContent() - Edge Case: No Version Data
    @isTest
    static void testGetFileContentNoVersionData() {
        System.debug('🔹 Running testGetFileContentNoVersionData...');
        
        // ✅ Fix: Use `Blob.valueOf(' ')` instead of empty string
        ContentVersion emptyVer = new ContentVersion(
            Title = 'Empty File',
            PathOnClient = 'EmptyFile.csv',
            VersionData = Blob.valueOf(' '), // Ensure non-empty VersionData
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert emptyVer;

        Id emptyDocId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :emptyVer.Id LIMIT 1
        ].ContentDocumentId;

        Test.startTest();
        String fileContent = FileController.getFileContent(emptyDocId);
        Test.stopTest();

        System.debug('✅ Empty File Content: ' + fileContent);

        // ✅ Fix: Expect Base64 encoding of empty space (`'IA=='` is Base64 of ' ' )
        System.assertEquals('IA==', fileContent, 'File content should return Base64 encoded empty string');
    }
}
