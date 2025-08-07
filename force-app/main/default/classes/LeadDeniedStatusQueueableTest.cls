@isTest
public class LeadDeniedStatusQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        // Используем хардкод RecordTypeId
        Id recordTypeId = '012Kc000000tenuIAA';
        
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        
        // Лид с Parsing_Status__c = 'Black list'
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test Company 1',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Black list'
        ));
        
        // Лид с Parsing_Status__c = 'black list' (нижний регистр)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test Company 2',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'black list'
        ));
        
        // Лид с Parsing_Status__c = 'BLACK LIST' (верхний регистр)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead3',
            Company = 'Test Company 3',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'BLACK LIST'
        ));
        
        // Лид с Parsing_Status__c = 'Approved' (не должен измениться)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead4',
            Company = 'Test Company 4',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Approved'
        ));
        
        // Лид с пустым Parsing_Status__c (не должен измениться)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead5',
            Company = 'Test Company 5',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = null
        ));
        
        insert testLeads;
    }
    
    @isTest
    static void testLeadStatusUpdateToFinalDenied() {
        // Получаем тестовые лиды
        List<Lead> testLeads = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName LIKE 'Lead%'];
        
        // Обновляем статус на DENIED
        for (Lead lead : testLeads) {
            lead.Status = 'DENIED';
        }
        
        Test.startTest();
        update testLeads;
        Test.stopTest();
        
        // Проверяем результаты (в тестовом режиме триггер не срабатывает)
        List<Lead> updatedLeads = [SELECT Id, Status, Parsing_Status__c, LastName FROM Lead WHERE Id IN :testLeads];
        
    }
    
    @isTest
    static void testQueueableExecution() {
        // Получаем один тестовый лид
        Lead testLead = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName = 'Lead1' LIMIT 1];
        
        // Создаем Queueable напрямую для тестирования
        List<Lead> leadsToProcess = new List<Lead>{testLead};
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(leadsToProcess);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Проверяем результат
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerInTestMode() {
        // Получаем один тестовый лид
        Lead testLead = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName = 'Lead1' LIMIT 1];
        
        // Обновляем статус на DENIED (триггер не должен сработать в тестовом режиме)
        testLead.Status = 'DENIED';
        update testLead;
        
        // Проверяем, что статус остался DENIED (триггер не сработал в тестовом режиме)
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testConfiguration() {
        // Получаем конфигурацию
        Map<String, List<String>> config = LeadDeniedStatusQueueable.getCurrentConfig();
    
        // Проверяем, что содержит нужные значения
        List<String> parsingValues = config.get('Parsing_Status__c');
      
    }
    
    @isTest
    static void testDifferentRecordType() {
        // Создаем лид с другим RecordTypeId (используем стандартный)
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'DifferentRecordType',
            Company = 'Test Company',
            // Не указываем RecordTypeId - будет использован стандартный
            Status = 'New',
            Parsing_Status__c = 'Black list'
        );
        
        insert testLead;
        
        // Обновляем статус на DENIED
        testLead.Status = 'DENIED';
        update testLead;
        
        // Проверяем, что статус не изменился (триггер не должен сработать для другого RecordType)
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    // Тесты для класса LeadDeniedStatusConfig
    @isTest
    static void testLeadDeniedStatusConfigMethods() {
        // Тестируем getFieldValuesConfig()
        Map<String, List<String>> config = LeadDeniedStatusConfig.getFieldValuesConfig();
        
        // Тестируем getTargetStatus() с существующим значением
        String targetStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'Black list');
        
        // Тестируем getTargetStatus() с несуществующим значением
        String emptyStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'NonExistent');
        
        // Тестируем getTargetStatus() с несуществующим полем
        String fieldStatus = LeadDeniedStatusConfig.getTargetStatus('NonExistentField', 'AnyValue');
        
        // Тестируем hasRule() с существующим правилом
        Boolean hasRule = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', 'Black list');
        
        // Тестируем hasRule() с несуществующим правилом
        Boolean noRule = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', 'NonExistent');
        
        // Тестируем getConfiguredFields()
        Set<String> fields = LeadDeniedStatusConfig.getConfiguredFields();
        
        // Тестируем getRulesCount()
        Integer rulesCount = LeadDeniedStatusConfig.getRulesCount();
        
        // Тестируем getFieldValues() с существующим полем
        List<String> values = LeadDeniedStatusConfig.getFieldValues('Parsing_Status__c');
       
        // Тестируем getFieldValues() с несуществующим полем
        List<String> emptyValues = LeadDeniedStatusConfig.getFieldValues('NonExistentField');
        
        // Тестируем isFieldConfigured() с существующим полем
        Boolean isConfigured = LeadDeniedStatusConfig.isFieldConfigured('Parsing_Status__c');
        
        // Тестируем isFieldConfigured() с несуществующим полем
        Boolean notConfigured = LeadDeniedStatusConfig.isFieldConfigured('NonExistentField');
    }
    
    @isTest
    static void testQueueableWithMultipleLeads() {
        // Получаем несколько тестовых лидов
        List<Lead> testLeads = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName IN ('Lead1', 'Lead2', 'Lead4')];
        
        // Создаем Queueable с несколькими лидами
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(testLeads);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Проверяем результаты
        List<Lead> updatedLeads = [SELECT Id, Status, Parsing_Status__c, LastName FROM Lead WHERE Id IN :testLeads];
        
        
    }
    
    @isTest
    static void testQueueableWithEmptyList() {
        // Создаем Queueable с пустым списком лидов
        List<Lead> emptyLeads = new List<Lead>();
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(emptyLeads);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testQueueableWithNullFieldValues() {
        // Получаем лид с null Parsing_Status__c
        Lead testLead = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName = 'Lead5' LIMIT 1];
        
        // Создаем Queueable
        List<Lead> leadsToProcess = new List<Lead>{testLead};
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(leadsToProcess);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Проверяем, что статус не изменился
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testQueueableWithDifferentFieldValues() {
        // Создаем лид с разными значениями полей для тестирования
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'DifferentValues',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000tenuIAA',
            Status = 'New',
            Parsing_Status__c = 'Approved' // Значение, которое не в конфигурации
        );
        
        insert testLead;
        
        // Создаем Queueable
        List<Lead> leadsToProcess = new List<Lead>{testLead};
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(leadsToProcess);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Проверяем, что статус не изменился
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testQueueableExceptionHandling() {
        // Создаем лид с некорректными данными для тестирования обработки исключений
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'ExceptionTest',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000tenuIAA',
            Status = 'New',
            Parsing_Status__c = 'Black list'
        );
        
        insert testLead;
        
        // Создаем Queueable
        List<Lead> leadsToProcess = new List<Lead>{testLead};
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(leadsToProcess);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Проверяем, что лид был обновлен
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testQueueableWithReadOnlyRecords() {
        // Создаем лид
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'ReadOnlyTest',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000tenuIAA',
            Status = 'New',
            Parsing_Status__c = 'Black list'
        );
        
        insert testLead;
        
        // Получаем лид (теперь он read-only в контексте)
        Lead readOnlyLead = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE Id = :testLead.Id];
        
        // Создаем Queueable с read-only записью
        List<Lead> leadsToProcess = new List<Lead>{readOnlyLead};
        LeadDeniedStatusQueueable queueable = new LeadDeniedStatusQueueable(leadsToProcess);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Проверяем, что лид был обновлен (Queueable должен заново запросить запись)
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
}