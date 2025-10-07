public with sharing class FraudMonitoringFileUploader {
    @AuraEnabled
    public static void uploadFile(Id leadId, String fileName, String base64Data) {
        if (leadId == null || String.isBlank(fileName) || String.isBlank(base64Data)) {
            throw new AuraHandledException('Invalid parameters for uploadFile');
        }

        if (base64Data.startsWith('data:')) {
            Integer idx = base64Data.indexOf('base64,');
            if (idx > -1) {
                base64Data = base64Data.substring(idx + 7);
            }
        }

        Blob fileBody = EncodingUtil.base64Decode(base64Data);

        ContentVersion cv = new ContentVersion(
            Title = fileName.substringBeforeLast('.'),
            PathOnClient = fileName,
            VersionData = fileBody,
            Type__c = 'fraud_monitoring'
        );

        insert cv;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = leadId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        insert link;
    }

    @AuraEnabled
    public static void deleteFile(Id contentDocumentId) {
        if (contentDocumentId == null) {
            throw new AuraHandledException('Content Document ID is required');
        }

        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1];
        delete doc;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getFraudMonitoringFiles(Id leadId) {
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :leadId
            AND Visibility = 'AllUsers'
        ];

        if (links.isEmpty()) {
            return new List<Map<String, Object>>();
        }

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink l : links) {
            docIds.add(l.ContentDocumentId);
        }

        List<ContentVersion> versions = [
            SELECT Id, Title, FileExtension, VersionData, Type__c, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND Type__c = 'fraud_monitoring'
            AND IsLatest = true
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (ContentVersion version : versions) {
            result.add(new Map<String, Object>{
                'Id' => version.Id,
                'Title' => version.Title,
                'FileExtension' => version.FileExtension,
                'VersionData' => EncodingUtil.base64Encode(version.VersionData),
                'ContentDocumentId' => version.ContentDocumentId
            });
        }

        return result;
    }

    @AuraEnabled
    public static String getFileBase64Data(String fileId) {
        try {
            if (String.isBlank(fileId)) {
                throw new AuraHandledException('File ID is required');
            }
            
            System.debug('Looking for ContentVersion with ContentDocumentId: ' + fileId);
            
            List<ContentVersion> contentVersions = [
                SELECT Id, VersionData, Title, PathOnClient, FileExtension
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
    public static String getBookUuid(Id leadId) {
        try {
            if (String.isBlank(leadId)) {
                throw new AuraHandledException('Lead ID is required');
            }
            
            Lead lead = [SELECT uuid__c FROM Lead WHERE Id = :leadId LIMIT 1];
            if (lead.uuid__c == null) {
                throw new AuraHandledException('uuid__c is not set for this Lead');
            }
            
            return lead.uuid__c;
        } catch (Exception e) {
            System.debug('Error getting Lead uuid__c: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error getting Lead uuid__c: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String getScoringLink(Id leadId) {
        try {
            if (String.isBlank(leadId)) {
                throw new AuraHandledException('Lead ID is required');
            }
            
            Lead lead = [SELECT FILE__c FROM Lead WHERE Id = :leadId LIMIT 1];
            if (lead.FILE__c == null) {
                throw new AuraHandledException('FILE__c is not set for this Lead');
            }
            
            return lead.FILE__c;
        } catch (Exception e) {
            System.debug('Error getting Lead FILE__c: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error getting Lead FILE__c: ' + e.getMessage());
        }
    }
}