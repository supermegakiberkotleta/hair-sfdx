public with sharing class AutodialCampaignIterationController {

    public class IterationDTO {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal orderNumber { get; set; }
        @AuraEnabled public Datetime startDate { get; set; }
        @AuraEnabled public Datetime endDate { get; set; }
        @AuraEnabled public String phoneNumber { get; set; }
        @AuraEnabled public Decimal totalCalls { get; set; }
        @AuraEnabled public Decimal totalSuccessfulCalls { get; set; }
        @AuraEnabled public Decimal totalNoAnswerCalls { get; set; }
        @AuraEnabled public Decimal totalFailedCalls { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<IterationDTO> getIterations(Id campaignId) {
        if (campaignId == null) {
            return new List<IterationDTO>();
        }

        List<Autodial_CampaignIteration__c> raw = [
            SELECT Id,
                   Name,
                   Order__c,
                   Start_Date__c,
                   End_Date__c,
                   Number__c,
                   Total_Calls__c,
                   Total_Successful_Calls__c,
                   Total_No_Answer_Calls__c,
                   Total_Failed_Calls__c
            FROM Autodial_CampaignIteration__c
            WHERE Autodial_Campaign__c = :campaignId
            ORDER BY Order__c NULLS LAST, CreatedDate ASC
        ];

        // Enforce FLS: strip fields not accessible to running user
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, raw);
        List<Autodial_CampaignIteration__c> accessible = (List<Autodial_CampaignIteration__c>) decision.getRecords();

        List<IterationDTO> result = new List<IterationDTO>();
        for (Autodial_CampaignIteration__c it : accessible) {
            IterationDTO dto = new IterationDTO();
            dto.id = it.Id;
            dto.name = it.Name;
            dto.orderNumber = it.Order__c;
            dto.startDate = it.Start_Date__c;
            dto.endDate = it.End_Date__c;
            dto.phoneNumber = it.Number__c;
            dto.totalCalls = it.Total_Calls__c;
            dto.totalSuccessfulCalls = it.Total_Successful_Calls__c;
            dto.totalNoAnswerCalls = it.Total_No_Answer_Calls__c;
            dto.totalFailedCalls = it.Total_Failed_Calls__c;
            result.add(dto);
        }
        return result;
    }
}


