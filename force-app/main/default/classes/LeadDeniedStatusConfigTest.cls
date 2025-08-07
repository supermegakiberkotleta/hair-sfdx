@isTest
public class LeadDeniedStatusConfigTest {
    
    @isTest
    static void testGetFieldValuesConfig() {
        // Тестируем получение конфигурации
        Map<String, List<String>> config = LeadDeniedStatusConfig.getFieldValuesConfig();
        
        // Проверяем, что конфигурация не null
        System.assertNotEquals(null, config, 'Config should not be null');
        
        // Проверяем, что содержит нужное поле
        System.assert(config.containsKey('Parsing_Status__c'), 'Should contain Parsing_Status__c field');
        
        // Проверяем, что поле содержит нужные значения
        List<String> values = config.get('Parsing_Status__c');
        System.assert(values.contains('Black list'), 'Should contain Black list value');
        System.assert(values.contains('black list'), 'Should contain black list value');
        System.assert(values.contains('BLACK LIST'), 'Should contain BLACK LIST value');
    }
    
    @isTest
    static void testGetTargetStatus() {
        // Тестируем с существующим значением
        String targetStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'Black list');
        System.assertEquals('Final Denied', targetStatus, 'Should return Final Denied for Black list');
        
        // Тестируем с другим регистром
        String lowerCaseStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'black list');
        System.assertEquals('Final Denied', lowerCaseStatus, 'Should return Final Denied for black list');
        
        String upperCaseStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'BLACK LIST');
        System.assertEquals('Final Denied', upperCaseStatus, 'Should return Final Denied for BLACK LIST');
        
        // Тестируем с несуществующим значением
        String emptyStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'NonExistent');
        System.assertEquals('', emptyStatus, 'Should return empty string for non-existent value');
        
        // Тестируем с несуществующим полем
        String fieldStatus = LeadDeniedStatusConfig.getTargetStatus('NonExistentField', 'AnyValue');
        System.assertEquals('', fieldStatus, 'Should return empty string for non-existent field');
        
        // Тестируем с null значением
        String nullStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', null);
        System.assertEquals('', nullStatus, 'Should return empty string for null value');
    }
    
    @isTest
    static void testHasRule() {
        // Тестируем с существующим правилом
        Boolean hasRule = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', 'Black list');
        System.assertEquals(true, hasRule, 'Should return true for existing rule');
        
        // Тестируем с другим регистром
        Boolean hasRuleLower = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', 'black list');
        System.assertEquals(true, hasRuleLower, 'Should return true for black list');
        
        Boolean hasRuleUpper = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', 'BLACK LIST');
        System.assertEquals(true, hasRuleUpper, 'Should return true for BLACK LIST');
        
        // Тестируем с несуществующим правилом
        Boolean noRule = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', 'NonExistent');
        System.assertEquals(false, noRule, 'Should return false for non-existent rule');
        
        // Тестируем с несуществующим полем
        Boolean noField = LeadDeniedStatusConfig.hasRule('NonExistentField', 'AnyValue');
        System.assertEquals(false, noField, 'Should return false for non-existent field');
        
        // Тестируем с null значением
        Boolean nullRule = LeadDeniedStatusConfig.hasRule('Parsing_Status__c', null);
        System.assertEquals(false, nullRule, 'Should return false for null value');
    }
    
    @isTest
    static void testGetConfiguredFields() {
        // Тестируем получение настроенных полей
        Set<String> fields = LeadDeniedStatusConfig.getConfiguredFields();
        
        // Проверяем, что содержит нужное поле
        System.assert(fields.contains('Parsing_Status__c'), 'Should contain Parsing_Status__c field');
        
        // Проверяем, что не содержит несуществующее поле
        System.assert(!fields.contains('NonExistentField'), 'Should not contain non-existent field');
    }
    
    @isTest
    static void testGetRulesCount() {
        // Тестируем подсчет правил
        Integer rulesCount = LeadDeniedStatusConfig.getRulesCount();
        
        // Проверяем, что есть хотя бы одно правило
        System.assert(rulesCount > 0, 'Should have at least one rule');
        
        // Проверяем, что количество правил соответствует ожидаемому (3 для Parsing_Status__c)
        System.assertEquals(3, rulesCount, 'Should have exactly 3 rules for Parsing_Status__c');
    }
    
    @isTest
    static void testGetFieldValues() {
        // Тестируем получение значений для существующего поля
        List<String> values = LeadDeniedStatusConfig.getFieldValues('Parsing_Status__c');
        
        // Проверяем, что содержит нужные значения
        System.assert(values.contains('Black list'), 'Should contain Black list value');
        System.assert(values.contains('black list'), 'Should contain black list value');
        System.assert(values.contains('BLACK LIST'), 'Should contain BLACK LIST value');
        
        // Проверяем размер списка
        System.assertEquals(3, values.size(), 'Should have exactly 3 values');
        
        // Тестируем получение значений для несуществующего поля
        List<String> emptyValues = LeadDeniedStatusConfig.getFieldValues('NonExistentField');
        System.assertEquals(0, emptyValues.size(), 'Should return empty list for non-existent field');
    }
    
    @isTest
    static void testIsFieldConfigured() {
        // Тестируем с настроенным полем
        Boolean isConfigured = LeadDeniedStatusConfig.isFieldConfigured('Parsing_Status__c');
        System.assertEquals(true, isConfigured, 'Should return true for configured field');
        
        // Тестируем с ненастроенным полем
        Boolean notConfigured = LeadDeniedStatusConfig.isFieldConfigured('NonExistentField');
        System.assertEquals(false, notConfigured, 'Should return false for non-configured field');
        
        // Тестируем с null полем
        Boolean nullField = LeadDeniedStatusConfig.isFieldConfigured(null);
        System.assertEquals(false, nullField, 'Should return false for null field');
    }
    
    @isTest
    static void testCaseInsensitiveMatching() {
        // Тестируем регистронезависимое сравнение
        List<String> testValues = new List<String>{
            'Black list',
            'black list',
            'BLACK LIST',
            'Black List',
            'BLACK list',
            'black LIST'
        };
        
        for (String value : testValues) {
            String targetStatus = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', value);
            System.assertEquals('Final Denied', targetStatus, 
                'Should return Final Denied for value: ' + value);
        }
    }
    
    @isTest
    static void testEdgeCases() {
        // Тестируем граничные случаи
        
        // Пустая строка
        String emptyString = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', '');
        System.assertEquals('', emptyString, 'Should return empty string for empty value');
        
        // Пробелы
        String spaces = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', '   ');
        System.assertEquals('', spaces, 'Should return empty string for spaces only');
        
        // Специальные символы
        String specialChars = LeadDeniedStatusConfig.getTargetStatus('Parsing_Status__c', 'Black@list');
        System.assertEquals('', specialChars, 'Should return empty string for special characters');
    }
}