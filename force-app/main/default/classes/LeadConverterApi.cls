@RestResource(urlMapping='/LeadConverter')
global with sharing class LeadConverterApi {

    global class ConvertLeadRequest {
        public String leadId;
        public String accountId;
        public String contactId;
        public String convertedStatus;
        public Boolean doNotCreateOpportunity;
        public String opportunityId;
        public String opportunityName;
        public Boolean overwriteLeadSource;
        public String ownerId;
        public Boolean sendNotificationEmail;
    }

    global class ResponseWrapper {
        public Boolean success;
        public String message;
        public String accountId;
        public String contactId;
        public String opportunityId;
    }

    @HttpPost
    global static ResponseWrapper convertLead() {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String body = RestContext.request.requestBody.toString();
            ConvertLeadRequest req = (ConvertLeadRequest) JSON.deserialize(body, ConvertLeadRequest.class);

            if (String.isBlank(req.leadId) || String.isBlank(req.convertedStatus)) {
                response.success = false;
                response.message = 'leadId and convertedStatus are required.';
                return response;
            }

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(req.leadId);
            lc.setConvertedStatus(req.convertedStatus);

            if (req.accountId != null) lc.setAccountId(req.accountId);
            if (req.contactId != null) lc.setContactId(req.contactId);
            if (req.ownerId != null) lc.setOwnerId(req.ownerId);
            if (req.doNotCreateOpportunity != null) lc.setDoNotCreateOpportunity(req.doNotCreateOpportunity);
            if (req.opportunityId != null) lc.setOpportunityId(req.opportunityId);
            if (req.opportunityName != null) lc.setOpportunityName(req.opportunityName);
            if (req.overwriteLeadSource != null) lc.setOverwriteLeadSource(req.overwriteLeadSource);
            if (req.sendNotificationEmail != null) lc.setSendNotificationEmail(req.sendNotificationEmail);

            Database.LeadConvertResult result = Database.convertLead(lc);

            if (result.isSuccess()) {
                response.success = true;
                response.message = 'Lead converted successfully.';
                response.accountId = result.getAccountId();
                response.contactId = result.getContactId();
                response.opportunityId = result.getOpportunityId();
            } else {
                response.success = false;
                response.message = result.getErrors().isEmpty() ? 'Unknown error' : result.getErrors()[0].getMessage();
            }

        } catch (Exception e) {
            response.success = false;
            response.message = 'Exception: ' + e.getMessage();
        }

        return response;
    }
}