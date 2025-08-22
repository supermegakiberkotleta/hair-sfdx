public with sharing class AutodialCampaignMemberController {

	public class LeadRow {
		@AuraEnabled public Id id;
		@AuraEnabled public String name;
		@AuraEnabled public String company;
		@AuraEnabled public String phone;
		@AuraEnabled public String email;
		@AuraEnabled public String status;
		@AuraEnabled public String ownerName;

		public LeadRow(Lead l) {
			this.id = l.Id;
			this.name = l.Name;
			this.company = l.Company;
			this.phone = l.Phone;
			this.email = l.Email;
			this.status = l.Status;
			this.ownerName = (l.Owner != null) ? l.Owner.Name : null;
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<LeadRow> searchLeads(String searchText, Integer limitSize) {
		Integer effLimit = (limitSize == null || limitSize <= 0) ? 50 : Math.min(limitSize, 200);
		String term = (searchText == null) ? '' : searchText.trim();
		String searchPattern = '%' + String.escapeSingleQuotes(term) + '%';

		List<Lead> leads = [
			SELECT Id, Name, Company, Phone, Email, Status, Owner.Name
			FROM Lead
			WHERE (
				Name LIKE :searchPattern OR Company LIKE :searchPattern OR Email LIKE :searchPattern OR Phone LIKE :searchPattern
			)
			ORDER BY LastModifiedDate DESC
			LIMIT :effLimit
		];

		List<LeadRow> rows = new List<LeadRow>();
		for (Lead l : leads) {
			rows.add(new LeadRow(l));
		}
		return rows;
	}

	public class AddMembersResult {
		@AuraEnabled public Boolean success;
		@AuraEnabled public Integer createdCount;
		@AuraEnabled public Integer skippedCount;
		@AuraEnabled public String message;
	}

	@AuraEnabled
	public static AddMembersResult addMembers(Id campaignId, List<Id> leadIds) {
		AddMembersResult res = new AddMembersResult();
		res.success = false;
		res.createdCount = 0;
		res.skippedCount = 0;
		res.message = '';

		if (campaignId == null || leadIds == null || leadIds.isEmpty()) {
			res.message = 'Campaign and at least one Lead are required.';
			return res;
		}

		// Find existing members to avoid duplicates
		Set<Id> leadIdSet = new Set<Id>(leadIds);
		Map<Id, Boolean> existingByLead = new Map<Id, Boolean>();
		for (Autodial_CampaignMembers__c m : [
			SELECT Id, Lead__c
			FROM Autodial_CampaignMembers__c
			WHERE Autodial_Campaign__c = :campaignId AND Lead__c IN :leadIdSet
		]) {
			existingByLead.put(m.Lead__c, true);
		}

		List<Autodial_CampaignMembers__c> toInsert = new List<Autodial_CampaignMembers__c>();
		for (Id lid : leadIdSet) {
			if (!existingByLead.containsKey(lid)) {
				toInsert.add(new Autodial_CampaignMembers__c(
					Autodial_Campaign__c = campaignId,
					Lead__c = lid
				));
			} else {
				res.skippedCount++;
			}
		}

		if (!toInsert.isEmpty()) {
			insert toInsert;
			res.createdCount = toInsert.size();
		}

		res.success = true;
		res.message = 'Added ' + res.createdCount + ' member(s); skipped ' + res.skippedCount + '.';
		return res;
	}
}


