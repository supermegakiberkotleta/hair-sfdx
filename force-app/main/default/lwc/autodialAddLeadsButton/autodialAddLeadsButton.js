import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class AutodialAddLeadsButton extends NavigationMixin(LightningElement) {
    @api recordId; // Autodial_Campaign__c Id
    @api label = 'Add Leads'; // Настраиваемая метка кнопки

    handleClick() {
        // Открываем модальное окно с компонентом autodialAddLeads
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__autodialAddLeadsModal'
            },
            state: {
                c__recordId: this.recordId
            }
        });
    }
}