public with sharing class ClearFilesController {
    
    /**
     * Получение списка файлов Clear Files для лида
     */
    @AuraEnabled(cacheable=true)
    public static List<ClearFileWrapper> getClearFiles(String leadId) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('LeadId is required');
        }
        
        try {
            // Получаем записи Clear_files__c для лида
            List<Clear_files__c> clearFiles = [
                SELECT Id, Name, Lead__c, File_Id__c, CreatedDate
                FROM Clear_files__c 
                WHERE Lead__c = :leadId 
                ORDER BY CreatedDate DESC
            ];
            
            List<ClearFileWrapper> result = new List<ClearFileWrapper>();
            
            // Получаем информацию о файлах Salesforce
            Set<String> fileIds = new Set<String>();
            for (Clear_files__c cf : clearFiles) {
                if (String.isNotBlank(cf.File_Id__c)) {
                    fileIds.add(cf.File_Id__c);
                }
            }
            
            Map<String, ContentVersion> fileMap = new Map<String, ContentVersion>();
            if (!fileIds.isEmpty()) {
                List<ContentVersion> contentVersions = [
                    SELECT Id, Title, FileType, ContentSize, CreatedDate, ContentDocumentId,
                           VersionData, FileExtension, ContentDocument.Title, ContentDocument.Description
                    FROM ContentVersion 
                    WHERE Id IN :fileIds
                    ORDER BY CreatedDate DESC
                ];
                
                for (ContentVersion cv : contentVersions) {
                    fileMap.put(cv.Id, cv);
                }
            }
            
            // Формируем результат
            for (Clear_files__c cf : clearFiles) {
                if (fileMap.containsKey(cf.File_Id__c)) {
                    ContentVersion cv = fileMap.get(cf.File_Id__c);
                    result.add(new ClearFileWrapper(
                        cf.Id,
                        cv.Title,
                        cv.ContentSize,
                        cv.CreatedDate,
                        cv.FileExtension,
                        cv.ContentDocumentId,
                        cv.Id
                    ));
                }
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching clear files: ' + e.getMessage());
        }
    }
    
    /**
     * Загрузка файла в Clear Files
     */
    @AuraEnabled
    public static String uploadFileToClearFiles(String fileName, String base64Data, String leadId, 
                                              Integer fileSize, String contentType) {
        if (String.isBlank(fileName) || String.isBlank(base64Data) || String.isBlank(leadId)) {
            throw new AuraHandledException('Missing fileName, base64Data or leadId');
        }
        
        try {
            // Создаем ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.PathOnClient = fileName;
            cv.IsMajorVersion = true;
            
            insert cv;
            
            // Получаем ContentDocumentId
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            
            // Создаем связь с Lead
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = insertedCV.ContentDocumentId;
            cdl.LinkedEntityId = leadId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            
            insert cdl;
            
            // Создаем запись в Clear_files__c
            Clear_files__c clearFile = new Clear_files__c();
            clearFile.Lead__c = leadId;
            clearFile.File_Id__c = cv.Id;
            
            insert clearFile;
            
            return clearFile.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
    
    /**
     * Удаление файла из Clear Files
     */
    @AuraEnabled
    public static void deleteClearFile(String fileId) {
        if (String.isBlank(fileId)) {
            throw new AuraHandledException('FileId is required');
        }
        
        try {
            // Получаем запись Clear_files__c
            List<Clear_files__c> clearFiles = [SELECT Id, File_Id__c, Lead__c FROM Clear_files__c WHERE Id = :fileId];
            
            if (!clearFiles.isEmpty()) {
                Clear_files__c clearFile = clearFiles[0];
                
                // Удаляем запись Clear_files__c
                delete clearFile;
                
                // Получаем ContentVersion
                List<ContentVersion> contentVersions = [
                    SELECT Id, ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :clearFile.File_Id__c
                ];
                
                if (!contentVersions.isEmpty()) {
                    ContentVersion cv = contentVersions[0];
                    
                    // Удаляем ContentDocumentLink для Lead
                    List<ContentDocumentLink> cdls = [
                        SELECT Id 
                        FROM ContentDocumentLink 
                        WHERE ContentDocumentId = :cv.ContentDocumentId 
                        AND LinkedEntityId = :clearFile.Lead__c
                    ];
                    
                    if (!cdls.isEmpty()) {
                        delete cdls;
                    }
                    
                    // Удаляем ContentDocument (это автоматически удалит все ContentVersion)
                    List<ContentDocument> contentDocs = [
                        SELECT Id 
                        FROM ContentDocument 
                        WHERE Id = :cv.ContentDocumentId
                    ];
                    
                    if (!contentDocs.isEmpty()) {
                        delete contentDocs;
                    }
                }
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        }
    }
    
    /**
     * Получение URL для скачивания файла
     */
    @AuraEnabled
    public static String getFileDownloadUrl(String fileId) {
        if (String.isBlank(fileId)) {
            throw new AuraHandledException('FileId is required');
        }
        
        try {
            // Получаем ContentVersion
            List<ContentVersion> contentVersions = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :fileId
            ];
            
            if (!contentVersions.isEmpty()) {
                ContentVersion cv = contentVersions[0];
                
                // Формируем URL для скачивания
                String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
                String downloadUrl = baseUrl + '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId;
                
                return downloadUrl;
            }
            
            return null;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting download URL: ' + e.getMessage());
        }
    }
    
    /**
     * Класс-обёртка для Clear Files
     */
    public class ClearFileWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String fileName;
        @AuraEnabled public Integer fileSize;
        @AuraEnabled public Datetime uploadDate;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String contentVersionId;
        
        public ClearFileWrapper(String id, String fileName, Integer fileSize, Datetime uploadDate, 
                              String fileExtension, String contentDocumentId, String contentVersionId) {
            this.id = id;
            this.fileName = fileName;
            this.fileSize = fileSize;
            this.uploadDate = uploadDate;
            this.fileExtension = fileExtension;
            this.contentDocumentId = contentDocumentId;
            this.contentVersionId = contentVersionId;
        }
    }
}