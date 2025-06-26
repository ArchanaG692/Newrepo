trigger ScannerReportTrigger on ContentDocumentLink (after insert) {

    Set<Id> documentIds = new Set<Id>();



    for (ContentDocumentLink cdl : Trigger.new) {

        // Fetch the related ContentDocument

        ContentDocument doc = [SELECT Id, Title FROM ContentDocument WHERE Id = :cdl.ContentDocumentId LIMIT 1];

        // Check if the file name contains "Code Scanner Delta Report"
        if (doc.Title.contains('Code Scanner Delta Report')) {
            documentIds.add(cdl.ContentDocumentId);
        }
    }
    if (!documentIds.isEmpty()) {
        ScannerReportHandler.processFiles(documentIds);
    }
}
