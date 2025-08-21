public with sharing class GenerateReportController {
    @AuraEnabled
    public static String sendLeadId(String leadId) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('Lead ID не может быть пустым');
        }

        // Тянем File_Id__c из Clear_files__c (указывают на ContentVersion.Id)
        List<Clear_files__c> clearFiles = [
            SELECT File_Id__c
            FROM Clear_files__c
            WHERE Lead__c = :leadId
              AND File_Id__c != null
        ];
        System.debug('Clear_files__c rows: ' + clearFiles.size());

        // Собираем Set<Id> из File_Id__c
        Set<Id> versionIds = new Set<Id>();
        for (Clear_files__c cf : clearFiles) {
            if (cf.File_Id__c != null) versionIds.add(cf.File_Id__c);
        }
        System.debug('ContentVersion Ids: ' + versionIds);

        // Тянем сами версии файлов по этим Id
        List<ContentVersion> versions = new List<ContentVersion>();
        if (!versionIds.isEmpty()) {
            versions = [
                SELECT Id, Title, FileExtension, VersionData
                FROM ContentVersion
                WHERE Id IN :versionIds
                // Если нужны только PDF, можно раскомментировать:
                // AND FileExtension = 'pdf'
            ];
        }
        System.debug('ContentVersion found: ' + versions.size());

        // Формируем массив файлов (base64)
        List<Map<String, Object>> fileList = new List<Map<String, Object>>();
        for (ContentVersion v : versions) {
            String base64Data = EncodingUtil.base64Encode(v.VersionData);
            fileList.add(new Map<String, Object>{
                'fileName' => v.Title + (String.isBlank(v.FileExtension) ? '' : '.' + v.FileExtension),
                'base64'   => base64Data
            });
        }

        // Готовим тело POST-запроса
        Map<String, Object> bodyMap = new Map<String, Object>{
            'leadId' => leadId,
            'files'  => fileList
        };

        System.debug('Prepared files: ' + fileList.size());
        System.debug('JSON length: ' + JSON.serialize(bodyMap).length());

        String endpointUrl = 'https://lenderpro.itprofit.net/api/v1/generate-report';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000); // ⏱ Установлен таймаут в 120 секунд
        request.setBody(JSON.serialize(bodyMap));

        HttpResponse response;
        try {
            response = http.send(request);
        } catch (System.CalloutException e) {
            throw new AuraHandledException('Ошибка при вызове внешнего сервиса: ' + e.getMessage());
        }

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            return 'Успех: ' + response.getBody();
        } else {
            throw new AuraHandledException('Ошибка: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }

    @AuraEnabled
    public static String sendOpportunityId(String opportunityId) {
        if (String.isBlank(opportunityId)) {
            throw new AuraHandledException('Opportunity ID не может быть пустым');
        }

        String endpointUrl = 'https://lenderpro.ai/api/v1/generate-opportunity-report';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000); // ⏱ Установлен таймаут в 60 секунд

        Map<String, String> bodyMap = new Map<String, String>{ 'opportunityId' => opportunityId };
        request.setBody(JSON.serialize(bodyMap));

        HttpResponse response;
        try {
            response = http.send(request);
        } catch (System.CalloutException e) {
            throw new AuraHandledException('Ошибка при вызове внешнего сервиса: ' + e.getMessage());
        }

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            return 'Успех: ' + response.getBody();
        } else {
            throw new AuraHandledException('Ошибка: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
}