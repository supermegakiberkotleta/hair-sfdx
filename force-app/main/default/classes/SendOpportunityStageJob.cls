public class SendOpportunityStageJob implements Queueable, Database.AllowsCallouts {
    private String opportunityId;

    public SendOpportunityStageJob(String opportunityId) {
        this.opportunityId = opportunityId;
    }

    public void execute(QueueableContext context) {
        Opportunity opp = [
            SELECT Id, Name, StageName, Lender_type__c, Loan_Start_Date__c,
                   Phone_number__c, Client_email__c,
                   To_Address_Line_1__c, To_Address_City__c, To_Address_State__c, To_Address_Zip__c,
                   To_Address_Line_1_Client__c, To_City_Client__c, To_State_Client__c, To_Zip_Client__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        // Проверяем StageName
        List<String> validStages = new List<String>{'Collectors','Lawyers','Collectors+Lawyers'};
        if (!validStages.contains(opp.StageName)) {
            System.debug('StageName не соответствует условиям. Job завершён.');
            return;
        }

        // Формируем payload
        Map<String, Object> payload = new Map<String, Object>{
            'id' => opp.Id,
            'StageName' => opp.StageName,
            'Name' => opp.Name,
            'Lender_type__c' => opp.Lender_type__c,
            'Loan_Start_Date__c' => opp.Loan_Start_Date__c,
            'Phone_number__c' => opp.Phone_number__c,
            'Client_email__c' => opp.Client_email__c,
            'company_adress' => new List<String>{
                opp.To_Address_Line_1__c,
                opp.To_Address_City__c,
                opp.To_Address_State__c,
                opp.To_Address_Zip__c
            },
            'client_adress' => new List<String>{
                opp.To_Address_Line_1_Client__c,
                opp.To_City_Client__c,
                opp.To_State_Client__c,
                opp.To_Zip_Client__c
            }
        };

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://lenderpro.itprofit.net/api/v1/send-email');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            HttpResponse res = http.send(req);
            System.debug('Response status: ' + res.getStatus());
            System.debug('Response body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Ошибка при вызове API: ' + e.getMessage());
        }
    }
}