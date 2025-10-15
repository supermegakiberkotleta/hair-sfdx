@RestResource(urlMapping='/api/report-purchases/*')
global with sharing class ReportPurchasesController {
    
    @HttpPost
    global static void processPurchases() {
        try {
            // Получаем входящий запрос
            RestRequest request = RestContext.request;
            String requestBody = request.requestBody.toString();
            
            System.debug('=== ReportPurchasesController ===');
            System.debug('Request received at: ' + System.now());
            System.debug('Request Body: ' + requestBody);
            
            // Парсим JSON запрос
            Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            // Извлекаем данные из запроса
            String customerId = (String) requestData.get('customerId');
            Decimal budget = (Decimal) requestData.get('budget');
            Boolean active = (Boolean) requestData.get('active');
            Integer currentPage = (Integer) requestData.get('page');
            Integer totalPages = (Integer) requestData.get('totalPages');
            List<Object> purchases = (List<Object>) requestData.get('purchases');
            
            System.debug('Customer ID: ' + customerId);
            System.debug('Budget: ' + budget);
            System.debug('Active: ' + active);
            System.debug('Current Page: ' + currentPage + ' of ' + totalPages);
            System.debug('Purchases count: ' + (purchases != null ? purchases.size() : 0));
            
            // Обрабатываем покупки
            processPurchasesList(purchases, customerId);
            
            // Если это последняя страница, обновляем запись клиента
            if (currentPage != null && totalPages != null && currentPage >= totalPages) {
                updateCustomerRecord(customerId, budget, active);
            }
            
            // Возвращаем успешный ответ
            String response = JSON.serialize(new Map<String, Object>{
                'success' => true,
                'message' => 'Purchases processed successfully',
                'page' => currentPage,
                'totalPages' => totalPages,
                'processedCount' => purchases != null ? purchases.size() : 0
            });
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(response);
            
        } catch (Exception e) {
            System.debug('Error in ReportPurchasesController: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            String errorResponse = JSON.serialize(new Map<String, Object>{
                'success' => false,
                'error' => 'Internal server error: ' + e.getMessage()
            });
            
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(errorResponse);
        }
    }
    
    private static void processPurchasesList(List<Object> purchases, String customerId) {
        if (purchases == null || purchases.isEmpty()) {
            System.debug('No purchases to process');
            return;
        }
        
        List<Marketing_Report_Purchase__c> purchasesToInsert = new List<Marketing_Report_Purchase__c>();
        List<Marketing_Report_Purchase__c> purchasesToUpdate = new List<Marketing_Report_Purchase__c>();
        Set<String> existingPurchaseIds = new Set<String>();
        
        // Собираем ID существующих записей для обновления
        for (Object purchaseObj : purchases) {
            Map<String, Object> purchase = (Map<String, Object>) purchaseObj;
            String purchaseId = (String) purchase.get('Id');
            if (String.isNotBlank(purchaseId)) {
                existingPurchaseIds.add(purchaseId);
            }
        }
        
        // Получаем существующие записи для обновления
        Map<String, Marketing_Report_Purchase__c> existingPurchasesMap = new Map<String, Marketing_Report_Purchase__c>();
        if (!existingPurchaseIds.isEmpty()) {
            List<Marketing_Report_Purchase__c> existingPurchases = [
                SELECT Id, Purchase_Amount__c, Date_Buy__c, Month_Buy__c, Week_Buy__c
                FROM Marketing_Report_Purchase__c
                WHERE Id IN :existingPurchaseIds
            ];
            
            for (Marketing_Report_Purchase__c existing : existingPurchases) {
                existingPurchasesMap.put(existing.Id, existing);
            }
        }
        
        // Обрабатываем каждую покупку
        for (Object purchaseObj : purchases) {
            Map<String, Object> purchase = (Map<String, Object>) purchaseObj;
            String purchaseId = (String) purchase.get('Id');
            
            if (String.isNotBlank(purchaseId) && existingPurchasesMap.containsKey(purchaseId)) {
                // Обновляем существующую запись
                Marketing_Report_Purchase__c existingPurchase = existingPurchasesMap.get(purchaseId);
                updatePurchaseRecord(existingPurchase, purchase);
                purchasesToUpdate.add(existingPurchase);
            } else {
                // Создаем новую запись
                Marketing_Report_Purchase__c newPurchase = createPurchaseRecord(purchase, customerId);
                purchasesToInsert.add(newPurchase);
            }
        }
        
        // Выполняем операции с базой данных
        if (!purchasesToInsert.isEmpty()) {
            insert purchasesToInsert;
            System.debug('Inserted ' + purchasesToInsert.size() + ' new purchase records');
        }
        
        if (!purchasesToUpdate.isEmpty()) {
            update purchasesToUpdate;
            System.debug('Updated ' + purchasesToUpdate.size() + ' existing purchase records');
        }
    }
    
    private static Marketing_Report_Purchase__c createPurchaseRecord(Map<String, Object> purchase, String customerId) {
        Marketing_Report_Purchase__c newPurchase = new Marketing_Report_Purchase__c();
        
        // Устанавливаем связь с клиентом
        newPurchase.Marketing_Report_Customer__c = customerId;
        
        // Заполняем поля из JSON
        if (purchase.containsKey('Purchase_Amount__c')) {
            newPurchase.Purchase_Amount__c = (Decimal) purchase.get('Purchase_Amount__c');
        }
        
        if (purchase.containsKey('Date_Buy__c')) {
            String dateStr = (String) purchase.get('Date_Buy__c');
            if (String.isNotBlank(dateStr)) {
                newPurchase.Date_Buy__c = Date.valueOf(dateStr);
            }
        }
        
        if (purchase.containsKey('Month_Buy__c')) {
            newPurchase.Month_Buy__c = (Integer) purchase.get('Month_Buy__c');
        }
        
        if (purchase.containsKey('Week_Buy__c')) {
            newPurchase.Week_Buy__c = (Integer) purchase.get('Week_Buy__c');
        }
        
        return newPurchase;
    }
    
    private static void updatePurchaseRecord(Marketing_Report_Purchase__c existingPurchase, Map<String, Object> purchase) {
        // Обновляем только пришедшие поля
        if (purchase.containsKey('Purchase_Amount__c')) {
            existingPurchase.Purchase_Amount__c = (Decimal) purchase.get('Purchase_Amount__c');
        }
        
        if (purchase.containsKey('Date_Buy__c')) {
            String dateStr = (String) purchase.get('Date_Buy__c');
            if (String.isNotBlank(dateStr)) {
                existingPurchase.Date_Buy__c = Date.valueOf(dateStr);
            }
        }
        
        if (purchase.containsKey('Month_Buy__c')) {
            existingPurchase.Month_Buy__c = (Integer) purchase.get('Month_Buy__c');
        }
        
        if (purchase.containsKey('Week_Buy__c')) {
            existingPurchase.Week_Buy__c = (Integer) purchase.get('Week_Buy__c');
        }
    }
    
    private static void updateCustomerRecord(String customerId, Decimal budget, Boolean active) {
        if (String.isBlank(customerId)) {
            System.debug('Customer ID is blank, skipping customer update');
            return;
        }
        
        try {
            Marketing_Report_Customer__c customer = [
                SELECT Id, Budget__c, Active__c
                FROM Marketing_Report_Customer__c
                WHERE Id = :customerId
                LIMIT 1
            ];
            
            Boolean needsUpdate = false;
            
            if (budget != null && customer.Budget__c != budget) {
                customer.Budget__c = budget;
                needsUpdate = true;
            }
            
            if (active != null && customer.Active__c != active) {
                customer.Active__c = active;
                needsUpdate = true;
            }
            
            if (needsUpdate) {
                update customer;
                System.debug('Updated customer record: ' + customerId);
            }
            
        } catch (QueryException e) {
            System.debug('Customer not found: ' + customerId + ', error: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Error updating customer record: ' + e.getMessage());
        }
    }
    
    @HttpGet
    global static void getPurchaseInfo() {
        try {
            RestRequest request = RestContext.request;
            
            System.debug('=== GET Request to ReportPurchasesController ===');
            System.debug('Request URI: ' + request.requestURI);
            System.debug('Request Parameters: ' + request.params);
            
            String response = JSON.serialize(new Map<String, Object>{
                'message' => 'ReportPurchasesController is active',
                'timestamp' => System.now().format(),
                'version' => '1.0'
            });
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(response);
            
        } catch (Exception e) {
            System.debug('Error in GET ReportPurchasesController: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Internal server error"}');
        }
    }
}
