@isTest
public class LeadDeniedStatusConfigTest {
    
    @isTest
    static void testGetFieldValuesConfig() {
        // Тестируем получение конфигурации
        Map<String, List<String>> config = LeadDeniedStatusConfig.getFieldValuesConfig();
        
        // Проверяем, что конфигурация не null
        System.assertNotEquals(null, config, 'Config should not be null');
        
        // Проверяем, что содержит нужное поле
        System.assert(config.containsKey('ClosingReasonNew__c'), 'Should contain ClosingReasonNew__c field');
        
        // Проверяем, что поле содержит нужные значения
        List<String> values = config.get('ClosingReasonNew__c');
        System.assert(values.contains('Black list'), 'Should contain Black list value');
        System.assert(values.contains('Unacceptable Banks'), 'Should contain Unacceptable Banks value');
        System.assert(values.contains('Must be Business/Commercial Checking Account'), 'Should contain Must be Business/Commercial Checking Account value');
        System.assert(values.contains('No statement'), 'Should contain No statement value');
    }
    
    @isTest
    static void testGetTargetStatus() {
        // Тестируем с существующим значением
        String targetStatus = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', 'Black list');
        System.assertEquals('Final Denied', targetStatus, 'Should return Final Denied for Black list');
        
        // Тестируем с другим регистром
        String lowerCaseStatus = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', 'Unacceptable Banks');
        System.assertEquals('Final Denied', lowerCaseStatus, 'Should return Final Denied for Unacceptable Banks');
        
        String upperCaseStatus = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', 'Must be Business/Commercial Checking Account');
        System.assertEquals('Final Denied', upperCaseStatus, 'Should return Final Denied for Must be Business/Commercial Checking Account');
        
        // Тестируем с несуществующим значением
        String emptyStatus = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', 'NonExistent');
        System.assertEquals('', emptyStatus, 'Should return empty string for non-existent value');
        
        // Тестируем с несуществующим полем
        String fieldStatus = LeadDeniedStatusConfig.getTargetStatus('NonExistentField', 'Avg Monthly Revenue');
        System.assertEquals('', fieldStatus, 'Should return empty string for non-existent field');
        
        // Тестируем с null значением
        String nullStatus = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', '');
        System.assertEquals('', nullStatus, 'Should return empty string for null value');
    }
    
    @isTest
    static void testHasRule() {
        // Тестируем с существующим правилом
        Boolean hasRule = LeadDeniedStatusConfig.hasRule('ClosingReasonNew__c', 'Black list');
        System.assertEquals(true, hasRule, 'Should return true for existing rule');
        
        // Тестируем с другим регистром
        Boolean hasRuleLower = LeadDeniedStatusConfig.hasRule('ClosingReasonNew__c', 'Unacceptable Banks');
        System.assertEquals(true, hasRuleLower, 'Should return true for Unacceptable Banks');
        
        Boolean hasRuleUpper = LeadDeniedStatusConfig.hasRule('ClosingReasonNew__c', 'Must be Business/Commercial Checking Account');
        System.assertEquals(true, hasRuleUpper, 'Should return true for Must be Business/Commercial Checking Account');
        
        // Тестируем с несуществующим правилом
        Boolean noRule = LeadDeniedStatusConfig.hasRule('ClosingReasonNew__c', 'NonExistent');
        System.assertEquals(false, noRule, 'Should return false for non-existent rule');
        
        // Тестируем с несуществующим полем
        Boolean noField = LeadDeniedStatusConfig.hasRule('NonExistentField', 'Avg Monthly Revenue');
        System.assertEquals(false, noField, 'Should return false for non-existent field');
        
        // Тестируем с null значением
        Boolean nullRule = LeadDeniedStatusConfig.hasRule('ClosingReasonNew__c', '');
        System.assertEquals(false, nullRule, 'Should return false for null value');
    }
    
    @isTest
    static void testGetConfiguredFields() {
        // Тестируем получение настроенных полей
        Set<String> fields = LeadDeniedStatusConfig.getConfiguredFields();
        
        // Проверяем, что содержит нужное поле
        System.assert(fields.contains('ClosingReasonNew__c'), 'Should contain ClosingReasonNew__c field');
        
        // Проверяем, что не содержит несуществующее поле
        System.assert(!fields.contains('NonExistentField'), 'Should not contain non-existent field');
    }
    
    @isTest
    static void testGetRulesCount() {
        // Тестируем подсчет правил
        Integer rulesCount = LeadDeniedStatusConfig.getRulesCount();
        
        // Проверяем, что есть хотя бы одно правило
        System.assert(rulesCount > 0, 'Should have at least one rule');
        
        // Проверяем, что количество правил соответствует ожидаемому (4 для ClosingReasonNew__c)
        System.assertEquals(4, rulesCount, 'Should have exactly 4 rules for ClosingReasonNew__c');
    }
    
    @isTest
    static void testGetFieldValues() {
        // Тестируем получение значений для существующего поля
        List<String> values = LeadDeniedStatusConfig.getFieldValues('ClosingReasonNew__c');
        
        // Проверяем, что содержит нужные значения
        System.assert(values.contains('Black list'), 'Should contain Black list value');
        System.assert(values.contains('Unacceptable Banks'), 'Should contain Unacceptable Banks value');
        System.assert(values.contains('Must be Business/Commercial Checking Account'), 'Should contain Must be Business/Commercial Checking Account value');
        System.assert(values.contains('No statement'), 'Should contain No statement value');
        
        // Проверяем размер списка
        System.assertEquals(4, values.size(), 'Should have exactly 4 values');
        
        // Тестируем получение значений для несуществующего поля
        List<String> emptyValues = LeadDeniedStatusConfig.getFieldValues('NonExistentField');
        System.assertEquals(0, emptyValues.size(), 'Should return empty list for non-existent field');
    }
    
    @isTest
    static void testIsFieldConfigured() {
        // Тестируем с настроенным полем
        Boolean isConfigured = LeadDeniedStatusConfig.isFieldConfigured('ClosingReasonNew__c');
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
            'Unacceptable Banks',
            'Must be Business/Commercial Checking Account',
            'No statement'
        };
        
        for (String value : testValues) {
            String targetStatus = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', value);
            System.assertEquals('Final Denied', targetStatus, 
                'Should return Final Denied for value: ' + value);
        }
    }
    
    @isTest
    static void testEdgeCases() {
        // Тестируем граничные случаи
        
        // Пустая строка
        String emptyString = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', '');
        System.assertEquals('', emptyString, 'Should return empty string for empty value');
        
        // Пробелы
        String spaces = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', '   ');
        System.assertEquals('', spaces, 'Should return empty string for spaces only');
        
        // Специальные символы
        String specialChars = LeadDeniedStatusConfig.getTargetStatus('ClosingReasonNew__c', 'Avg Monthly Revenue');
        System.assertEquals('', specialChars, 'Should return empty string for special characters');
    }
}