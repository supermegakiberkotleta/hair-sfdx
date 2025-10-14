public class AccountMarketingReportHandler {
    
    /**
     * Handles after insert event to create Marketing_Report_Customer__c records
     * @param newAccounts - List of accounts already filtered by RecordTypeId in trigger
     */
    public static void handleAfterInsert(List<Account> newAccounts) {
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        
        // Get lead creation dates for converted accounts
        Map<Id, Date> accountToLeadCreatedDateMap = getLeadCreatedDatesForAccounts(newAccounts);
        
        // Create Marketing_Report_Customer__c records
        List<Marketing_Report_Customer__c> reportsToInsert = new List<Marketing_Report_Customer__c>();
        
        for (Account acc : newAccounts) {
            Date leadCreatedDate = accountToLeadCreatedDateMap.get(acc.Id);
            
            if (leadCreatedDate != null) {
                Marketing_Report_Customer__c report = new Marketing_Report_Customer__c();
                report.Account__c = acc.Id;
                report.Date_Message__c = leadCreatedDate;
                report.Active__c = isActiveYear(leadCreatedDate);
                report.Month_Message__c = leadCreatedDate.month();
                report.Week_Message__c = getWeekNumber(leadCreatedDate);
                
                reportsToInsert.add(report);
            }
        }
        
        if (!reportsToInsert.isEmpty()) {
            insert reportsToInsert;
        }
    }
    
    /**
     * Handles before delete event to delete related Marketing_Report_Customer__c records
     * @param oldAccounts - List of accounts already filtered by RecordTypeId in trigger
     */
    public static void handleBeforeDelete(List<Account> oldAccounts) {
        if (oldAccounts == null || oldAccounts.isEmpty()) {
            return;
        }
        
        try {
            // Collect account IDs
            Set<Id> accountIdsToDelete = new Set<Id>();
            for (Account acc : oldAccounts) {
                accountIdsToDelete.add(acc.Id);
            }
            
            // Delete related Marketing_Report_Customer__c records
            List<Marketing_Report_Customer__c> reportsToDelete = [
                SELECT Id 
                FROM Marketing_Report_Customer__c 
                WHERE Account__c IN :accountIdsToDelete
            ];
            
            if (!reportsToDelete.isEmpty()) {
                delete reportsToDelete;
            }
        } catch (Exception e) {
            // Логируем ошибку, но не прерываем процесс удаления аккаунтов
            System.debug('Error deleting Marketing_Report_Customer__c records: ' + e.getMessage());
        }
    }
    
    /**
     * Gets lead created dates for accounts that were converted from leads
     */
    private static Map<Id, Date> getLeadCreatedDatesForAccounts(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Map<Id, Date> accountToLeadCreatedDateMap = new Map<Id, Date>();
        
        // Query leads that were converted to these accounts
        List<Lead> convertedLeads = [
            SELECT Id, CreatedDate, ConvertedAccountId 
            FROM Lead 
            WHERE ConvertedAccountId IN :accountIds 
            AND IsConverted = true
        ];
        
        for (Lead lead : convertedLeads) {
            accountToLeadCreatedDateMap.put(lead.ConvertedAccountId, lead.CreatedDate.date());
        }
        
        return accountToLeadCreatedDateMap;
    }
    
    /**
     * Checks if the year from the date matches the current year
     */
    private static Boolean isActiveYear(Date messageDate) {
        return messageDate.year() == Date.today().year();
    }
    
    /**
     * Calculates the week number of the year for a given date
     */
    private static Integer getWeekNumber(Date messageDate) {
        Date firstDayOfYear = Date.newInstance(messageDate.year(), 1, 1);
        Integer daysDifference = firstDayOfYear.daysBetween(messageDate);
        Integer weekNumber = (daysDifference / 7) + 1;
        return weekNumber;
    }
}

