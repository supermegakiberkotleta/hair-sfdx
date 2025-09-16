public class SendMissedPaymentJob implements Queueable, Database.AllowsCallouts {
    private String oppId;

    public SendMissedPaymentJob(String oppId) {
        this.oppId = oppId;
    }

    public void execute(QueueableContext context) {
        // подтягиваем нужные поля
        Opportunity opp = [
            SELECT Id, MCA__c, Merchant__c,
                   To_Name__c, To_Company__c, To_Email__c, To_Phone__c,
                   To_Address_Line_1__c, To_Address_Line_2__c, To_Address_City__c,
                   To_Address_State__c, To_Address_Zip__c, To_Address_Country__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        // собираем recipients как массив
        List<Map<String, Object>> recipients = new List<Map<String, Object>>();
        Map<String, Object> recipient = new Map<String, Object>{
            'To_Name__c' => opp.To_Name__c,
            'To_Company__c' => opp.To_Company__c,
            'To_Email__c' => opp.To_Email__c,
            'To_Phone__c' => opp.To_Phone__c,
            'To_Address_Line_1__c' => opp.To_Address_Line_1__c,
            'To_Address_Line_2__c' => opp.To_Address_Line_2__c,
            'To_Address_City__c' => opp.To_Address_City__c,
            'To_Address_State__c' => opp.To_Address_State__c,
            'To_Address_Zip__c' => opp.To_Address_Zip__c,
            'To_Address_Country__c' => opp.To_Address_Country__c
        };
        
        // добавляем только если есть хотя бы какое-то значение
        if (String.isNotBlank(opp.To_Name__c) || String.isNotBlank(opp.To_Email__c)) {
            recipients.add(recipient);
        } else {
            recipients.add(recipient);
        }

        Map<String, Object> payload = new Map<String, Object>{
            'opportunityId' => opp.Id,
            'MCA' => opp.get('MCA__c'),
            'Merchant' => opp.get('Merchant__c'),
            'recipients' => recipients
        };

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();

            req.setEndpoint('https://lenderpro.itprofit.net/api/v1/send-letter');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(60000);
            req.setBody(JSON.serialize(payload, true));

            HttpResponse res = http.send(req);
            System.debug('MissedPayment POST ' + res.getStatusCode() + ' | ' + res.getBody());
        } catch (Exception e) {
            System.debug('MissedPayment POST failed: ' + e.getMessage());
        }
    }
}