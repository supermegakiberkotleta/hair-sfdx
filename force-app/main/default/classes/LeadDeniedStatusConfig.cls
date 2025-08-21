public class LeadDeniedStatusConfig {
    
    // Конфигурация полей и значений для перевода в Final Denied
    // Легко добавлять, удалять или изменять правила
    private static final Map<String, List<String>> FIELD_VALUES_CONFIG = new Map<String, List<String>>{
        'ClosingReasonNew__c' => new List<String>{
            'Black list',
            'Unacceptable Banks', 
            'Must be Business/Commercial Checking Account',
            'No statement'
        }
        // Пример добавления других полей:
        // 'Company' => new List<String>{
        //     'Test Company',
        //     'Blocked Company'
        // },
        // 'Industry__c' => new List<String>{
        //     'Technology',
        //     'Finance'
        // }
    };
    
    /**
     * Получает конфигурацию для проверки полей лидов
     * @return Map с конфигурацией полей и значений
     */
    public static Map<String, List<String>> getFieldValuesConfig() {
        return FIELD_VALUES_CONFIG;
    }
    
    /**
     * Целевой статус для всех правил
     */
    private static final String TARGET_STATUS = 'Final Denied';
    
    /**
     * Получает целевой статус для заданного поля и значения
     * @param fieldName - имя поля
     * @param fieldValue - значение поля
     * @return целевой статус или пустая строка, если правило не найдено
     */
    public static String getTargetStatus(String fieldName, String fieldValue) {
        // Проверяем, что fieldValue не null
        if (fieldValue == null) {
            return '';
        }
        
        Map<String, List<String>> config = getFieldValuesConfig();
        
        if (config.containsKey(fieldName)) {
            List<String> values = config.get(fieldName);
            
            // Проверяем содержание значения (регистронезависимо)
            for (String configValue : values) {
                if (fieldValue.containsIgnoreCase(configValue)) {
                    return TARGET_STATUS;
                }
            }
        }
        
        return '';
    }
    
    /**
     * Проверяет, есть ли правило для заданного поля и значения
     * @param fieldName - имя поля
     * @param fieldValue - значение поля
     * @return true, если правило существует
     */
    public static Boolean hasRule(String fieldName, String fieldValue) {
        return String.isNotBlank(getTargetStatus(fieldName, fieldValue));
    }
    
    /**
     * Получает список всех полей в конфигурации
     * @return Set имен полей
     */
    public static Set<String> getConfiguredFields() {
        return getFieldValuesConfig().keySet();
    }
    
    /**
     * Получает количество правил в конфигурации
     * @return количество правил
     */
    public static Integer getRulesCount() {
        Map<String, List<String>> config = getFieldValuesConfig();
        Integer count = 0;
        
        for (String fieldName : config.keySet()) {
            count += config.get(fieldName).size();
        }
        
        return count;
    }
    
    /**
     * Получает все значения для конкретного поля
     * @param fieldName - имя поля
     * @return список значений или пустой список
     */
    public static List<String> getFieldValues(String fieldName) {
        // Проверяем, что fieldName не null
        if (fieldName == null) {
            return new List<String>();
        }
        
        Map<String, List<String>> config = getFieldValuesConfig();
        return config.containsKey(fieldName) ? config.get(fieldName) : new List<String>();
    }
    
    /**
     * Проверяет, настроено ли поле в конфигурации
     * @param fieldName - имя поля
     * @return true, если поле настроено
     */
    public static Boolean isFieldConfigured(String fieldName) {
        // Проверяем, что fieldName не null
        if (fieldName == null) {
            return false;
        }
        
        return getFieldValuesConfig().containsKey(fieldName);
    }
}