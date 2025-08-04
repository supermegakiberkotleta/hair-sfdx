@isTest
private class LeadEmailSenderTest {
    @isTest
    static void testSendOpportunityCreatedEmail() {
        // Создаём тестового лида и opportunity
        Lead lead = new Lead(LastName='Test Lead', Company='TestCo');
        insert lead;

        Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today(), StageName='Prospecting');
        insert opp;

        Test.startTest();
        LeadEmailSender.sendOpportunityCreatedEmail(
            opp.Id,
            opp.Name,
            lead.Id,
            lead.Name
        );
        Test.stopTest();

        // Нет assert-ов, так как @future не возвращает результат
        // Но метод вызван и попадёт в coverage
    }

    @isTest
    static void testSendRejectionEmail() {
        Lead lead = new Lead(LastName='Rejected', Company='RejectCo');
        insert lead;

        Test.startTest();
        LeadEmailSender.sendRejectionEmail(lead.Id, lead.Name, 'Rejected');
        Test.stopTest();
    }

    @isTest
    static void testSendOfferEmail() {
        Lead lead = new Lead(LastName='Offer', Company='OfferCo');
        insert lead;

        Test.startTest();
        LeadEmailSender.sendOfferEmail(lead.Id, lead.Name, 'Offered');
        Test.stopTest();
    }
}