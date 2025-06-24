@isTest
public class LoanLeadsConvertedTriggerTest {

    // Получаем корректный RecordTypeId по DeveloperName
    static Id getLoanRecordTypeId() {
        return Schema.SObjectType.Lead
            .getRecordTypeInfosByDeveloperName()
            .get('Loan_Leads') // ❗замени на актуальный API Name
            .getRecordTypeId();
    }

    @isTest
    static void testTriggerBlocksLeadWithMissingFields() {
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = getLoanRecordTypeId()
            // ❌ не заполняем нужные поля
        );
        insert lead;

        Test.startTest();
        try {
            lead.Status = 'Call after';
            update lead;
            System.assert(false, 'Expected trigger to throw an error due to missing fields');
        } catch (DmlException e) {
            System.debug('Expected error: ' + e.getMessage());
            System.assert(e.getMessage().contains('you must fill in the fields'), 'Ошибка должна содержать список полей');
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
            RecordTypeId = getLoanRecordTypeId(),
            Final_Daily_payment__c = 100,
            Final_purchased_Amount_of_Future_New__c = 200,
            Payment_Frequency__c = 'Weekly',
            Loan_Start_Date__c = Date.today(),
            Final_Term__c = '12 months',
            Client_email__c = 'jane@example.com'
        );
        insert lead;

        Test.startTest();
        lead.Status = 'Call after';
        update lead; // ✅ должно пройти без ошибок
        Test.stopTest();

        Lead updated = [SELECT Status FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Call after', updated.Status, 'Статус должен быть обновлен');
    }
}
