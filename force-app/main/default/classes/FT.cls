@isTest
public class FileTest {

    @isTest
    static void testProcessNewFiles_andImportVulnerabilityData() {
        // Step 1: Prepare mock V5 CSV content
        String csvContent =
            'rule,engine,severity,tags,file,startLine,startColumn,endLine,endColumn,message,resources,commit,actualline,targetbranch\n' +
            'AvoidDebug,pmd,3,Performance,temp_scanner_files_temp_force-app_main_default_classes_MyClass.cls,4,9,4,49,"Avoid debug","https://docs.pmd-code.org","TestUser","4","feature/scan"';

        // Step 2: Create a mock ContentVersion record
        ContentVersion cv = new ContentVersion(
            Title = 'Code Scanner Report - Test',
            PathOnClient = 'TestReport.csv',
            VersionData = Blob.valueOf(csvContent),
            IsMajorVersion = true
        );
        insert cv;

        // Fetch ContentDocumentId via SOQL (auto-generated after insert)
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Step 3: Call the method under test
        Test.startTest();
        List<ContentVersion> inputList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        File.processNewFiles(inputList);
        Test.stopTest();

        // Step 4: Validate that Vulnerability__c record was created
        List<Vulnerability__c> vulns = [SELECT Rule__c, File__c, Line__c, Column__c, Severity__c, TargetBranch__c FROM Vulnerability__c];

        System.assertEquals(1, vulns.size(), 'A vulnerability record should be inserted.');
        System.assertEquals('AvoidDebug', vulns[0].Rule__c);
        System.assertEquals('3', vulns[0].Severity__c);
        System.assertEquals('temp_scanner_files_temp_force-app_main_default_classes_MyClass.cls', vulns[0].File__c);
        System.assertEquals('4', vulns[0].Line__c);
        System.assertEquals('9', vulns[0].Column__c);
        System.assertEquals('feature/scan', vulns[0].TargetBranch__c);
    }
}
