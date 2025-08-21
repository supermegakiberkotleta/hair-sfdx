trigger CreateLeadTrigger on Lead (after insert,after update) {
    if(System.IsBatch() == false && System.isFuture() == false){
        List<Map<String, Object>> leadsToSend = new List<Map<String, Object>>();
    
        System.debug('Лид ' + lead.Id + ' добавлен или изменен');

        for(Lead lead: Trigger.new) {
            Map<String, Object> leadData = new Map<String, Object>{
                'Id' => lead.Id,
                'LastName' => lead.LastName,
                'Broker_email__c' => lead.Broker_email__c,
                'RecordTypeId' => lead.RecordTypeId,
                'Lead_type_a__c' => lead.Lead_type_a__c,
                'Company' => lead.Company,
                'Ownership__c' => lead.Ownership__c,
                'Industry__c' => lead.Industry__c,
                'FILE__c' => lead.FILE__c,
                'Term__c' => lead.Term__c,
                'Buyrate__c' => lead.Buyrate__c,
                'SSN__c' => lead.SSN__c,
                'EIN__c' => lead.EIN__c,
                'State__c' => lead.State__c,
                'Start_date__c' => lead.Start_date__c,
                'uuid__c' => lead.uuid__c,
                'MaxDailyPayment__c' => lead.MaxDailyPayment__c,
                'Payment_Frequency__c' => lead.Payment_Frequency__c,
                'Max_Existing_MCA_Positions__c' => lead.Max_Existing_MCA_Positions__c,
                'Routing_Number__c' => lead.Routing_Number__c,
                'Account_Number__c' => lead.Account_Number__c,
                'Industry_type__c' => lead.Industry_type__c,
                'Loan_Start_Date__c' => lead.Loan_Start_Date__c,
                'Min_Single_Month_Revenue__c' => lead.Min_Single_Month_Revenue__c,
                'Avg_Monthly_Revenue__c' => lead.Avg_Monthly_Revenue__c,
                'Last_Monthly_Revenue__c' => lead.Last_Monthly_Revenue__c,
                'Min_Monthly_Deposit_Count__c' => lead.Min_Monthly_Deposit_Count__c,
                'Max_Leverage__c' => lead.Max_Leverage__c,
                'Max_Existing_MCA_Positions__c' => lead.Max_Existing_MCA_Positions__c,
                'Adjusted_Payments__c' => lead.Adjusted_Payments__c,
                'Paying_Collections_Company__c' => lead.Paying_Collections_Company__c,
                'Stopped_Payment_on_MCA_company__c' => lead.Stopped_Payment_on_MCA_company__c,
                'Reverse_payment__c' => lead.Reverse_payment__c,
                'Max_MCA_Payment_Bounces_daily__c' => lead.Max_MCA_Payment_Bounces_daily__c,
                'Max_MCA_Payment_Bounces_weekly__c' => lead.Max_MCA_Payment_Bounces_weekly__c,
                'NegativeBalanceDaysLastMonth' => lead.Negative_Balance_Days_Last_Month__c,
                'Low_Balance_Days_including_neg_days_LM__c' => lead.Low_Balance_Days_including_neg_days_LM__c,
                'NSF_charge_Overdraft__c' => lead.NSF_charge_Overdraft__c,
                'Altered_Edited_Statements__c' => lead.Altered_Edited_Statements__c,
                'OfferAmount__c' => lead.OfferAmount__c,
                'Status' => lead.Status,
                'Parsing_Status__c'=>lead.Parsing_Status__c,
                'Tag__c'=>lead.Tag__c,
                'Lender_type__c'=>lead.Lender_type__c,
                'PurchasePrice__c'=>lead.PurchasePrice__c,
                'Purchase_Price_Term_2__c'=>lead.Purchase_Price_Term_2__c,
                'Origination_Fee_Offer__c'=>lead.Origination_Fee_Offer__c,
                'Origination_Fee_Term_2__c'=>lead.Origination_Fee_Term_2__c,
                'UCC_fee_term_1__c'=>lead.UCC_fee_term_1__c,
                'UCC_fee_term_2__c'=>lead.UCC_fee_term_2__c,
                'Wire_fee_term_1__c'=>lead.Wire_fee_term_1__c,
                'Wire_fee_term_2__c'=>lead.Wire_fee_term_2__c,
                'Net_Funding_Amount__c'=>lead.Net_Funding_Amount__c,
                'Net_Funding_Amount_term_2__c'=>lead.Net_Funding_Amount_term_2__c,
                'Term_2__c'=>lead.Term_2__c,
                'DailyPayment__c'=>lead.DailyPayment__c,
                'Daily_Payment_term_2__c'=>lead.Daily_Payment_term_2__c,
                'Your_Commission__c'=>lead.Your_Commission__c,
                'Your_Commission_term_2__c'=>lead.Your_Commission_term_2__c,
                'Purchased_Amount_Future__c'=>lead.Purchased_Amount_Future__c,
                'Purchased_Amount_Future_term_2__c'=>lead.Purchased_Amount_Future_term_2__c,
                'Specified_percentage__c'=>lead.Specified_percentage__c,
                'Specified_percentage_term_2__c'=>lead.Specified_percentage_term_2__c,
                'FactorRate__c'=>lead.FactorRate__c,
                'Factor_Rate_term_2__c'=>lead.Factor_Rate_term_2__c,
                'BrokersFee__c'=>lead.BrokersFee__c,
                'Brokers_Fee_term_2__c'=>lead.Brokers_Fee_term_2__c,
                'Mail_Theme__c'=>lead.Mail_Theme__c,
                'Datamerch__c'=>lead.Datamerch__c,
                'Client_email__c'=>lead.Client_email__c,
                'Phone_number_a__c'=>lead.Phone_number_a__c
            };

            leadsToSend.add(leadData);
        }

        String payload = JSON.serialize(leadsToSend);

        CreateLeadTriggerHandler.sendLeadDataToExternalService(payload);
    }
    
}