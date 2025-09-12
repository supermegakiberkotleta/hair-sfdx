public with sharing class ApiDataController {
    @AuraEnabled
    public static void updateDataFromApi() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://lenderpro.itprofit.net/api/v1/us-report-sf'); // Замени на свой API
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            List<ApiRecordWrapper> items = (List<ApiRecordWrapper>) JSON.deserialize(res.getBody(), List<ApiRecordWrapper>.class);

            // Опционально: удалить старые записи
            delete [SELECT Id FROM API_Data__c];

            List<API_Data__c> recordsToInsert = new List<API_Data__c>();
            for (ApiRecordWrapper item : items) {
                recordsToInsert.add(new API_Data__c(
                    Name = item.name,
                    Field_1__c = item.field1,
                    Field_2__c = item.field2
                ));
            }
            insert recordsToInsert;
        } else {
            throw new AuraHandledException('Ошибка API: ' + res.getStatusCode());
        }
    }

    public class ApiRecordWrapper {
        public String name;
        public String field1;
        public String field2;
    }
}