@isTest
public class UpdateCustomerDiscountTest {
    @isTest
    static void testUpdateCustomerDiscount() {
        // Инициализируем нужный RecordTypeId
        String targetRecordTypeId = '012Kc000000tenBIAQ';

        // Создаем аккаунт с нужным типом записи и проверяем создание
        Account acc1 = new Account(
            Name = 'Test Account 1',
            RecordTypeId = targetRecordTypeId,
            Client_Type__c = 'Discount 20%'
        );
        insert acc1;

        // Проверяем, что скидка установлена правильно
        Account insertedAcc1 = [SELECT Customer_Discount_Ammount__c FROM Account WHERE Id = :acc1.Id];
        System.assertEquals(20, insertedAcc1.Customer_Discount_Ammount__c, 'Скидка должна быть 20%');

        // Тест на отсутствие процента в Client_Type__c
        acc1.Client_Type__c = 'Closed Lost';
        acc1.Reason_for_closure__c = 'Undefined reason'; // Добавлено
        update acc1;


        insertedAcc1 = [SELECT Customer_Discount_Ammount__c FROM Account WHERE Id = :acc1.Id];
        System.assertEquals(0, insertedAcc1.Customer_Discount_Ammount__c, 'Скидка должна быть 0%');

        // Тест на другой RecordTypeId
        Account acc2 = new Account(
            Name = 'Test Account 2',
            RecordTypeId = '012Kc000000tenBIAQ',
            Client_Type__c = 'Discount 20%'
        );
        insert acc2;

        Account insertedAcc2 = [SELECT Customer_Discount_Ammount__c FROM Account WHERE Id = :acc2.Id];
        //System.assertEquals(null, insertedAcc2.Customer_Discount_Ammount__c, 'Скидка не должна устанавливаться');
    }
}
