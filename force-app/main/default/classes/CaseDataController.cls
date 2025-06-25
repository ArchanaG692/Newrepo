public with sharing class CaseDataController {
    public class CSVDataResponse {
        @AuraEnabled public List<Map<String, String>> csvData = new List<Map<String, String>>();
        @AuraEnabled public Integer clsViolationCount = 0;
        @AuraEnabled public Integer lwcViolationCount = 0;
        @AuraEnabled public Integer auraViolationCount = 0;
        @AuraEnabled public Integer objectsViolationCount = 0;
    }

    @AuraEnabled(cacheable=true)
    public static CSVDataResponse getCSVData(String caseId) {
        CSVDataResponse response = new CSVDataResponse();

        try {
            // Step 1: Get latest ContentDocumentId from Case's Files Related List
            List<ContentDocumentLink> contentLinks = [
                SELECT
