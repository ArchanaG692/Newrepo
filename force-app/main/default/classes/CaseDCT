@isTest
private class CaseDataControllerTest {

    @isTest
    static void testGetCSVData_validCSVFile() {
        // Step 1: Insert a dummy Case record
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // Step 2: Create valid CSV content
        String csvData =
            'File,Problem,Severity\n' +
            'classes/MyClass.cls,Issue 1,3\n' +
            'lwc/component.js,Issue 2,2\n' +
            'aura/Comp.cmp,Issue 3,1\n' +
            'objects/CustomObj__c,Issue 4,2\n';

        // Step 3: Upload ContentVersion with CSV data
        ContentVersion version = new ContentVersion(
            Title = 'ViolationReport.csv',
            PathOnClient = 'ViolationReport.csv',
            VersionData = Blob.valueOf(csvData),
            IsMajorVersion = true
        );
        insert version;

        // Step 4: Retrieve ContentDocumentId
        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        // Step 5: Link to Case via ContentDocumentLink
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = version.ContentDocumentId,
            LinkedEntityId = testCase.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        // Step 6: Call getCSVData
        Test.startTest();
        CaseDataController.CSVDataResponse result = CaseDataController.getCSVData(testCase.Id);
        Test.stopTest();

        // Step 7: Assertions
        System.assertEquals(4, result.csvData.size(), 'Expected 4 rows parsed');
        System.assertEquals(1, result.clsViolationCount);
        System.assertEquals(1, result.lwcViolationCount);
        System.assertEquals(1, result.auraViolationCount);
        System.assertEquals(1, result.objectsViolationCount);
    }

    @isTest
    static void testGetCSVData_noFileAttached() {
        // Case without any attached file
        Case emptyCase = new Case(Status = 'New');
        insert emptyCase;

        Test.startTest();
        CaseDataController.CSVDataResponse result = CaseDataController.getCSVData(emptyCase.Id);
        Test.stopTest();

        // Expected: empty response
        System.assertEquals(0, result.csvData.size());
        System.assertEquals(0, result.clsViolationCount);
    }

    @isTest
    static void testGetCSVData_nonCSVFileName() {
        // Case with a file that is not a .csv file
        Case testCase = new Case(Status = 'New');
        insert testCase;

        String fileData = 'Header1,Header2\nVal1,Val2';

        ContentVersion version = new ContentVersion(
            Title = 'NonCSVFile.txt',
            PathOnClient = 'NonCSVFile.txt',
            VersionData = Blob.valueOf(fileData),
            IsMajorVersion = true
        );
        insert version;

        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = version.ContentDocumentId,
            LinkedEntityId = testCase.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        Test.startTest();
        CaseDataController.CSVDataResponse result = CaseDataController.getCSVData(testCase.Id);
        Test.stopTest();

        // Because the Title doesn't end with .csv, query will return no result
        System.assertEquals(0, result.csvData.size(), 'Should return empty because no matching CSV file found');
    }

    @isTest
    static void testGetCSVData_emptyCSVFile() {
        // Case with empty CSV content
        Case testCase = new Case(Status = 'New');
        insert testCase;

        String emptyCSV = ''; // No content

        ContentVersion version = new ContentVersion(
            Title = 'EmptyCSV.csv',
            PathOnClient = 'EmptyCSV.csv',
            VersionData = Blob.valueOf(emptyCSV),
            IsMajorVersion = true
        );
        insert version;

        version = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = version.ContentDocumentId,
            LinkedEntityId = testCase.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        Test.startTest();
        CaseDataController.CSVDataResponse result = CaseDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(0, result.csvData.size(), 'Should return empty for empty CSV content');
    }
}
