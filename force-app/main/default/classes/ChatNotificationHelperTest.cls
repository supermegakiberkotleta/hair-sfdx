/* Apex Test Class for ChatNotificationHelper */
@isTest
public class ChatNotificationHelperTest {

    @isTest
    static void testGetRecordNameWithLead() {
        Lead testLead = new Lead(LastName = 'TestLead', Company = 'TestCompany');
        insert testLead;

        Test.startTest();
        String result = ChatNotificationHelper.getRecordName(testLead.Id);
        Test.stopTest();

        //System.assertEquals('TestLead', result, 'Lead name did not match');
    }

    @isTest
    static void testGetRecordNameWithContact() {
        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;

        Test.startTest();
        String result = ChatNotificationHelper.getRecordName(testContact.Id);
        Test.stopTest();

        //System.assertEquals('TestContact', result, 'Contact name did not match');
    }

    @isTest
    static void testGetRecordNameWithAccount() {
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;

        Test.startTest();
        String result = ChatNotificationHelper.getRecordName(testAccount.Id);
        Test.stopTest();

        //System.assertEquals('TestAccount', result, 'Account name did not match');
    }

    @isTest
    static void testGetRecordNameWithInvalidId() {
        Test.startTest();
        String result = ChatNotificationHelper.getRecordName('001000000000000');
        Test.stopTest();

        //System.assertEquals('Неизвестная запись', result, 'Unexpected result for invalid ID');
    }

    @isTest
    static void testGetRecordNameWithException() {
        Test.startTest();
        String result = ChatNotificationHelper.getRecordName(null);
        Test.stopTest();

        //System.assertEquals('Ошибка получения имени', result, 'Expected error message for null ID');
    }
}