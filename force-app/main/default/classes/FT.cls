@isTest
public class FileTest {
    
    @isTest
    static void testProcessNewFiles() {
        // Generate CSV header matching V5 fieldMappings (13 columns)
        String header = 'rule,engine,severity,tags,file,startline,startcolumn,message,resources,commit,actualline,targetbranch,extra';
        String row = 'AvoidDebugStatements,pmd,3,Performance,src/MyClass.cls,10,5,"Avoid debug",https://example.com/debug,abc123,10,main,';
        
        ContentVersion cv = new ContentVersion(
            Title = 'Code Scanner - Sample Report',
            PathOnClient = 'test.csv',
            VersionData = Blob.valueOf(header + '\n' + row),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, insertedCV.ContentDocumentId);

        Test.startTest();
        File.processNewFiles(new List<ContentVersion>{insertedCV});
        Test.stopTest();

        List<Vulnerability__c> vl = [SELECT Rule__c, Engine__c, Severity__c, Category__c,
                                            File__c, Line__c, Column__c, Description__c,
                                            URL__c, Commit__c, ActualLine__c, TargetBranch__c
                                     FROM Vulnerability__c];
        System.assertEquals(1, vl.size());
        Vulnerability__c v = vl[0];
        System.assertEquals('AvoidDebugStatements', v.Rule__c);
        System.assertEquals('pmd', v.Engine__c);
        System.assertEquals('3', v.Severity__c);
        System.assertEquals('Performance', v.Category__c);
        System.assertEquals('src/MyClass.cls', v.File__c);
        System.assertEquals('10', v.Line__c);
        System.assertEquals('5', v.Column__c);
        System.assertEquals('Avoid debug', v.Description__c);
        System.assertEquals('https://example.com/debug', v.URL__c);
        System.assertEquals('abc123', v.Commit__c);
        System.assertEquals('10', v.ActualLine__c);
        System.assertEquals('main', v.TargetBranch__c);
    }

    @isTest
    static void test_missingRequiredHeaders_skipsInsert() {
        // Drop 'rules' to simulate missing mandatory column → skip
        String header = 'severity,engine,tags,file,startline,startcolumn,message,resources,commit,actualline,targetbranch';
        String row =    '3,pmd,Performance,src/MyClass.cls,10,5,"msg",http://example.com,abc123,10,main';
        
        ContentVersion bad = new ContentVersion(
            Title = 'BadReport',
            PathOnClient = 'bad.csv',
            VersionData = Blob.valueOf(header + '\n' + row),
            IsMajorVersion = true
        );
        insert bad;
        
        bad = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :bad.Id];
        
        Test.startTest();
        File.importVulnerabilityData(new List<Id>{bad.ContentDocumentId});
        Test.stopTest();
        
        System.assertEquals(0, [SELECT Count() FROM Vulnerability__c]);
    }
    
    @isTest
    static void test_parseCSVLine_quotesAndEmpty() {
        String line = '"Abc, Def",,,ghi,"Jkl, Mno"';
        List<String> r = File.parseCSVLine(line);
        System.assertEquals(6, r.size());
        System.assertEquals('Abc, Def', r[0]);
        System.assertEquals('', r[1]);
        System.assertEquals('', r[2]);
        System.assertEquals('ghi', r[3]);
        System.assertEquals('Jkl, Mno', r[4]);
        System.assertEquals('', r[5]);
    }

    @isTest
    static void test_invalidCSV_doesNothing() {
        ContentVersion iv = new ContentVersion(
            Title = 'Invalid',
            PathOnClient = 'invalid.csv',
            VersionData = Blob.valueOf('Not,a,CSV'),
            IsMajorVersion = true
        );
        insert iv;
        iv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :iv.Id];

        Test.startTest();
        File.importVulnerabilityData(new List<Id>{iv.ContentDocumentId});
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Vulnerability__c]);
    }

    @isTest
    static void test_emptyContent_skipsInsert() {
        ContentVersion ev = new ContentVersion(
            Title = 'Empty',
            PathOnClient = 'empty.csv',
            VersionData = Blob.valueOf(' '),
            IsMajor
