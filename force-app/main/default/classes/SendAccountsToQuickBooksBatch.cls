global class SendAccountsToQuickBooksBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Phone FROM Account WHERE Phone != null AND RecordTypeId = '012Kc000000tenBIAQ'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Sales_from_QuickBooks__c> newQBs = new List<Sales_from_QuickBooks__c>();
        Map<String, Sales_from_QuickBooks__c> existingQBs = getExistingQuickBooksRecords(accounts);

        for (Account acc : accounts) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://hair.lenderpro.ai/quickbooks/customer?token=lxhWgAsa0Y2zqpHD5pwVAXDOT'); // Используй Named Credential
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                Map<String, String> body = new Map<String, String>{
                    'Lead_Id' => acc.Id,
                    'Phone'   => acc.Phone
                };
                req.setBody(JSON.serialize(body));

                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    if (response.containsKey('Last_Sale_Date'))
                        acc.Last_Date_Of_Sale__c = Date.valueOf((String) response.get('Last_Sale_Date'));
                    if (response.containsKey('Outstanding_Balance'))
                        acc.Outstanding_balance__c = Decimal.valueOf(response.get('Outstanding_Balance').toString());
                    if (response.containsKey('Customer_Category'))
                        acc.Customer_category_quickbooks__c = (String) response.get('Customer_Category');

                    for (String key : response.keySet()) {
                        if (key.startsWith('Sales_')) {
                            String year = key.replace('Sales_', '');
                            if (isNumeric(year)) {
                                String qbKey = acc.Id + '_' + year;
                                if (existingQBs.containsKey(qbKey)) {
                                    existingQBs.get(qbKey).Total_sales__c = Integer.valueOf(response.get(key).toString());
                                } else {
                                    newQBs.add(new Sales_from_QuickBooks__c(
                                        Account__c = acc.Id,
                                        Name = year,
                                        Total_sales__c = Integer.valueOf(response.get(key).toString())
                                    ));
                                }
                            }
                        }
                    }

                    accountsToUpdate.add(acc);
                }
            } catch (Exception e) {
                System.debug('Ошибка: ' + e.getMessage());
            }
        }

        if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
        if (!newQBs.isEmpty()) insert newQBs;
        if (!existingQBs.isEmpty()) update existingQBs.values();
    }

    global void finish(Database.BatchableContext bc) {
        // Можно добавить лог или отправку уведомления
    }

    private static Map<String, Sales_from_QuickBooks__c> getExistingQuickBooksRecords(List<Account> accounts) {
        Map<String, Sales_from_QuickBooks__c> mapQBs = new Map<String, Sales_from_QuickBooks__c>();
        Set<Id> accIds = new Set<Id>();
        for (Account acc : accounts) accIds.add(acc.Id);

        for (Sales_from_QuickBooks__c qb : [
            SELECT Id, Account__c, Name, Total_sales__c FROM Sales_from_QuickBooks__c WHERE Account__c IN :accIds
        ]) {
            mapQBs.put(qb.Account__c + '_' + qb.Name, qb);
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
