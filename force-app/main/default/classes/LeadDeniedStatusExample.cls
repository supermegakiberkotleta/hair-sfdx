/**
 * Пример использования системы обработки статусов лидов DENIED
 * Этот класс демонстрирует, как работать с системой
 */
public class LeadDeniedStatusExample {
    
    /**
     * Пример получения информации о конфигурации
     */
    public static void showConfiguration() {
        // Получаем текущую конфигурацию
        Map<String, List<String>> config = LeadDeniedStatusConfig.getFieldValuesConfig();
        
        System.debug('Текущая конфигурация:');
        for (String fieldName : config.keySet()) {
            System.debug('Поле: ' + fieldName);
            List<String> values = config.get(fieldName);
            for (String value : values) {
                System.debug('  Значение: "' + value + '" -> Статус: "Final Denied"');
            }
        }
        
        // Получаем количество правил
        Integer rulesCount = LeadDeniedStatusConfig.getRulesCount();
        System.debug('Общее количество правил: ' + rulesCount);
        
        // Получаем список настроенных полей
        Set<String> fields = LeadDeniedStatusConfig.getConfiguredFields();
        System.debug('Настроенные поля: ' + fields);
    }
    
    /**
     * Пример проверки правила для конкретного значения
     */
    public static void checkRule(String fieldName, String fieldValue) {
        Boolean hasRule = LeadDeniedStatusConfig.hasRule(fieldName, fieldValue);
        String targetStatus = LeadDeniedStatusConfig.getTargetStatus(fieldName, fieldValue);
        
        if (hasRule) {
            System.debug('Найдено правило для поля "' + fieldName + '" со значением "' + fieldValue + '"');
            System.debug('Целевой статус: "' + targetStatus + '"');
        } else {
            System.debug('Правило для поля "' + fieldName + '" со значением "' + fieldValue + '" не найдено');
        }
    }
    
    /**
     * Пример симуляции обработки лида
     */
    public static void simulateLeadProcessing() {
        // Создаем тестовый лид (не сохраняем в базе)
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Parsing_Status__c = 'Black list',
            Industry__c = 'Technology'
        );
        
        System.debug('Тестируем лид:');
        System.debug('Company: ' + testLead.Company);
        System.debug('Parsing_Status__c: ' + testLead.Parsing_Status__c);
        System.debug('Industry__c: ' + testLead.Industry__c);
        
        // Проверяем правила для каждого поля
        checkRule('Company', testLead.Company);
        checkRule('Parsing_Status__c', testLead.Parsing_Status__c);
        checkRule('Industry__c', testLead.Industry__c);
    }
    
    /**
     * Пример получения информации о системе
     */
    public static void showSystemInfo() {
        System.debug('=== Информация о системе обработки статусов лидов ===');
        System.debug('Целевой статус: Final Denied');
        System.debug('RecordTypeId: 012Kc000000tenuIAA');
        System.debug('Триггер: LeadDeniedStatusTrigger');
        System.debug('Queueable: LeadDeniedStatusQueueable');
        System.debug('Конфигурация: LeadDeniedStatusConfig');
    }
    
    /**
     * Пример получения значений для конкретного поля
     */
    public static void showFieldValues(String fieldName) {
        List<String> values = LeadDeniedStatusConfig.getFieldValues(fieldName);
        
        if (values.isEmpty()) {
            System.debug('Поле "' + fieldName + '" не настроено в конфигурации');
        } else {
            System.debug('Значения для поля "' + fieldName + '":');
            for (String value : values) {
                System.debug('  - "' + value + '"');
            }
        }
    }
    
    /**
     * Пример проверки настроенности поля
     */
    public static void checkFieldConfiguration(String fieldName) {
        Boolean isConfigured = LeadDeniedStatusConfig.isFieldConfigured(fieldName);
        
        if (isConfigured) {
            System.debug('Поле "' + fieldName + '" настроено в конфигурации');
            showFieldValues(fieldName);
        } else {
            System.debug('Поле "' + fieldName + '" НЕ настроено в конфигурации');
        }
    }
}