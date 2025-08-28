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

	public class ContactRow {
		@AuraEnabled public Id id;
		@AuraEnabled public String name;
		@AuraEnabled public String accountName;
		@AuraEnabled public String phone;
		@AuraEnabled public String email;
		@AuraEnabled public String ownerName;

		public ContactRow(Contact c) {
			this.id = c.Id;
			this.name = c.Name;
			this.accountName = (c.Account != null) ? c.Account.Name : null;
			this.phone = c.Phone;
			this.email = c.Email;
			this.ownerName = (c.Owner != null) ? c.Owner.Name : null;
		}
	}

	public class AccountRow {
		@AuraEnabled public Id id;
		@AuraEnabled public String name;
		@AuraEnabled public String phone;
		@AuraEnabled public String ownerName;

		public AccountRow(Account a) {
			this.id = a.Id;
			this.name = a.Name;
			this.phone = a.Phone;
			this.ownerName = (a.Owner != null) ? a.Owner.Name : null;
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

	@AuraEnabled(cacheable=true)
	public static List<ContactRow> searchContacts(String searchText, Integer limitSize) {
		Integer effLimit = (limitSize == null || limitSize <= 0) ? 50 : Math.min(limitSize, 200);
		String term = (searchText == null) ? '' : searchText.trim();
		String searchPattern = '%' + String.escapeSingleQuotes(term) + '%';

		List<Contact> contacts = [
			SELECT Id, Name, Account.Name, Phone, Email, Owner.Name
			FROM Contact
			WHERE (
				Name LIKE :searchPattern OR Account.Name LIKE :searchPattern OR Email LIKE :searchPattern OR Phone LIKE :searchPattern
			)
			ORDER BY LastModifiedDate DESC
			LIMIT :effLimit
		];

		List<ContactRow> rows = new List<ContactRow>();
		for (Contact c : contacts) {
			rows.add(new ContactRow(c));
		}
		return rows;
	}

	@AuraEnabled(cacheable=true)
	public static List<AccountRow> searchAccounts(String searchText, Integer limitSize) {
		Integer effLimit = (limitSize == null || limitSize <= 0) ? 50 : Math.min(limitSize, 200);
		String term = (searchText == null) ? '' : searchText.trim();
		String searchPattern = '%' + String.escapeSingleQuotes(term) + '%';

		List<Account> accounts = [
			SELECT Id, Name, Phone, Owner.Name
			FROM Account
			WHERE (
				Name LIKE :searchPattern OR Phone LIKE :searchPattern
			)
			ORDER BY LastModifiedDate DESC
			LIMIT :effLimit
		];

		List<AccountRow> rows = new List<AccountRow>();
		for (Account a : accounts) {
			rows.add(new AccountRow(a));
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

		// Dynamic approach to avoid compile-time dependency on object API
		Set<Id> leadIdSet = new Set<Id>(leadIds);
		Map<Id, Boolean> existingByLead = new Map<Id, Boolean>();
		for (SObject sob : Database.query('SELECT Id, Lead__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Lead__c IN :leadIdSet')) {
			existingByLead.put((Id)sob.get('Lead__c'), true);
		}

		List<SObject> toInsert = new List<SObject>();
		Schema.SObjectType sObjType = Schema.getGlobalDescribe().get('Autodial_CampaignMembers__c');
		if (sObjType == null) {
			res.message = 'Object Autodial_CampaignMembers__c not found.';
			return res;
		}
		Schema.SObjectField campField = sObjType.getDescribe().fields.getMap().get('Autodial_Campaign__c');
		Schema.SObjectField leadField = sObjType.getDescribe().fields.getMap().get('Lead__c');
		for (Id lid : leadIdSet) {
			if (!existingByLead.containsKey(lid)) {
				SObject rec = sObjType.newSObject();
				rec.put(campField, campaignId);
				rec.put(leadField, lid);
				toInsert.add(rec);
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

	@AuraEnabled
	public static AddMembersResult addMembersGeneric(Id campaignId, String entityType, List<Id> recordIds) {
		AddMembersResult res = new AddMembersResult();
		res.success = false;
		res.createdCount = 0;
		res.skippedCount = 0;
		res.message = '';

		if (campaignId == null || String.isBlank(entityType) || recordIds == null || recordIds.isEmpty()) {
			res.message = 'Campaign, Entity Type and at least one Id are required.';
			return res;
		}

		String et = entityType.trim().toLowerCase();
		Set<Id> ids = new Set<Id>(recordIds);

		Schema.SObjectType cmType = Schema.getGlobalDescribe().get('Autodial_CampaignMembers__c');
		if (cmType == null) {
			res.message = 'Object Autodial_CampaignMembers__c not found.';
			return res;
		}
		List<SObject> toInsert = new List<SObject>();

		if (et == 'lead') {
			Map<Id, Boolean> existing = new Map<Id, Boolean>();
			for (SObject sob : Database.query('SELECT Id, Lead__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Lead__c IN :ids')) {
				existing.put((Id)sob.get('Lead__c'), true);
			}
			for (Id idVal : ids) {
				if (!existing.containsKey(idVal)) {
					SObject rec = cmType.newSObject();
					rec.put('Autodial_Campaign__c', campaignId);
					rec.put('Lead__c', idVal);
					toInsert.add(rec);
				} else {
					res.skippedCount++;
				}
			}
		} else if (et == 'contact') {
			Map<Id, Boolean> existing = new Map<Id, Boolean>();
			for (SObject sob : Database.query('SELECT Id, Contact__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Contact__c IN :ids')) {
				existing.put((Id)sob.get('Contact__c'), true);
			}
			for (Id idVal : ids) {
				if (!existing.containsKey(idVal)) {
					SObject rec = cmType.newSObject();
					rec.put('Autodial_Campaign__c', campaignId);
					rec.put('Contact__c', idVal);
					toInsert.add(rec);
				} else {
					res.skippedCount++;
				}
			}
		} else if (et == 'account') {
			Map<Id, Boolean> existing = new Map<Id, Boolean>();
			for (SObject sob : Database.query('SELECT Id, Account__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Account__c IN :ids')) {
				existing.put((Id)sob.get('Account__c'), true);
			}
			for (Id idVal : ids) {
				if (!existing.containsKey(idVal)) {
					SObject rec = cmType.newSObject();
					rec.put('Autodial_Campaign__c', campaignId);
					rec.put('Account__c', idVal);
					toInsert.add(rec);
				} else {
					res.skippedCount++;
				}
			}
		} else {
			res.message = 'Unsupported entity type: ' + entityType;
			return res;
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