@isTest
public class SendOpportunityStageJobTest {

    // Счётчики и «инспектор» тел запросов — только на уровне верхнего класса (OK для static)
    private static Integer sendEmailCallCount = 0;
    private static Integer lenderTypeCallCount = 0;
    private static List<String> capturedRequestBodies = new List<String>();

    // Сброс состояния перед каждым тестом
    private static void resetHttpState() {
        sendEmailCallCount = 0;
        lenderTypeCallCount = 0;
        capturedRequestBodies.clear();
    }

    // Универсальный мок без static-полей внутри
    private class MockHttpRouter implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            String url = request.getEndpoint();
            if (request.getBody()!=null) {
                SendOpportunityStageJobTest.capturedRequestBodies.add(request.getBody());
            }

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);

            if (url!=null && url.contains('/api/v1/send-email')) {
                SendOpportunityStageJobTest.sendEmailCallCount++;
                response.setBody('{"success":true}');
                return response;
            }
            if (url!=null && url.contains('/api/v1/lender-type')) {
                SendOpportunityStageJobTest.lenderTypeCallCount++;
                response.setBody('{"ok":true}');
                return response;
            }

            response.setBody('{"ignored":true}');
            return response;
        }
    }

    @isTest
    static void testValidStageCollectors() {
        resetHttpState();

        Opportunity opportunityRecord = new Opportunity(
            Name='Test Opp',
            StageName='Collectors',
            CloseDate=Date.today(),
            Lender_type__c='Boostra',
            Loan_Start_Date__c=Date.today(),
            Phone_number__c='1234567890',
            Client_email__c='test@example.com',
            To_Address_Line_1__c='Street 1',
            To_Address_City__c='City',
            To_Address_State__c='ST',
            To_Address_Zip__c='00000',
            To_Address_Line_1_Client__c='Street 2',
            To_City_Client__c='Client City',
            To_State_Client__c='CL',
            To_Zip_Client__c='11111'
        );
        insert opportunityRecord;

        Test.setMock(HttpCalloutMock.class,new MockHttpRouter());
        Test.startTest();
        System.enqueueJob(new SendOpportunityStageJob(opportunityRecord.Id));
        Test.stopTest();

        System.assertEquals(1,sendEmailCallCount,'Ожидалась одна отправка на /api/v1/send-email');
        System.assert(capturedRequestBodies.size()>0,'Должно быть хотя бы одно тело запроса');
    }

    @isTest
    static void testInvalidStage() {
        resetHttpState();

        Opportunity opportunityRecord = new Opportunity(
            Name='Test Opp Invalid',
            StageName='5-10 days',
            CloseDate=Date.today()
        );
        insert opportunityRecord;

        Test.setMock(HttpCalloutMock.class,new MockHttpRouter());
        Test.startTest();
        System.enqueueJob(new SendOpportunityStageJob(opportunityRecord.Id));
        Test.stopTest();

        System.assertEquals(0,sendEmailCallCount,'Не должно быть отправок на /api/v1/send-email при невалидной стадии');
        System.assert(true,'Job завершился без ошибок при невалидной стадии');
    }
}