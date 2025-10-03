public class SendMissedPaymentJob implements Queueable, Database.AllowsCallouts {
    private String opportunityId;

    public SendMissedPaymentJob(String opportunityId) {
        this.opportunityId = opportunityId;
    }

    public void execute(QueueableContext context) {
        Opportunity opportunityRecord = [
            SELECT Id, MCA__c, Merchant__c,
                   Lender_type__c, Company_name__c, Company_owner_name__c,
                   Client_email__c, State__c, EIN__c, SSN__c,
                   Remaining_amount__c, Loan_Start_Date__c,
                   To_Company__c, To_Email__c, To_Phone__c,
                   To_Address_Line_1__c, To_Address_Line_2__c, To_Address_City__c,
                   To_Address_State__c, To_Address_Zip__c, To_Address_Country__c,
                   To_Name_Client__c, To_Email_Client__c, To_Phone_Client__c,
                   To_Address_Line_1_Client__c, To_Address_Line_2_Client__c, To_City_Client__c,
                   To_State_Client__c, To_Zip_Client__c, To_Country_Client__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Map<String,Object> payload = new Map<String,Object>{
            'opportunityId' => opportunityRecord.Id,
            'MCA' => opportunityRecord.MCA__c,
            'Merchant' => opportunityRecord.Merchant__c,
            'lenderType' => opportunityRecord.Lender_type__c,
            'company' => new Map<String,Object>{
                'name' => opportunityRecord.Company_name__c,
                'ownerName' => opportunityRecord.Company_owner_name__c,
                'ein' => opportunityRecord.EIN__c,
                'ssn' => opportunityRecord.SSN__c,
                'To_Company__c' => opportunityRecord.To_Company__c,
                'To_Email__c' => opportunityRecord.To_Email__c,
                'To_Phone__c' => opportunityRecord.To_Phone__c,
                'To_Address_Line_1__c' => opportunityRecord.To_Address_Line_1__c,
                'To_Address_Line_2__c' => opportunityRecord.To_Address_Line_2__c,
                'To_Address_City__c' => opportunityRecord.To_Address_City__c,
                'To_Address_State__c' => opportunityRecord.To_Address_State__c,
                'To_Address_Zip__c' => opportunityRecord.To_Address_Zip__c,
                'To_Address_Country__c' => opportunityRecord.To_Address_Country__c
            },
            'client' => new Map<String,Object>{
                'To_Name_Client__c' => opportunityRecord.To_Name_Client__c,
                'To_Email_Client__c' => opportunityRecord.To_Email_Client__c,
                'To_Phone_Client__c' => opportunityRecord.To_Phone_Client__c,
                'To_Address_Line_1_Client__c' => opportunityRecord.To_Address_Line_1_Client__c,
                'To_Address_Line_2_Client__c' => opportunityRecord.To_Address_Line_2_Client__c,
                'To_City_Client__c' => opportunityRecord.To_City_Client__c,
                'To_State_Client__c' => opportunityRecord.To_State_Client__c,
                'To_Zip_Client__c' => opportunityRecord.To_Zip_Client__c,
                'To_Country_Client__c' => opportunityRecord.To_Country_Client__c
            },
            'clientEmail' => opportunityRecord.Client_email__c,
            'state' => opportunityRecord.State__c,
            'remainingAmount' => opportunityRecord.Remaining_amount__c,
            'loanStartDate' => opportunityRecord.Loan_Start_Date__c
        };

        try {
            Http httpClient = new Http();
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint('https://lenderpro.itprofit.net/api/v1/send-letter');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setTimeout(60000);
            httpRequest.setBody(JSON.serialize(payload, true));

            HttpResponse httpResponse = httpClient.send(httpRequest);
            System.debug('MissedPayment POST ' + httpResponse.getStatusCode() + ' | ' + httpResponse.getBody());
        } catch (Exception error) {
            System.debug('MissedPayment POST failed: ' + error.getMessage());
        }
    }
}