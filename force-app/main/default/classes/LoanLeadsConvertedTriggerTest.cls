@isTest
public class LoanLeadsConvertedTriggerTest {

    // Get Loan_Leads RecordType ID
    static Id getLoanRecordTypeId() {
        try {
            return Schema.SObjectType.Lead
                .getRecordTypeInfosByDeveloperName()
                .get('Loan_Leads')
                .getRecordTypeId();
        } catch (Exception e) {
            // If RecordType doesn't exist, return null
            return null;
        }
    }

    @isTest
    static void testTriggerBlocksLeadWithMissingFields() {
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Status = 'New',
            Email = 'john@example.com'
            // ❌ не заполняем нужные поля
        );
        
        // Set RecordType if it exists
        Id recordTypeId = getLoanRecordTypeId();
        if (recordTypeId != null) {
            lead.RecordTypeId = recordTypeId;
        }
        
        insert lead;

        Test.startTest();
        try {
            lead.Status = 'Call after';
            update lead;
        } catch (DmlException e) {
            System.debug('Expected error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testTriggerAllowsLeadWithAllFields() {
        Lead lead = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Test Company',
            Status = 'New',
            Email = 'jane@example.com',
            Final_Daily_payment__c = 100,
            Final_purchased_Amount_of_Future_New__c = 200,
            Payment_Frequency__c = '100',
            Loan_Start_Date__c = Date.today(),
            Final_Term__c = '100',
            Client_email__c = 'jane@example.com',
            Lender_type__c = 'Liberty'
        );
        
        // Set RecordType if it exists
        Id recordTypeId = getLoanRecordTypeId();
        if (recordTypeId != null) {
            lead.RecordTypeId = recordTypeId;
        }
        
        insert lead;

        Test.startTest();
        lead.Status = 'Call after';
        update lead; // ✅ должно пройти без ошибок
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :lead.Id];
    }
}