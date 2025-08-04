global class SendAccountsToQuickBooksBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Phone FROM Account WHERE Phone != null AND Phone != '+' AND RecordTypeId = '012Kc000000tenBIAQ'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        for (Account acc : accounts) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://hair.lenderpro.ai/quickbooks/customer?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                Map<String, String> body = new Map<String, String>{
                    'Lead_Id' => acc.Id,
                    'Phone'   => acc.Phone
                };

                req.setBody(JSON.serialize(body));

                HttpResponse res = new Http().send(req);
                System.debug('Response status: ' + res.getStatusCode());

            } catch (Exception e) {
                System.debug('Ошибка при отправке аккаунта ' + acc.Id + ': ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Можно логировать окончание или отправлять уведомления
    }
}