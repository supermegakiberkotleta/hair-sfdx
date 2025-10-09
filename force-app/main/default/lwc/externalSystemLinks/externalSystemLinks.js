import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const FIELDS = [
    'Account.Quickbooks_id__c',
    'Account.Zoho_Inventory_id__c'
];

export default class ExternalSystemLinks extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get quickbooksId() {
        return getFieldValue(this.account.data, 'Account.Quickbooks_id__c');
    }

    get zohoInventoryId() {
        return getFieldValue(this.account.data, 'Account.Zoho_Inventory_id__c');
    }

    get quickbooksUrl() {
        return this.quickbooksId 
            ? `https://qbo.intuit.com/app/customerdetail?nameId=${this.quickbooksId}`
            : null;
    }

    get zohoInventoryUrl() {
        return this.zohoInventoryId 
            ? `https://inventory.zoho.com/app/891723056#/contacts/${this.zohoInventoryId}`
            : null;
    }

    get hasAnyLink() {
        return this.quickbooksUrl || this.zohoInventoryUrl;
    }
}

