@isTest
private class CSVDataControllerTest {

    // ✅ Valid test with all violation types
    @isTest
    static void testGetCSVData_validAttachment() {
        Case testCase = new Case(Subject = 'Valid Case', Origin = 'Phone', Status = 'New');
        insert testCase;

        String csvContent =
            'File,Problem\n' +
            'classes/Test.cls,Unused variable\n' +
            'lwc/component.js,Missing semicolon\n' +
            'aura/MyComp.cmp,Deprecated tag\n' +
            'objects/MyObject__c,Missing label';

        Attachment attachment = new Attachment(
            Name = 'Code Scanner Report - Valid.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attachment;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(4, result.csvData.size(), 'Should parse 4 rows');
        System.assertEquals(1, result.clsViolationCount);
        System.assertEquals(1, result.lwcViolationCount);
        System.assertEquals(1, result.auraViolationCount);
        System.assertEquals(1, result.objectsViolationCount);
    }

    // 🟡 No matching CSV file
    @isTest
    static void testGetCSVData_noCSVFound() {
        Case testCase = new Case(Subject = 'No Attachment Case', Origin = 'Email', Status = 'New');
        insert testCase;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(0, result.csvData.size());
    }

    // ⚠️ Attachment with empty content
    @isTest
    static void testGetCSVData_emptyCSVFile() {
        Case testCase = new Case(Subject = 'Empty File Case', Origin = 'Web', Status = 'New');
        insert testCase;

        Attachment emptyAttachment = new Attachment(
            Name = 'Code Scanner Report - Empty.csv',
            Body = Blob.valueOf(''),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert emptyAttachment;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(0, result.csvData.size(), 'Should return 0 for empty CSV file');
    }

    // 🔍 One malformed row (column count mismatch)
    @isTest
    static void testGetCSVData_malformedRow() {
        Case testCase = new Case(Subject = 'Malformed Row Case', Origin = 'Chat', Status = 'New');
        insert testCase;

        String csvContent =
            'File,Problem\n' +
            'classes/Test.cls\n' +  // malformed row
            'lwc/component.js,Missing semicolon';

        Attachment attachment = new Attachment(
            Name = 'Code Scanner Report - Malformed.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert attachment;

        Test.startTest();
        CSVDataController.CSVDataResponse result = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        System.assertEquals(1, result.csvData.size(), 'Should parse only valid rows');
        System.assertEquals(1, result.lwcViolationCount);
    }
}
