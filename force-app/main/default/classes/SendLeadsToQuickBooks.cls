public with sharing class SendLeadsToQuickBooks implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        List<Lead> leads = [SELECT Id, Phone FROM Lead WHERE Phone != null AND RecordTypeId = '012Kc000000ten6IAA']; 

        List<QuickBooks__c> qbsToInsert = new List<QuickBooks__c>();
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Lead l : leads) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://hair.lenderpro.ai/quickbooks/customer?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                Map<String, String> body = new Map<String, String>{
                    'Lead_Id' => l.Id,
                    'Phone'   => l.Phone
                };
                req.setBody(JSON.serialize(body));

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    if (response.get('Last_Sale_Date') != null)
                        l.Last_date_of_sale__c = Date.valueOf((String) response.get('Last_Sale_Date'));

                    if (response.get('Outstanding_Balance') != null)
                        l.Outstanding_balance__c = Decimal.valueOf(response.get('Outstanding_Balance').toString());

                    if (response.get('Customer_Category') != null)
                        l.Customer_category_quickbooks__c = (String) response.get('Customer_Category');

                    for (String key : response.keySet()) {
                        if (key.startsWith('Sales_')) {
                            String yearStr = key.replace('Sales_', '');
                            if (isNumeric(yearStr)) {
                                qbsToInsert.add(new QuickBooks__c(
                                    Lead__c = l.Id,
                                    Name = yearStr,
                                    Total_sales__c = Integer.valueOf(response.get(key).toString())
                                ));
                            }
                        }
                    }

                    leadsToUpdate.add(l);
                } else {
                    System.debug('HTTP ошибка: ' + res.getStatus() + ' — ' + res.getBody());
                }

            } catch (Exception e) {
                System.debug('Ошибка при обработке лида ' + l.Id + ': ' + e.getMessage());
            }
        }

        if (!leadsToUpdate.isEmpty()) Database.update(leadsToUpdate, false);
        if (!qbsToInsert.isEmpty()) Database.insert(qbsToInsert, false);
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