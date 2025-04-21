@isTest
private class CSVDataControllerTest {

    @isTest
    static void testGetCSVData_validCSVFile() {
        // Create a Case
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // Create CSV content with all violation types
        String csvContent =
            'File,Problem\n' +
            'classes/MyClass.cls,Issue A\n' +
            'lwc/component.js,Issue B\n' +
            'aura/Comp.cmp,Issue C\n' +
            'objects/MyObj__c,Issue D';

        // Create Attachment (CSV)
        Attachment attachment = new Attachment(
            Name = 'CodeScanReport.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attachment;

        // Run method
        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        // Validate result
        System.assertEquals(4, result.csvData.size(), 'Should return 4 CSV rows');
        System.assertEquals(1, result.clsViolationCount);
        System.assertEquals(1, result.lwcViolationCount);
        System.assertEquals(1, result.auraViolationCount);
        System.assertEquals(1, result.objectsViolationCount);
    }

    @isTest
    static void testGetCSVData_noAttachmentFound() {
        // Create Case without any attachments
        Case testCase = new Case(Status = 'New');
        insert testCase;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        // Expect default empty response
        System.assertEquals(0, result.csvData.size());
        System.assertEquals(0, result.clsViolationCount);
    }

    @isTest
    static void testGetCSVData_emptyCSVFile() {
        // Create Case
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // Add attachment with empty content
        Attachment attachment = new Attachment(
            Name = 'EmptyFile.csv',
            Body = Blob.valueOf(''),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attachment;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(0, result.csvData.size(), 'Should return 0 rows for empty file');
    }

    @isTest
    static void testGetCSVData_malformedCSVRows() {
        // Create Case
        Case testCase = new Case(Status = 'New');
        insert testCase;

        // CSV where one row has missing column
        String csvContent =
            'File,Problem\n' +
            'classes/IncompleteRow.cls\n' + // only 1 column instead of 2
            'lwc/ValidRow.js,Issue B';

        Attachment attachment = new Attachment(
            Name = 'MalformedCSV.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attachment;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(1, result.csvData.size(), 'Only one valid row should be processed');
        System.assertEquals(1, result.lwcViolationCount, 'Should count LWC file');
    }
}
