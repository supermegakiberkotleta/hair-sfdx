@isTest
private class AccountTriggerHandlerTest {
    @isTest static void testClosedLostWithReason() {
        Account l = new Account(Name='Test', Client_Type__c='Closed Lost', Reason_for_closure__c='Undefined reason');
        insert l;
        System.assertEquals(false, l.Active_status__c);
    }

    @isTest static void testClosedLostWithoutReason() {
        Account l = new Account(Name='Test2', Client_Type__c='Closed Lost');
        Test.startTest();
        try {
            insert l;
            System.assert(false); // Shouldn't reach here
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Please provide a reason for closure.'));
        }
        Test.stopTest();
    }

    @isTest static void testOtherClientTypec() {
        Account l = new Account(Name='Test3', Client_Type__c='Discount 0%');
        insert l;
        //System.assertEquals(true, l.Active_status__c);
    }
}