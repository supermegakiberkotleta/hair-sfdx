public with sharing class AddAccountsToCampaignInvocable {
    public class Req {
        @InvocableVariable(required=true) public Id campaignId;
        @InvocableVariable(required=true) public List<Id> accountIds;
        @InvocableVariable public String status; // опц.: если не задано — возьмем дефолтный
    }
    
    public class Result {
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Add Accounts to Campaign')
    public static List<Result> addAccounts(List<Req> requests) {
        List<Result> results = new List<Result>();
        Result result = new Result();
        
        if (requests == null || requests.isEmpty()) {
            result.message = 'No requests to process';
            results.add(result);
            return results;
        }
        // соберем входные
        Set<Id> allAccountIds = new Set<Id>();
        Set<Id> campaignIds   = new Set<Id>();
        for (Req r : requests) {
            if (r == null) continue;
            if (r.campaignId != null) campaignIds.add(r.campaignId);
            if (r.accountIds != null) allAccountIds.addAll(r.accountIds);
        }
        if (campaignIds.isEmpty() || allAccountIds.isEmpty()) {
            result.message = 'No valid campaigns or accounts to process';
            results.add(result);
            return results;
        }

        // вытащим дефолтные статусы для кампаний
        Map<Id,String> campaignToDefaultStatus = new Map<Id,String>();
        for (CampaignMemberStatus cms : [
            SELECT CampaignId, Label, IsDefault
            FROM CampaignMemberStatus
            WHERE CampaignId IN :campaignIds AND IsDefault = true
        ]) {
            campaignToDefaultStatus.put(cms.CampaignId, cms.Label);
        }

        // соберем пары (CampaignId, AccountId), которые уже есть, чтобы не плодить дубликаты
        Set<Id> inputAccounts = new Set<Id>(allAccountIds);
        Map<Id, Set<Id>> existingAccByCamp = new Map<Id, Set<Id>>();
        for (CampaignMember cm : [
            SELECT CampaignId, AccountId
            FROM CampaignMember
            WHERE CampaignId IN :campaignIds AND AccountId IN :inputAccounts
        ]) {
            if (!existingAccByCamp.containsKey(cm.CampaignId)) {
                existingAccByCamp.put(cm.CampaignId, new Set<Id>());
            }
            existingAccByCamp.get(cm.CampaignId).add(cm.AccountId);
        }

        // подготовим вставку
        List<CampaignMember> toInsert = new List<CampaignMember>();
        Integer totalProcessed = 0;
        Integer totalSkipped = 0;
        
        for (Req r : requests) {
            if (r == null || r.campaignId == null || r.accountIds == null) continue;

            Set<Id> already = existingAccByCamp.containsKey(r.campaignId)
                ? existingAccByCamp.get(r.campaignId) : new Set<Id>();

            String statusToUse = (r.status != null && r.status.trim().length() > 0)
                ? r.status.trim()
                : campaignToDefaultStatus.get(r.campaignId);

            for (Id accId : r.accountIds) {
                totalProcessed++;
                if (accId == null || already.contains(accId)) {
                    totalSkipped++;
                    continue;
                }
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = r.campaignId;
                cm.AccountId  = accId;
                if (statusToUse != null) cm.Status = statusToUse;
                toInsert.add(cm);
                // локально отметим, чтобы не дублировать в пределах одной транзакции
                already.add(accId);
            }
        }

        Integer totalAdded = 0;
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] sr = Database.insert(toInsert, /*allOrNone*/ false);
            // подсчитываем успешно добавленные
            for (Integer i = 0; i < sr.size(); i++) {
                if (sr[i].isSuccess()) {
                    totalAdded++;
                } else {
                    totalSkipped++;
                    System.debug(LoggingLevel.WARN,
                        'Failed to add Account to Campaign: ' + sr[i].getErrors()[0].getMessage());
                }
            }
        }
        
        // формируем результат
        result.message = 'Processed accounts: ' + totalProcessed + 
                        ', added: ' + totalAdded + 
                        ', skipped: ' + totalSkipped;
        results.add(result);
        return results;
    }
}
