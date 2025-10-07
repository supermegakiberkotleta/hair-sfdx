public with sharing class FileServiceController {
    
    // Получение файлов по leadId
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getUploadedFiles(String leadId) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('LeadId is required');
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/ocrolus/get-info');
        request.setMethod('POST');

        // Создаем параметры для тела запроса
        String body = 'leadId=' + EncodingUtil.urlEncode(leadId, 'UTF-8');
        request.setBody(body);  // Устанавливаем тело запроса

        // Устанавливаем заголовки, если необходимо
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded'); // Для передачи данных формы

        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            return (List<FileWrapper>) JSON.deserialize(response.getBody(), List<FileWrapper>.class);
        } else {
            throw new AuraHandledException('Error fetching files: ' + response.getStatus() + ' - ' + response.getBody());
        }
    }


    // Загрузка файла с передачей leadId
    @AuraEnabled
    public static void uploadFile(String fileName, String base64Data, String leadId) {
        if (String.isBlank(fileName) || String.isBlank(base64Data) || String.isBlank(leadId)) {
            throw new AuraHandledException('Missing fileName, base64Data or leadId');
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/ocrolus/upload-single-document');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Map<String, String> body = new Map<String, String>();
        body.put('fileName', fileName);
        body.put('fileData', base64Data);
        body.put('leadId', leadId); // Добавили передачу ID лида

        request.setBody(JSON.serialize(body));

        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 200) {
            throw new AuraHandledException('Upload failed: ' + response.getStatus() + ' - ' + response.getBody());
        }
    }

    @AuraEnabled
    public static void triggerNewScoring(String leadId) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('LeadId is required');
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/ocrolus/new-scoring');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body = 'leadId=' + EncodingUtil.urlEncode(leadId, 'UTF-8');
        request.setBody(body);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            throw new AuraHandledException('Scoring request failed: ' + response.getStatus() + ' - ' + response.getBody());
        }
    }

    // Класс-обёртка для ответа
    public class FileWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String status;
         @AuraEnabled public String type;
    }
}