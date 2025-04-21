@isTest
private class CSVDataControllerTest {

    @isTest
    static void testGetCSVData_withValidCSV() {
        // Step 1: Create a dummy Case to associate the attachment
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;

        // Step 2: Prepare a sample CSV file content with violation types
        String csvContent = 'File,Problem,Severity\n'
                          + 'classes/Talent.cls,Unused variable,3\n'
                          + 'lwc/someComponent.js,Missing semicolon,2\n'
                          + 'aura/MyComponent.cmp,Deprecated tag,1\n'
                          + 'objects/MyObject__c.object,Field label missing,2';

        // Step 3: Create an Attachment and insert it
        Attachment testAttachment = new Attachment(
            Name = 'testReport.csv',
            Body = Blob.valueOf(csvContent),
            ContentType = 'text/csv',
            ParentId = testCase.Id
        );
        insert testAttachment;

        // Step 4: Call the method
        Test.startTest();
        CSVDataController.CSVDataResponse response = CSVDataController.getCSVData(testCase.Id);
        Test.stopTest();

        // Step 5: Assertions
        System.assertEquals(4, response.csvData.size(), 'Expected 4 rows of CSV data');
        System.assertEquals(1, response.clsViolationCount, '1 class violation expected');
        System.assertEquals(1, response.lwcViolationCount, '1 LWC violation expected');
        System.assertEquals(1, response.auraViolationCount, '1 Aura violation expected');
        System.assertEquals(1, response.objectsViolationCount, '1 Objects violation expected');
    }

    @isTest
    static void testGetCSVData_noAttachment() {
        // Case with no attachment
        Case emptyCase = new Case(Subject = 'Empty Case');
        insert emptyCase;

        Test.startTest();
        CSVDataController.CSVDataResponse response = CSVDataController.getCSVData(emptyCase.Id);
        Test.stopTest();

        System.assertEquals(0, response.csvData.size(), 'No data should be returned');
        System.assertEquals(0, response.clsViolationCount);
        System.assertEquals(0, response.lwcViolationCount);
        System.assertEquals(0, response.auraViolationCount);
        System.assertEquals(0, response.objectsViolationCount);
    }

    @isTest
    static void testGetCSVData_withInvalidCSVFormat() {
        // Case with malformed CSV
        Case malformedCase = new Case(Subject = 'Malformed CSV Case');
        insert malformedCase;

        String badCSV = 'JustOneHeader\n'
                      + 'OnlyOneColumn\n';

        Attachment badAttachment = new Attachment(
            Name = 'badFormat.csv',
            Body = Blob.valueOf(badCSV),
            ContentType = 'text/csv',
            ParentId = malformedCase.Id
        );
        insert badAttachment;

        Test.startTest();
        CSVDataController.CSVDataResponse response = CSVDataController.getCSVData(malformedCase.Id);
        Test.stopTest();

        System.assertEquals(0, response.clsViolationCount);
        System.assertEquals(1, response.csvData.size(), 'One row should be returned');
    }
}
