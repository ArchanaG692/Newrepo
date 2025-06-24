public with sharing class FileController {
    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getAllFiles() {
        return [SELECT Id, Title FROM ContentDocument ORDER BY Title ASC];
    }

    @AuraEnabled
    public static String getFileContent(String fileId) {
        try {
            List<ContentVersion> fileVersions = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId = :fileId 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            
            if (fileVersions.isEmpty()) {
                return 'NO_CONTENT'; // handle no result
            }
    
            return EncodingUtil.base64Encode(fileVersions[0].VersionData);
        } catch (Exception e) {
            return 'ERROR';
        }
    }
}
