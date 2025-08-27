@isTest
private class LeadMassDeleteControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Email = 'test' + i + '@test.com'
            ));
        }
        insert testLeads;
    }
    
    @isTest
    static void testConstructor() {
        // Создаем тестовые лиды для StandardSetController
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 3];
        
        Test.startTest();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        LeadMassDeleteController controller = new LeadMassDeleteController(ssc);
        Test.stopTest();
        
        // Проверяем, что контроллер создался корректно
        System.assertNotEquals(null, controller);
    }
    
    @isTest
    static void testDoDeleteWithSelectedRecords() {
        // Создаем тестовые лиды и отмечаем их как выбранные
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 3];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        ssc.setSelected(leads);
        
        LeadMassDeleteController controller = new LeadMassDeleteController(ssc);
        
        Test.startTest();
        PageReference result = controller.doDelete();
        Test.stopTest();
        
        // Проверяем, что лиды были удалены
        List<Lead> remainingLeads = [SELECT Id FROM Lead WHERE Id IN :leads];
        System.assertEquals(0, remainingLeads.size(), 'Leads should be deleted');
        
        // Проверяем, что возвращается PageReference
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testDoDeleteWithNoSelectedRecords() {
        // Создаем контроллер без выбранных записей
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 3];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        
        LeadMassDeleteController controller = new LeadMassDeleteController(ssc);
        
        Test.startTest();
        PageReference result = controller.doDelete();
        Test.stopTest();
        
        // Проверяем, что возвращается null при отсутствии выбранных записей
        System.assertEquals(null, result);
        
        // Проверяем, что сообщение об ошибке добавлено
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean errorMessageFound = false;
        for (ApexPages.Message msg : messages) {
            if (msg.getSeverity() == ApexPages.Severity.ERROR && 
                msg.getDetail().contains('No records selected')) {
                errorMessageFound = true;
                break;
            }
        }
        System.assert(errorMessageFound, 'Error message should be displayed');
    }
    
    @isTest
    static void testDoDeleteWithEmptySelection() {
        // Создаем контроллер с пустым списком выбранных записей
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 3];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        ssc.setSelected(new List<Lead>());
        
        LeadMassDeleteController controller = new LeadMassDeleteController(ssc);
        
        Test.startTest();
        PageReference result = controller.doDelete();
        Test.stopTest();
        
        // Проверяем, что возвращается null при пустом выборе
        System.assertEquals(null, result);
        
        // Проверяем, что сообщение об ошибке добавлено
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean errorMessageFound = false;
        for (ApexPages.Message msg : messages) {
            if (msg.getSeverity() == ApexPages.Severity.ERROR && 
                msg.getDetail().contains('No records selected')) {
                errorMessageFound = true;
                break;
            }
        }
        System.assert(errorMessageFound, 'Error message should be displayed');
    }
    
    @isTest
    static void testDoDeleteWithNullSelection() {
        // Создаем контроллер с null списком выбранных записей
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 3];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        
        LeadMassDeleteController controller = new LeadMassDeleteController(ssc);
        
        Test.startTest();
        PageReference result = controller.doDelete();
        Test.stopTest();
        
        // Проверяем, что возвращается null при null выборе
        System.assertEquals(null, result);
        
        // Проверяем, что сообщение об ошибке добавлено
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean errorMessageFound = false;
        for (ApexPages.Message msg : messages) {
            if (msg.getSeverity() == ApexPages.Severity.ERROR && 
                msg.getDetail().contains('No records selected')) {
                errorMessageFound = true;
                break;
            }
        }
        System.assert(errorMessageFound, 'Error message should be displayed');
    }
    
    @isTest
    static void testDoDeleteWithLargeSelection() {
        // Создаем больше тестовых лидов для проверки работы с большим количеством
        List<Lead> additionalLeads = new List<Lead>();
        for (Integer i = 5; i < 10; i++) {
            additionalLeads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Email = 'test' + i + '@test.com'
            ));
        }
        insert additionalLeads;
        
        // Выбираем все лиды
        List<Lead> allLeads = [SELECT Id FROM Lead];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(allLeads);
        ssc.setSelected(allLeads);
        
        LeadMassDeleteController controller = new LeadMassDeleteController(ssc);
        
        Test.startTest();
        PageReference result = controller.doDelete();
        Test.stopTest();
        
        // Проверяем, что все лиды были удалены
        List<Lead> remainingLeads = [SELECT Id FROM Lead];
        System.assertEquals(0, remainingLeads.size(), 'All leads should be deleted');
        
        // Проверяем, что возвращается PageReference
        System.assertNotEquals(null, result);
        
        // Проверяем сообщение об успехе
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean successMessageFound = false;
        for (ApexPages.Message msg : messages) {
            if (msg.getSeverity() == ApexPages.Severity.CONFIRM && 
                msg.getDetail().contains('removed')) {
                successMessageFound = true;
                break;
            }
        }
        System.assert(successMessageFound, 'Success message should be displayed');
    }
}


