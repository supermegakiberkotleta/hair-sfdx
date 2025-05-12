@isTest
private class LeadTriggerHandlerTest {
    @isTest static void testClosedLostWithReason() {
        Lead l = new Lead(LastName='Test', Company='TestCo', Status='Closed Lost', Reason_for_closure__c='Undefined reason');
        insert l;
        System.assertEquals(false, l.Active_status__c);
    }

    @isTest static void testClosedLostWithoutReason() {
        Lead l = new Lead(LastName='Test2', Company='TestCo2', Status='Closed Lost');
        Test.startTest();
        try {
            insert l;
            System.assert(false); // Shouldn't reach here
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Please provide a reason for closure.'));
        }
        Test.stopTest();
    }

    @isTest static void testOtherStatus() {
        Lead l = new Lead(LastName='Test3', Company='TestCo3', Status='Open');
        insert l;
        //System.assertEquals(true, l.Active_status__c);
    }
}
