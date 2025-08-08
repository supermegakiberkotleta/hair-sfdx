import { LightningElement, api, track } from 'lwc';
import scanLicence from '@salesforce/apex/LicenseScanController.scanLicence';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Lead.Id';
import COMPANY_OWNER_NAME_FIELD from '@salesforce/schema/Lead.Company_owner_name__c';

export default class ScanLicence extends LightningElement {
    @api recordId; // Lead Id
    endpointUrl = 'https://lenderpro.itprofit.net/api/v1/driver-license/analyze';

    @track imageDataUrl;
    @track base64Image;
    @track isLoading = false;
    @track scannedName;
    @track errorMessage;

    get isScanDisabled() {
        return !this.base64Image || this.isLoading;
    }

    handleFileChange(event) {
        this.errorMessage = undefined;
        const file = event.target.files && event.target.files[0];
        if (!file) {
            this.base64Image = undefined;
            this.imageDataUrl = undefined;
            return;
        }
        const reader = new FileReader();
        reader.onload = () => {
            const dataUrl = reader.result;
            this.imageDataUrl = dataUrl;
            const base64Marker = 'base64,';
            const idx = dataUrl.indexOf(base64Marker);
            this.base64Image = idx > -1 ? dataUrl.substring(idx + base64Marker.length) : dataUrl;
        };
        reader.onerror = () => {
            this.showToast('Error', 'Failed to read the file', 'error');
        };
        reader.readAsDataURL(file);
    }

    async handleScan() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            const nameValue = await scanLicence({ base64Image: this.base64Image, endpointUrl: this.endpointUrl });
            this.scannedName = nameValue;
            await this.updateLeadName(nameValue);
            this.showToast('Success', 'Name extracted and Lead updated', 'success');
        } catch (error) {
            const message = (error && error.body && error.body.message) ? error.body.message : (error && error.message) ? error.message : 'Unknown error';
            this.errorMessage = message;
            this.showToast('Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async updateLeadName(nameValue) {
        if (!this.recordId) {
            return;
        }
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[COMPANY_OWNER_NAME_FIELD.fieldApiName] = nameValue;
        await updateRecord({ fields });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
} 