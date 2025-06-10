@isTest
public class BrokerFeeTriggerTest {
    static final String TAG = 'Biz Capital 12%';

    static testMethod void testLeadTrigger() {
        Lead l = new Lead(
            LastName = 'Test',
            Company = 'Test Co',
            Tag__c = TAG,
            OfferAmount__c = 10000
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead inserted = [SELECT BrokersFee__c FROM Lead WHERE Id = :l.Id];
        //System.assertEquals(1200, inserted.BrokersFee__c);
    }

    static testMethod void testContactTrigger() {
        Contact c = new Contact(
            LastName = 'Test',
            FirstName = 'Trigger',
            Tag__c = TAG,
            OfferAmount__c = 15000
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Contact inserted = [SELECT BrokersFee__c FROM Contact WHERE Id = :c.Id];
        //System.assertEquals(1800, inserted.BrokersFee__c);
    }

    static testMethod void testAccountTrigger() {
        Account a = new Account(
            Name = 'Test Account',
            Tag__c = TAG,
            OfferAmount__c = 20000
        );

        Test.startTest();
        insert a;
        Test.stopTest();

        Account inserted = [SELECT BrokersFee__c FROM Account WHERE Id = :a.Id];
        //System.assertEquals(2400, inserted.BrokersFee__c);
    }

    static testMethod void testOpportunityTrigger() {
        Opportunity o = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Tag__c = TAG,
            OfferAmount__c = 5000
        );

        Test.startTest();
        insert o;
        Test.stopTest();

        Opportunity inserted = [SELECT BrokersFee__c FROM Opportunity WHERE Id = :o.Id];
        //System.assertEquals(600, inserted.BrokersFee__c);
    }

    static testMethod void testIgnoreUnsupportedTag() {
        Lead l = new Lead(
            LastName = 'Test',
            Company = 'Invalid Tag',
            Tag__c = 'Unknown Tag',
            OfferAmount__c = 10000
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead inserted = [SELECT BrokersFee__c FROM Lead WHERE Id = :l.Id];
        //System.assertEquals(null, inserted.BrokersFee__c);
    }

    static testMethod void testBlankTagNoFee() {
        Opportunity o = new Opportunity(
            Name = 'No Tag',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            OfferAmount__c = 10000,
            Tag__c = null
        );

        Test.startTest();
        insert o;
        Test.stopTest();

        Opportunity inserted = [SELECT BrokersFee__c FROM Opportunity WHERE Id = :o.Id];
        //System.assertEquals(null, inserted.BrokersFee__c);
    }

    static testMethod void testNullOfferAmountNoFee() {
        Contact c = new Contact(
            LastName = 'Test',
            Tag__c = TAG,
            OfferAmount__c = null
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Contact inserted = [SELECT BrokersFee__c FROM Contact WHERE Id = :c.Id];
        //System.assertEquals(null, inserted.BrokersFee__c);
    }
}
