import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createLead from '@salesforce/apex/CreateLeadFromOpportunity.createLead';
import { NavigationMixin } from 'lightning/navigation';

export default class CreateLeadFromOpportunityButton extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;

    handleClick() {
        this.isLoading = true;
        createLead({ opportunityId: this.recordId })
            .then(leadId => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Успех',
                        message: 'Лид успешно создан',
                        variant: 'success'
                    })
                );
                // Редирект на нового лида
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: leadId,
                        objectApiName: 'Lead',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.dispatchEvent(
                    console.log(error),
                    new ShowToastEvent({
                        title: 'Ошибка',
                        message: error.body && error.body.message ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}