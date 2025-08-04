global class SendLeadsToQuickBooksBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Phone FROM Lead WHERE Phone != null AND RecordTypeId = '012Kc000000ten6IAA'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Lead> leads) {
        List<Lead> leadsToUpdate = new List<Lead>();
        List<QuickBooks__c> newQBs = new List<QuickBooks__c>();
        Map<String, QuickBooks__c> existingQBs = getExistingQuickBooksRecords(leads);

        for (Lead l : leads) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://hair.lenderpro.ai/quickbooks/customer?token=lxhWgAsa0Y2zqpHD5pwVAXDOT'); // Используй Named Credential
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                Map<String, String> body = new Map<String, String>{
                    'Lead_Id' => l.Id,
                    'Phone'   => l.Phone
                };
                req.setBody(JSON.serialize(body));

                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    if (response.containsKey('Last_Sale_Date'))
                        l.Last_date_of_sale__c = Date.valueOf((String) response.get('Last_Sale_Date'));
                    if (response.containsKey('Outstanding_Balance'))
                        l.Outstanding_balance__c = Decimal.valueOf(response.get('Outstanding_Balance').toString());
                    if (response.containsKey('Customer_Category'))
                        l.Customer_category_quickbooks__c = (String) response.get('Customer_Category');

                    for (String key : response.keySet()) {
                        if (key.startsWith('Sales_')) {
                            String year = key.replace('Sales_', '');
                            if (isNumeric(year)) {
                                String qbKey = l.Id + '_' + year;
                                if (existingQBs.containsKey(qbKey)) {
                                    existingQBs.get(qbKey).Total_sales__c = Integer.valueOf(response.get(key).toString());
                                } else {
                                    newQBs.add(new QuickBooks__c(
                                        Lead__c = l.Id,
                                        Name = year,
                                        Total_sales__c = Integer.valueOf(response.get(key).toString())
                                    ));
                                }
                            }
                        }
                    }

                    leadsToUpdate.add(l);
                }
            } catch (Exception e) {
                System.debug('Ошибка: ' + e.getMessage());
            }
        }

        if (!leadsToUpdate.isEmpty()) update leadsToUpdate;
        if (!newQBs.isEmpty()) insert newQBs;
        if (!existingQBs.isEmpty()) update existingQBs.values();
    }

    global void finish(Database.BatchableContext bc) {
        // Можно добавить лог или отправку уведомления
    }

    private static Map<String, QuickBooks__c> getExistingQuickBooksRecords(List<Lead> leads) {
        Map<String, QuickBooks__c> mapQBs = new Map<String, QuickBooks__c>();
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : leads) leadIds.add(l.Id);

        for (QuickBooks__c qb : [
            SELECT Id, Lead__c, Name, Total_sales__c FROM QuickBooks__c WHERE Lead__c IN :leadIds
        ]) {
            mapQBs.put(qb.Lead__c + '_' + qb.Name, qb);
        }
        return mapQBs;
    }

    private static Boolean isNumeric(String str) {
        if (String.isBlank(str)) return false;
        try {
            Decimal.valueOf(str);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}