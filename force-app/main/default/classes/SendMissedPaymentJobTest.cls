@IsTest
private class SendMissedPaymentJobTest {
    private class SendLetterMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        if (req.getEndpoint().endsWith('/api/v1/send-letter')) {
            System.assertEquals('POST', req.getMethod(), 'Ожидался POST');
            System.assertEquals('application/json', req.getHeader('Content-Type'), 'Неверный Content-Type');

            Map<String,Object> bodyMap = (Map<String,Object>)JSON.deserializeUntyped(req.getBody());
            System.assert(bodyMap.containsKey('opportunityId'));
            System.assert(bodyMap.containsKey('MCA'));
            System.assert(bodyMap.containsKey('Merchant'));
            System.assert(bodyMap.containsKey('lenderType'));
            System.assert(bodyMap.containsKey('company'));
            System.assert(bodyMap.containsKey('client'));
            System.assert(bodyMap.containsKey('clientEmail'));
            System.assert(bodyMap.containsKey('state'));
            System.assert(bodyMap.containsKey('remainingAmount'));
            System.assert(bodyMap.containsKey('loanStartDate'));

            Map<String,Object> company = (Map<String,Object>)bodyMap.get('company');
            System.assert(company.containsKey('name'));
            System.assert(company.containsKey('ownerName'));
            System.assert(company.containsKey('ein'));
            System.assert(company.containsKey('ssn'));
            System.assert(company.containsKey('To_Company__c'));
            System.assert(company.containsKey('To_Email__c'));
            System.assert(company.containsKey('To_Phone__c'));
            System.assert(company.containsKey('To_Address_Line_1__c'));
            System.assert(company.containsKey('To_Address_Line_2__c'));
            System.assert(company.containsKey('To_Address_City__c'));
            System.assert(company.containsKey('To_Address_State__c'));
            System.assert(company.containsKey('To_Address_Zip__c'));
            System.assert(company.containsKey('To_Address_Country__c'));

            Map<String,Object> client = (Map<String,Object>)bodyMap.get('client');
            System.assert(client.containsKey('To_Name_Client__c'));
            System.assert(client.containsKey('To_Email_Client__c'));
            System.assert(client.containsKey('To_Phone_Client__c'));
            System.assert(client.containsKey('To_Address_Line_1_Client__c'));
            System.assert(client.containsKey('To_Address_Line_2_Client__c'));
            System.assert(client.containsKey('To_City_Client__c'));
            System.assert(client.containsKey('To_State_Client__c'));
            System.assert(client.containsKey('To_Zip_Client__c'));
            System.assert(client.containsKey('To_Country_Client__c'));
        } else {
            
        }

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"status":"ok"}');
        return res;
    }
}


    @IsTest
    static void shouldBuildPayloadAndSendCallout() {
        Opportunity opportunityRecord = new Opportunity(
            Name='Test Opp',
            StageName='0 days',
            CloseDate=Date.today().addDays(10),
            MCA__c='1st alliance',
            Merchant__c='Ach credit merchant svcs',
            Lender_type__c='Boostra',
            Company_name__c='Acme LLC',
            Company_owner_name__c='John Doe',
            Client_email__c='client@example.com',
            State__c='FL',
            EIN__c='12-3456789',
            SSN__c='123-45-6789',
            Remaining_amount__c=1000,
            Loan_Start_Date__c=Date.today().addDays(-30),
            To_Company__c='Acme LLC',
            To_Email__c='info@acme.test',
            To_Phone__c='555-0100',
            To_Address_Line_1__c='123 Main St',
            To_Address_Line_2__c='Suite 100',
            To_Address_City__c='Miami',
            To_Address_State__c='FL',
            To_Address_Zip__c='33101',
            To_Address_Country__c='US',
            To_Name_Client__c='Jane Smith',
            To_Email_Client__c='jane@example.com',
            To_Phone_Client__c='555-0200',
            To_Address_Line_1_Client__c='456 Ocean Dr',
            To_Address_Line_2_Client__c='Apt 5',
            To_City_Client__c='Miami Beach',
            To_State_Client__c='FL',
            To_Zip_Client__c='33139',
            To_Country_Client__c='US'
        );
        insert opportunityRecord;

        Test.setMock(HttpCalloutMock.class, new SendLetterMock());

        Test.startTest();
        System.enqueueJob(new SendMissedPaymentJob(opportunityRecord.Id));
        Test.stopTest();
    }
}