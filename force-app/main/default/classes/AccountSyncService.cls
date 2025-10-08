public class AccountSyncService {
    private static final String ENDPOINT_URL = 'https://hair.lenderpro.ai/api/account-sync';
    
    /**
     * Синхронизирует аккаунты с внешним API
     * @param accountIds список ID аккаунтов для синхронизации
     */
    public static void syncAccounts(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        try {
            // Отправляем данные асинхронно (передаем только Id)
            sendAccountsAsync(accountIds);
            
        } catch (Exception e) {
            System.debug('Error in syncAccounts: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Получает данные аккаунтов из базы
     */
    private static List<Account> getAccountsData(List<Id> accountIds) {
        return [
            SELECT Id, 
                   Name, 
                   Phone, 
                   Work_Email__c, 
                   Client_Category__c, 
                   Client_Type__c, 
                   AccountSource,
                   BillingStreet,
                   BillingCity,
                   BillingState,
                   BillingPostalCode,
                   BillingCountry
            FROM Account 
            WHERE Id IN :accountIds
        ];
    }
    
    /**
     * Подготавливает данные аккаунтов для отправки
     */
    private static List<Map<String, Object>> prepareAccountsData(List<Account> accounts) {
        List<Map<String, Object>> accountsData = new List<Map<String, Object>>();
        
        for (Account acc : accounts) {
            Map<String, Object> accountData = new Map<String, Object>();
            accountData.put('Id', acc.Id);
            accountData.put('Name', acc.Name);
            accountData.put('Phone', acc.Phone);
            accountData.put('Work_Email__c', acc.Work_Email__c);
            accountData.put('Client_Category__c', acc.Client_Category__c);
            accountData.put('Client_Type__c', acc.Client_Type__c);
            accountData.put('AccountSource', acc.AccountSource);
            
            // Формируем BillingAddress
            Map<String, String> billingAddress = new Map<String, String>();
            billingAddress.put('street', acc.BillingStreet);
            billingAddress.put('city', acc.BillingCity);
            billingAddress.put('state', acc.BillingState);
            billingAddress.put('postalCode', acc.BillingPostalCode);
            billingAddress.put('country', acc.BillingCountry);
            accountData.put('BillingAddress', billingAddress);
            
            accountsData.add(accountData);
        }
        
        return accountsData;
    }
    
    /**
     * Отправляет данные на внешний API асинхронно
     */
    @future(callout=true)
    private static void sendAccountsAsync(List<Id> accountIds) {
        try {
            // Получаем данные аккаунтов с необходимыми полями
            List<Account> accounts = getAccountsData(accountIds);
            
            if (accounts.isEmpty()) {
                return;
            }
            
            // Подготавливаем данные для отправки
            List<Map<String, Object>> accountsData = prepareAccountsData(accounts);
            String jsonBody = JSON.serialize(accountsData);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(120000); // 120 секунд
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Логируем результат
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                System.debug('Error sending accounts: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Error in sendAccountsAsync: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Синхронный метод отправки (используется для тестов)
     */
    @TestVisible
    private static HttpResponse sendAccountsSync(List<Map<String, Object>> accountsData) {
        String jsonBody = JSON.serialize(accountsData);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        req.setTimeout(120000);
        
        Http http = new Http();
        return http.send(req);
    }
}

