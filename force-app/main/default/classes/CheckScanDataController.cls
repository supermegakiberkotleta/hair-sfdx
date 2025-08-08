public with sharing class CheckScanDataController {
    
    @AuraEnabled(cacheable=false)
    public static Scan_Data__c getScanDataByLeadId(String leadId) {
        try {
            return [
                SELECT Id, Lead__c, File_Id__c, Routing_Number__c, Account_Number__c, Scan_Date__c, Type__c
                FROM Scan_Data__c 
                WHERE Lead__c = :leadId 
                AND Type__c = 'check'
                ORDER BY Scan_Date__c DESC 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error in getScanDataByLeadId: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static Scan_Data__c saveScanData(String leadId, String fileName, String base64Data, String routingNumber, String accountNumber) {
        try {
            System.debug('saveScanData called with leadId: ' + leadId);
            System.debug('fileName: ' + fileName);
            System.debug('routingNumber: ' + routingNumber);
            System.debug('accountNumber: ' + accountNumber);
            System.debug('base64Data length: ' + (base64Data != null ? base64Data.length() : 0));
            
            // Удаляем старые записи для этого Lead с типом 'check'
            List<Scan_Data__c> existingRecords = [
                SELECT Id, File_Id__c
                FROM Scan_Data__c 
                WHERE Lead__c = :leadId
                AND Type__c = 'check'
            ];
            
            System.debug('Found ' + existingRecords.size() + ' existing records');
            
            // Удаляем старые файлы
            List<Id> oldFileIds = new List<Id>();
            for (Scan_Data__c record : existingRecords) {
                if (record.File_Id__c != null) {
                    oldFileIds.add(record.File_Id__c);
                }
            }
            
            if (!oldFileIds.isEmpty()) {
                System.debug('Deleting ' + oldFileIds.size() + ' old files');
                List<ContentDocument> filesToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :oldFileIds];
                if (!filesToDelete.isEmpty()) {
                    delete filesToDelete;
                    System.debug('Deleted ' + filesToDelete.size() + ' files');
                }
            }
            
            if (!existingRecords.isEmpty()) {
                delete existingRecords;
                System.debug('Deleted ' + existingRecords.size() + ' existing records');
            }
            
            // Проверяем base64 данные перед созданием файла
            try {
                Blob fileBlob = EncodingUtil.base64Decode(base64Data);
                System.debug('Base64 decode successful, blob size: ' + fileBlob.size());
            } catch (Exception decodeEx) {
                System.debug('Base64 decode failed: ' + decodeEx.getMessage());
                throw new AuraHandledException('Invalid base64 data: ' + decodeEx.getMessage());
            }
            
            // Создаем новый файл
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.Title = 'Check_Scan_' + Datetime.now().format('yyyyMMdd_HHmmss') + '_' + fileName;
            cv.PathOnClient = fileName;
            cv.IsMajorVersion = true;
            
            System.debug('Creating ContentVersion with title: ' + cv.Title);
            insert cv;
            System.debug('ContentVersion created with ID: ' + cv.Id);
            
            // Получаем ContentDocument Id
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            System.debug('ContentDocument ID: ' + contentDocumentId);
            
            // Создаем связь с Lead
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = leadId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            System.debug('ContentDocumentLink created');
            
            // Создаем новую запись Scan_Data__c с типом 'check'
            Scan_Data__c scanData = new Scan_Data__c(
                Lead__c = leadId,
                File_Id__c = contentDocumentId,
                Routing_Number__c = routingNumber,
                Account_Number__c = accountNumber,
                Scan_Date__c = Datetime.now(),
                Type__c = 'check'
            );
            
            insert scanData;
            System.debug('Scan_Data__c record created with ID: ' + scanData.Id);
            return scanData;
        } catch (Exception e) {
            System.debug('Error in saveScanData: ' + e.getMessage());
            System.debug('Error type: ' + e.getTypeName());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving scan data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> getFileInfo(String fileId) {
        try {
            if (String.isBlank(fileId)) {
                System.debug('File ID is blank');
                return null;
            }
            
            System.debug('Looking for ContentVersion with ContentDocumentId: ' + fileId);
            
            List<ContentVersion> contentVersions = [
                SELECT Id, Title, PathOnClient, ContentSize, FileType
                FROM ContentVersion 
                WHERE ContentDocumentId = :fileId 
                AND IsLatest = true
                LIMIT 1
            ];
            
            if (contentVersions.isEmpty()) {
                System.debug('No ContentVersion found for ContentDocumentId: ' + fileId);
                return null;
            }
            
            ContentVersion cv = contentVersions[0];
            System.debug('Found ContentVersion: ' + cv);
            
            Map<String, Object> fileInfo = new Map<String, Object>();
            fileInfo.put('fileName', cv.PathOnClient);
            fileInfo.put('fileSize', cv.ContentSize);
            fileInfo.put('fileType', cv.FileType);
            
            System.debug('File info retrieved: ' + fileInfo);
            return fileInfo;
        } catch (Exception e) {
            System.debug('Error getting file info: ' + e.getMessage());
            System.debug('Error type: ' + e.getTypeName());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    @AuraEnabled
    public static String getFileUrl(String fileId) {
        try {
            if (String.isBlank(fileId)) {
                return null;
            }
            
            ContentVersion cv = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE ContentDocumentId = :fileId 
                AND IsLatest = true
                LIMIT 1
            ];
            
            return '/sfc/servlet.shepherd/document/download/' + cv.Id;
        } catch (Exception e) {
            System.debug('Error getting file URL: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static String getFileBase64Data(String fileId) {
        try {
            if (String.isBlank(fileId)) {
                throw new AuraHandledException('File ID is required');
            }
            
            System.debug('Looking for ContentVersion with ContentDocumentId: ' + fileId);
            
            List<ContentVersion> contentVersions = [
                SELECT Id, VersionData, Title, PathOnClient
                FROM ContentVersion 
                WHERE ContentDocumentId = :fileId 
                AND IsLatest = true
                LIMIT 1
            ];
            
            if (contentVersions.isEmpty()) {
                System.debug('No ContentVersion found for ContentDocumentId: ' + fileId);
                throw new AuraHandledException('File not found');
            }
            
            ContentVersion cv = contentVersions[0];
            System.debug('Found ContentVersion: ' + cv);
            
            String base64Data = EncodingUtil.base64Encode(cv.VersionData);
            System.debug('Retrieved base64 data length: ' + base64Data.length());
            return base64Data;
        } catch (Exception e) {
            System.debug('Error getting file base64 data: ' + e.getMessage());
            System.debug('Error type: ' + e.getTypeName());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error getting file data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateScanDataWithResult(String scanDataId, String routingNumber, String accountNumber) {
        try {
            if (String.isBlank(scanDataId)) {
                throw new AuraHandledException('Scan Data ID is required');
            }
            
            Scan_Data__c scanData = [
                SELECT Id, Routing_Number__c, Account_Number__c, Type__c
                FROM Scan_Data__c 
                WHERE Id = :scanDataId
                AND Type__c = 'check'
                LIMIT 1
            ];
            
            if (scanData == null) {
                throw new AuraHandledException('Scan Data record not found');
            }
            
            scanData.Routing_Number__c = routingNumber;
            scanData.Account_Number__c = accountNumber;
            update scanData;
            
            System.debug('Updated scan data with routing number: ' + routingNumber + ', account number: ' + accountNumber);
        } catch (Exception e) {
            System.debug('Error updating scan data: ' + e.getMessage());
            throw new AuraHandledException('Error updating scan data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteScanData(String leadId) {
        try {
            List<Scan_Data__c> recordsToDelete = [
                SELECT Id, File_Id__c
                FROM Scan_Data__c 
                WHERE Lead__c = :leadId
                AND Type__c = 'check'
            ];
            
            // Удаляем файлы
            List<Id> fileIds = new List<Id>();
            for (Scan_Data__c record : recordsToDelete) {
                if (record.File_Id__c != null) {
                    fileIds.add(record.File_Id__c);
                }
            }
            
            if (!fileIds.isEmpty()) {
                List<ContentDocument> filesToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :fileIds];
                if (!filesToDelete.isEmpty()) {
                    delete filesToDelete;
                }
            }
            
            // Удаляем записи Scan_Data__c
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        } catch (Exception e) {
            System.debug('Error deleting scan data: ' + e.getMessage());
            throw new AuraHandledException('Error deleting scan data: ' + e.getMessage());
        }
    }
} 