@isTest
private class CSVDataControllerTest {

    @isTest
    static void testValidCSVAttachment() {
        // Create a Case record
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // Create a valid CSV with different violation types
        String csvContent =
            'File,Problem\n' +
            'classes/Test.cls,Issue A\n' +
            'lwc/component.js,Issue B\n' +
            'aura/Comp.cmp,Issue C\n' +
            'objects/Obj__c,Issue D';

        // Create an Attachment with .csv name and link to Case
        Attachment attach = new Attachment(
            Name = 'ScanReport.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attach;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(4, result.csvData.size());
        System.assertEquals(1, result.clsViolationCount);
        System.assertEquals(1, result.lwcViolationCount);
        System.assertEquals(1, result.auraViolationCount);
        System.assertEquals(1, result.objectsViolationCount);
    }

    @isTest
    static void testNoAttachmentFound() {
        Case testCase = new Case(Status = 'New');
        insert testCase;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(0, result.csvData.size());
    }

    @isTest
    static void testEmptyCSVContent() {
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // Insert CSV file with empty body
        Attachment attach = new Attachment(
            Name = 'Empty.csv',
            Body = Blob.valueOf(''),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attach;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(0, result.csvData.size());
    }

    @isTest
    static void testMalformedCSVRow() {
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // One row is malformed (only one column)
        String csvContent =
            'File,Problem\n' +
            'classes/OnlyFilePath\n' +
            'lwc/Component.js,Missing Semicolon';

        Attachment attach = new Attachment(
            Name = 'BadRow.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attach;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(1, result.csvData.size()); // Only 1 row valid
        System.assertEquals(1, result.lwcViolationCount);
    }
}
