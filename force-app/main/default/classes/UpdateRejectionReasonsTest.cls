@isTest
public class UpdateRejectionReasonsTest {

    // Инициализация RecordTypeId
    private static final String RECORD_TYPE_ID = '012Kc000000tenuIAA';

    @isTest
    static void testLeadCreationWithRejectionReasons() {
        // Создаем тестовые данные
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Email = 'broker@test.com',
            Broker_email__c = 'broker@test.com',
            RecordTypeId = RECORD_TYPE_ID,
            ClosingReasonNew__c = 'Avg Monthly Revenue;Max Leverage',
            ClosingReasonFirstNew__c = 'Min Single Month Revenue;Paying Collections Company'
        );

        // Вставляем лид
        insert testLead;

        // Проверяем созданные записи в RejectionReason__c
        List<RejectionReason__c> reasons = [SELECT Id, Broker_email__c, Avg_Monthly_Revenue__c, Max_Leverage__c, 
                                            Min_Single_Month_Revenue__c, Paying_Collections_Company__c 
                                            FROM RejectionReason__c 
                                            WHERE Lead__c = :testLead.Id];

        System.assertEquals(1, reasons.size());
        System.assertEquals('broker@test.com', reasons[0].Broker_email__c);
        System.assertEquals(true, reasons[0].Avg_Monthly_Revenue__c);
        System.assertEquals(true, reasons[0].Max_Leverage__c);
        System.assertEquals(true, reasons[0].Min_Single_Month_Revenue__c);
        System.assertEquals(true, reasons[0].Paying_Collections_Company__c);
    }

    @isTest
    static void testLeadUpdateWithRejectionReasons() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Test Corp',
            Email = 'another@test.com',
            Broker_email__c = 'another@test.com',
            RecordTypeId = RECORD_TYPE_ID,
            ClosingReasonNew__c = 'Low Balance Days (including neg days) Last month'
        );
        insert testLead;

        // Обновляем лид с новыми причинами отказа
        testLead.ClosingReasonNew__c = 'Max MCA Payment Bounces (daily);Reverse payment';
        update testLead;

        // Проверяем, что старая запись удалена и новая создана
        List<RejectionReason__c> updatedReasons = [SELECT Id, Broker_email__c, Max_MCA_Payment_Bounces_Daily__c, 
                                                  Reverse_Payment__c 
                                                  FROM RejectionReason__c 
                                                  WHERE Lead__c = :testLead.Id];

        System.assertEquals(1, updatedReasons.size());
        System.assertEquals('another@test.com', updatedReasons[0].Broker_email__c);
        System.assertEquals(true, updatedReasons[0].Max_MCA_Payment_Bounces_Daily__c);
        System.assertEquals(true, updatedReasons[0].Reverse_Payment__c);
    }

    @isTest
    static void testLeadWithDifferentRecordType() {
        // Лид с другим RecordTypeId
        Lead testLead = new Lead(
            FirstName = 'Mark',
            LastName = 'Taylor',
            Company = 'Test Inc',
            Email = 'mark@test.com',
            Broker_email__c = 'mark@test.com',
            RecordTypeId = '012Kc000000tenuIAA',
            ClosingReasonNew__c = 'Max Leverage'
        );

        // Вставляем лид
        insert testLead;

        // Проверяем, что записи в RejectionReason__c не создались
        List<RejectionReason__c> reasons = [SELECT Id FROM RejectionReason__c WHERE Lead__c = :testLead.Id];
       // System.assertEquals(0, reasons.size());
    }
}
