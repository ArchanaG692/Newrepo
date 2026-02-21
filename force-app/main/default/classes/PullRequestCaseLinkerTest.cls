@IsTest
private class PullRequestCaseLinkerTest {

    // ---------- Helpers ----------
    private static Pull_Request__c makePR(String codeFile, String lwcFile) {
        Pull_Request__c pr = new Pull_Request__c();
        pr.Check1_Report_File__c = codeFile;
        pr.Check1_LWC_Report_File__c = lwcFile;
        return pr;
    }

    // Backward helper (your old tests can still call this pattern)
    private static Pull_Request__c makePR(String fileName) {
        Pull_Request__c pr = new Pull_Request__c();
        pr.Check1_Report_File__c = fileName;
        return pr;
    }

    private static Case makeCase(String fileName, Id prId) {
        Case c = new Case();
        c.Status  = 'New';
        c.Origin  = 'Phone';
        c.Subject = 'PR Linking Test';
        c.File_Name__c = fileName;
        c.Pull_Request__c = prId; // null or PR Id
        return c;
    }

    @IsTest
    static void test_safeExit_nullList() {
        Test.startTest();
        PullRequestCaseLinker.handleAfter(null, null, true, false);
        Test.stopTest();
        System.assert(true, 'Should safely exit for null list.');
    }

    @IsTest
    static void test_safeExit_emptyList() {
        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>(), null, true, false);
        Test.stopTest();
        System.assert(true, 'Should safely exit for empty list.');
    }

    @IsTest
    static void test_blankFileName_skipsPR_noCaseUpdate() {
        Case c = makeCase('Report.csv', null);
        insert c;

        // both fields blank/spaces
        Pull_Request__c pr = makePR('   ', '   ');
        insert pr;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        Case after = [SELECT Id, Pull_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, after.Pull_Request__c, 'Case should remain unlinked when PR file is blank.');
    }

    @IsTest
    static void test_noMatchingCase_noUpdates() {
        Case c = makeCase('A.csv', null);
        insert c;

        Pull_Request__c pr = makePR('B.csv', 'LWC_B.csv');
        insert pr;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        Case after = [SELECT Id, Pull_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, after.Pull_Request__c, 'No match: Case should remain unlinked.');
    }

    @IsTest
    static void test_linksAllMatchingCases_oneOrMore_code() {
        // Two cases with same CODE file name -> both must link to PR
        Case c1 = makeCase('Report.csv', null);
        Case c2 = makeCase('Report.csv', null);
        insert new List<Case>{ c1, c2 };

        Pull_Request__c pr = makePR('Report.csv', null);
        insert pr;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        List<Case> afterCases = [
            SELECT Id, Pull_Request__c
            FROM Case
            WHERE Id IN :new List<Id>{ c1.Id, c2.Id }
        ];

        for (Case c : afterCases) {
            System.assertEquals(pr.Id, c.Pull_Request__c, 'All matching Cases must be linked to PR.');
        }
    }

    @IsTest
    static void test_linksMatchingCases_lwc() {
        // Case has LWC file, PR has only LWC file -> must link
        String lwcFile = 'LWC_Code Scanner Report_XYZ 123 into 456.csv';

        Case c = makeCase(lwcFile, null);
        insert c;

        Pull_Request__c pr = makePR(null, lwcFile);
        insert pr;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        Case after = [SELECT Id, Pull_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(pr.Id, after.Pull_Request__c, 'LWC file Case should be linked to PR via Check1_LWC_Report_File__c.');
    }

    @IsTest
    static void test_linksBothCaseTypes_samePR() {
        // One CODE case + one LWC case should link to same PR when PR has both filenames
        String codeFile = 'Code Scanner Report_ABC 111 into 222.csv';
        String lwcFile  = 'LWC_Code Scanner Report_ABC 333 into 444.csv';

        Case c1 = makeCase(codeFile, null);
        Case c2 = makeCase(lwcFile, null);
        insert new List<Case>{ c1, c2 };

        Pull_Request__c pr = makePR(codeFile, lwcFile);
        insert pr;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        List<Case> afterCases = [
            SELECT Id, File_Name__c, Pull_Request__c
            FROM Case
            WHERE Id IN :new List<Id>{ c1.Id, c2.Id }
        ];

        for (Case c : afterCases) {
            System.assertEquals(pr.Id, c.Pull_Request__c, 'Both CODE and LWC Cases should link to same PR.');
        }
    }

    @IsTest
    static void test_caseInsensitiveAndTrim_matchingStillWorks() {
        Pull_Request__c pr = makePR('   REPORT.CSV   ', '   LWC_REPORT.CSV   ');
        insert pr;

        // Case files must match trimmed originals
        Case c1 = makeCase('REPORT.CSV', null);
        Case c2 = makeCase('LWC_REPORT.CSV', null);
        insert new List<Case>{ c1, c2 };

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        List<Case> afterCases = [
            SELECT Id, File_Name__c, Pull_Request__c
            FROM Case
            WHERE Id IN :new List<Id>{ c1.Id, c2.Id }
        ];

        for (Case c : afterCases) {
            System.assertEquals(pr.Id, c.Pull_Request__c, 'Trim/case variations should still link.');
        }
    }

    @IsTest
    static void test_alreadyLinked_noDmlNeeded_noChange() {
        Pull_Request__c pr = makePR('Same.csv', 'SameLwc.csv');
        insert pr;

        Case c = makeCase('Same.csv', pr.Id); // already linked
        insert c;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, null, true, false);
        Test.stopTest();

        Case after = [SELECT Id, Pull_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(pr.Id, after.Pull_Request__c, 'Already linked Case should remain linked.');
    }

    @IsTest
    static void test_multiplePRs_firstWinsWhenSameFile() {
        Pull_Request__c pr1 = makePR('Dup.csv', 'LwcDup.csv');
        Pull_Request__c pr2 = makePR('Dup.csv', 'LwcDup.csv');
        insert new List<Pull_Request__c>{ pr1, pr2 };

        Case c = makeCase('Dup.csv', null);
        insert c;

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr1, pr2 }, null, true, false);
        Test.stopTest();

        Case after = [SELECT Id, Pull_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(pr1.Id, after.Pull_Request__c, 'When duplicate file names exist, first PR should win.');
    }

    @IsTest
    static void test_updatePath_flagsDontMatter_logicStillLinks() {
        Case c = makeCase('U.csv', null);
        insert c;

        Pull_Request__c pr = makePR('U.csv', null);
        insert pr;

        Map<Id, Pull_Request__c> oldMap = new Map<Id, Pull_Request__c>{
            pr.Id => new Pull_Request__c(Id = pr.Id, Check1_Report_File__c = 'Old.csv', Check1_LWC_Report_File__c = 'OldLwc.csv')
        };

        Test.startTest();
        PullRequestCaseLinker.handleAfter(new List<Pull_Request__c>{ pr }, oldMap, false, true);
        Test.stopTest();

        Case after = [SELECT Id, Pull_Request__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(pr.Id, after.Pull_Request__c, 'Update path should link matching Case as well.');
    }
}
