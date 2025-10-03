import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getFilters from '@salesforce/apex/AutodialCampaignFiltersController.getFilters';
import getObjectFields from '@salesforce/apex/AutodialCampaignFiltersController.getObjectFields';
import saveFilters from '@salesforce/apex/AutodialCampaignFiltersController.saveFilters';
import deleteFilter from '@salesforce/apex/AutodialCampaignFiltersController.deleteFilter';
import deleteAllFilters from '@salesforce/apex/AutodialCampaignFiltersController.deleteAllFilters';

// Import fields for Autodial_Campaign__c
const CAMPAIGN_ID_FIELD = 'Autodial_Campaign__c.Id';

export default class AutodialCampaignFilters extends LightningElement {
    @api recordId; // Autodial_Campaign__c record ID
    
    @track filters = [];
    @track newFilter = {
        objectType: '',
        field: '',
        operator: 'equals', // Set default operator to 'equals'
        value: ''
    };
    
    constructor() {
        super();
        console.log('=== Constructor called ===');
        console.log('Initial fieldOptions:', this.fieldOptions);
    }
    
    @track objectTypeOptions = [
        { label: 'Lead', value: 'Lead' },
        { label: 'Contact', value: 'Contact' },
        { label: 'Account', value: 'Account' }
    ];
    
    @track fieldOptions = [];
    @track allFieldOptions = {}; // Store field options for all object types
    @track filteredFieldOptions = [];
    @track fieldSearchValue = '';
    @track showFieldDropdown = false;
    @track operatorOptions = [
        { label: 'Equals', value: 'equals' },
        { label: 'Not Equal To', value: 'not equal to' },
        { label: 'Contains', value: 'contains' },
        { label: 'Does Not Contain', value: 'does not contain' },
        { label: 'Is Null', value: 'is null' },
        { label: 'Greater Than', value: 'greater than' },
        { label: 'Less Than', value: 'less than' },
        { label: 'Greater or Equal', value: 'greater or equal' },
        { label: 'Less or Equal', value: 'less or equal' }
    ];
    
    isLoading = false;
    isSaving = false;
    
    // Wired properties
    @wire(getRecord, { recordId: '$recordId', fields: [CAMPAIGN_ID_FIELD] })
    wiredCampaign;
    
    async connectedCallback() {
        console.log('=== connectedCallback called ===');
        console.log('recordId:', this.recordId);
        await this.loadAllFieldOptions();
        this.loadFilters();
    }
    
    // Load filters method
    async loadFilters() {
        console.log('=== loadFilters called ===');
        console.log('recordId:', this.recordId);
        
        if (!this.recordId) {
            console.log('No recordId, returning early');
            return;
        }
        
        try {
            this.isLoading = true;
            console.log('Calling getFilters with campaignId:', this.recordId);
            const jsonResult = await getFilters({ campaignId: this.recordId });
            console.log('getFilters JSON result:', jsonResult);
            console.log('JSON result type:', typeof jsonResult);
            console.log('JSON result length:', jsonResult ? jsonResult.length : 'null');
            
            // Parse JSON string to array of objects
            let result = [];
            if (jsonResult) {
                try {
                    result = JSON.parse(jsonResult);
                    console.log('Parsed result:', result);
                    console.log('Parsed result type:', typeof result);
                    console.log('Parsed result is array:', Array.isArray(result));
                    console.log('Result length:', result ? result.length : 'null');
                } catch (parseError) {
                    console.error('Error parsing JSON:', parseError);
                    console.error('JSON string:', jsonResult);
                    this.showToast('Error', 'Failed to parse filter data', 'error');
                    return;
                }
            } else {
                console.log('No JSON result received');
            }
            
            // Log each filter individually
            if (result && result.length > 0) {
                result.forEach((filter, index) => {
                    console.log(`Filter ${index}:`, {
                        Id: filter.Id,
                        object_type__c: filter.object_type__c,
                        field__c: filter.field__c,
                        operator__c: filter.operator__c,
                        value__c: filter.value__c,
                        autodial_campaign__c: filter.autodial_campaign__c
                    });
                });
            }
            
            // Process existing filters to add labels for display
            this.filters = (result || []).map(filter => {
                // Find labels for existing filters
                const objectTypeLabel = this.objectTypeOptions.find(opt => opt.value === filter.object_type__c)?.label || filter.object_type__c || 'Unknown';
                const operatorLabel = this.operatorOptions.find(opt => opt.value === filter.operator__c)?.label || filter.operator__c || 'Unknown';
                
                // Ensure all values are strings and not null/undefined
                const safeObjectType = filter.object_type__c || '';
                const safeField = filter.field__c || '';
                const safeOperator = filter.operator__c || '';
                const safeValue = filter.value__c || '';
                
                // Get field label from all field options if available
                let fieldLabel = safeField; // Default to field API name
                if (this.allFieldOptions && this.allFieldOptions[safeObjectType]) {
                    const fieldOption = this.allFieldOptions[safeObjectType].find(field => field.value === safeField);
                    if (fieldOption) {
                        fieldLabel = fieldOption.label;
                    }
                }
                
                return {
                    ...filter,
                    objectType: safeObjectType, // Map to camelCase for consistency
                    field: safeField,
                    operator: safeOperator,
                    value: safeValue,
                    objectTypeLabel: objectTypeLabel,
                    operatorLabel: operatorLabel,
                    fieldLabel: fieldLabel,
                    fieldApiName: safeField
                };
            });
            
            console.log('Set filters to:', JSON.parse(JSON.stringify(this.filters)));
            
            // Log each processed filter individually
            if (this.filters && this.filters.length > 0) {
                this.filters.forEach((filter, index) => {
                    console.log(`Processed Filter ${index}:`, {
                        Id: filter.Id,
                        objectTypeLabel: filter.objectTypeLabel,
                        fieldLabel: filter.fieldLabel,
                        fieldApiName: filter.fieldApiName,
                        operatorLabel: filter.operatorLabel,
                        value: filter.value,
                        objectType: filter.objectType,
                        field: filter.field,
                        operator: filter.operator
                    });
                });
            }
        } catch (error) {
            this.showToast('Error', 'Failed to load filters', 'error');
            console.error('Error loading filters:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Load field options method
    async loadFieldOptions() {
        console.log('=== loadFieldOptions called ===');
        console.log('newFilter.objectType:', this.newFilter.objectType);
        
        if (!this.newFilter.objectType) {
            console.log('No object type selected, clearing field options');
            this.fieldOptions = [];
            this.filteredFieldOptions = [];
            this.fieldSearchValue = '';
            this.showFieldDropdown = false;
            return;
        }
        
        // Use cached field options if available
        if (this.allFieldOptions && this.allFieldOptions[this.newFilter.objectType]) {
            console.log('Using cached field options for:', this.newFilter.objectType);
            this.fieldOptions = this.allFieldOptions[this.newFilter.objectType];
            this.filteredFieldOptions = this.fieldOptions;
            this.showFieldDropdown = this.fieldOptions.length > 0;
            console.log('fieldOptions length:', this.fieldOptions.length);
            return;
        }
        
        try {
            console.log('Calling getObjectFields for:', this.newFilter.objectType);
            const result = await getObjectFields({ objectType: this.newFilter.objectType });
            console.log('getObjectFields result:', JSON.parse(JSON.stringify(result)));
            console.log('Result length:', result ? result.length : 'null');
            
            // Log first few items to see structure
            if (result && result.length > 0) {
                console.log('First result item:', result[0]);
                console.log('First result item keys:', Object.keys(result[0]));
                console.log('First result item label:', result[0].label);
                console.log('First result item apiName:', result[0].apiName);
            }
            
            this.fieldOptions = result.map(field => ({
                label: field.label,
                value: field.apiName
            }));
            
            this.filteredFieldOptions = this.fieldOptions;
            this.showFieldDropdown = this.fieldOptions.length > 0;
            
            console.log('Mapped fieldOptions:', JSON.parse(JSON.stringify(this.fieldOptions)));
            console.log('fieldOptions length:', this.fieldOptions.length);
            
            // Log first few mapped items
            if (this.fieldOptions.length > 0) {
                console.log('First fieldOption:', this.fieldOptions[0]);
            }
            
        } catch (error) {
            console.error('Error loading fields:', error);
            console.error('Error details:', JSON.stringify(error, null, 2));
            this.fieldOptions = [];
            this.filteredFieldOptions = [];
        }
    }
    
    // Load field options for all object types
    async loadAllFieldOptions() {
        console.log('=== loadAllFieldOptions called ===');
        
        try {
            // Load fields for all object types
            const objectTypes = ['Lead', 'Contact', 'Account'];
            const fieldPromises = objectTypes.map(async (objectType) => {
                try {
                    const result = await getObjectFields({ objectType: objectType });
                    return {
                        objectType: objectType,
                        fields: result.map(field => ({
                            label: field.label,
                            value: field.apiName
                        }))
                    };
                } catch (error) {
                    console.error(`Error loading fields for ${objectType}:`, error);
                    return {
                        objectType: objectType,
                        fields: []
                    };
                }
            });
            
            const results = await Promise.all(fieldPromises);
            
            // Store field options for each object type
            this.allFieldOptions = {};
            results.forEach(result => {
                this.allFieldOptions[result.objectType] = result.fields;
            });
            
            console.log('All field options loaded:', this.allFieldOptions);
            
        } catch (error) {
            console.error('Error loading all field options:', error);
        }
    }
    
    // Computed properties
    get isAddDisabled() {
        return !this.newFilter.objectType || 
               !this.newFilter.field || 
               !this.newFilter.operator || 
               !this.newFilter.value;
    }
    
    get isClearDisabled() {
        return this.filters.length === 0;
    }
    
    get isSaveDisabled() {
        return this.isSaving;
    }
    
    // Event handlers
    async handleObjectTypeChange(event) {
        console.log('=== handleObjectTypeChange called ===');
        console.log('Event detail value:', event.detail.value);
        
        this.newFilter.objectType = event.detail.value;
        console.log('Set newFilter.objectType to:', this.newFilter.objectType);
        
        // Reset field when object type changes
        this.newFilter.field = '';
        this.newFilter.operator = 'equals'; // Set default operator to 'equals'
        this.newFilter.value = '';
        this.fieldSearchValue = '';
        this.showFieldDropdown = false;
        console.log('Reset other filter fields, set default operator to equals');
        
        // Load field options for the selected object type
        console.log('About to call loadFieldOptions');
        await this.loadFieldOptions();
        console.log('loadFieldOptions completed');
    }
    
    handleFieldChange(event) {
        console.log('handleFieldChange called with:', event.detail.value);
        this.newFilter.field = event.detail.value;
        console.log('newFilter.field set to:', this.newFilter.field);
    }
    
    handleFieldSearchChange(event) {
        console.log('handleFieldSearchChange called with:', event.detail.value);
        this.fieldSearchValue = event.detail.value;
        
        // Filter field options based on search value
        if (this.fieldSearchValue && this.fieldSearchValue.length > 0) {
            this.filteredFieldOptions = this.fieldOptions.filter(field => 
                field.label.toLowerCase().includes(this.fieldSearchValue.toLowerCase()) ||
                field.value.toLowerCase().includes(this.fieldSearchValue.toLowerCase())
            );
            this.showFieldDropdown = this.filteredFieldOptions.length > 0;
        } else {
            this.filteredFieldOptions = this.fieldOptions;
            this.showFieldDropdown = this.fieldOptions.length > 0;
        }
        
        console.log('Filtered field options:', this.filteredFieldOptions.length);
    }
    
    handleFieldInputClick(event) {
        console.log('handleFieldInputClick called');
        // Show all field options when clicking on the input
        if (this.fieldOptions.length > 0) {
            this.filteredFieldOptions = this.fieldOptions;
            this.showFieldDropdown = true;
        }
    }
    
    handleFieldInputFocus(event) {
        console.log('handleFieldInputFocus called');
        // Show all field options when focusing on the input
        if (this.fieldOptions.length > 0) {
            this.filteredFieldOptions = this.fieldOptions;
            this.showFieldDropdown = true;
        }
    }
    
    selectField(event) {
        const selectedValue = event.target.dataset.value;
        const selectedField = this.fieldOptions.find(field => field.value === selectedValue);
        
        if (selectedField) {
            this.newFilter.field = selectedValue;
            this.fieldSearchValue = selectedField.label;
            this.showFieldDropdown = false;
            console.log('Selected field:', selectedField);
        }
    }
    
    handleContainerClick(event) {
        // Close dropdown if clicked outside of field search container
        if (!event.target.closest('.field-search-container')) {
            this.showFieldDropdown = false;
        }
    }
    
    handleOperatorChange(event) {
        console.log('handleOperatorChange called with:', event.detail.value);
        this.newFilter.operator = event.detail.value;
        console.log('newFilter.operator set to:', this.newFilter.operator);
    }
    
    handleValueChange(event) {
        console.log('handleValueChange called with:', event.detail.value);
        this.newFilter.value = event.detail.value;
        console.log('newFilter.value set to:', this.newFilter.value);
    }
    
    addFilter() {
        console.log('=== addFilter called ===');
        console.log('isAddDisabled:', this.isAddDisabled);
        console.log('newFilter:', this.newFilter);
        console.log('newFilter.objectType:', this.newFilter.objectType);
        console.log('newFilter.field:', this.newFilter.field);
        console.log('newFilter.operator:', this.newFilter.operator);
        console.log('newFilter.value:', this.newFilter.value);
        console.log('fieldOptions:', this.fieldOptions);
        
        if (this.isAddDisabled) {
            this.showToast('Warning', 'Please fill in all filter fields', 'warning');
            return;
        }
        
        // Find field label and API name for display
        let fieldLabel = this.newFilter.field; // Default to field API name
        let fieldApiName = this.newFilter.field; // Default to field API name
        
        if (this.allFieldOptions && this.allFieldOptions[this.newFilter.objectType]) {
            const fieldOption = this.allFieldOptions[this.newFilter.objectType].find(field => field.value === this.newFilter.field);
            console.log('fieldOption found:', fieldOption);
            
            if (fieldOption) {
                fieldLabel = fieldOption.label;
                fieldApiName = fieldOption.value;
            }
        } else {
            console.log('allFieldOptions is empty for object type, using field API name as label');
        }
        
        console.log('fieldLabel:', fieldLabel);
        console.log('fieldApiName:', fieldApiName);
        
        const objectTypeOption = this.objectTypeOptions.find(opt => opt.value === this.newFilter.objectType);
        console.log('objectTypeOption found:', objectTypeOption);
        const objectTypeLabel = objectTypeOption ? objectTypeOption.label : this.newFilter.objectType;
        console.log('objectTypeLabel:', objectTypeLabel);
        
        const operatorOption = this.operatorOptions.find(opt => opt.value === this.newFilter.operator);
        console.log('operatorOption found:', operatorOption);
        const operatorLabel = operatorOption ? operatorOption.label : this.newFilter.operator;
        console.log('operatorLabel:', operatorLabel);
        
        // Create new filter object for display
        const newFilterObject = {
            Id: 'temp_' + Date.now(), // Temporary ID for display
            objectTypeLabel: objectTypeLabel,
            fieldLabel: fieldLabel,
            fieldApiName: fieldApiName,
            operatorLabel: operatorLabel,
            ...this.newFilter
        };
        
        console.log('newFilterObject:', newFilterObject);
        
        this.filters = [...this.filters, newFilterObject];
        console.log('Updated filters:', JSON.parse(JSON.stringify(this.filters)));
        
        // Reset form
        this.newFilter = {
            objectType: this.newFilter.objectType, // Keep object type selected
            field: '',
            operator: 'equals', // Set default operator to 'equals'
            value: ''
        };
        this.fieldSearchValue = '';
        this.showFieldDropdown = false;
        
        this.showToast('Success', 'Filter added successfully', 'success');
    }
    
    async deleteFilter(event) {
        const index = parseInt(event.target.dataset.index);
        const filterToDelete = this.filters[index];
        
        if (!filterToDelete) {
            this.showToast('Error', 'Filter not found', 'error');
            return;
        }
        
        // If it's a temporary filter (not saved yet), just remove from local array
        if (filterToDelete.Id && filterToDelete.Id.toString().startsWith('temp_')) {
            this.filters.splice(index, 1);
            this.filters = [...this.filters]; // Trigger reactivity
            this.showToast('Success', 'Filter removed successfully', 'success');
            return;
        }
        
        // If it's a saved filter, delete from database
        if (filterToDelete.Id) {
            try {
                this.isLoading = true;
                await deleteFilter({ filterId: filterToDelete.Id });
                
                // Remove from local array after successful deletion
                this.filters.splice(index, 1);
                this.filters = [...this.filters]; // Trigger reactivity
                
                this.showToast('Success', 'Filter removed successfully', 'success');
            } catch (error) {
                console.error('Error deleting filter:', error);
                let errorMessage = 'Failed to delete filter';
                
                if (error.body && error.body.message) {
                    errorMessage += ': ' + error.body.message;
                } else if (error.message) {
                    errorMessage += ': ' + error.message;
                }
                
                this.showToast('Error', errorMessage, 'error');
            } finally {
                this.isLoading = false;
            }
        } else {
            // Fallback: just remove from local array
            this.filters.splice(index, 1);
            this.filters = [...this.filters]; // Trigger reactivity
            this.showToast('Success', 'Filter removed successfully', 'success');
        }
    }
    
    async clearAllFilters() {
        if (this.filters.length === 0) {
            this.showToast('Warning', 'No filters to clear', 'warning');
            return;
        }
        
        try {
            this.isLoading = true;
            await deleteAllFilters({ campaignId: this.recordId });
            
            // Clear local array after successful deletion
            this.filters = [];
            // Reset form to initial state
            this.newFilter = {
                objectType: '',
                field: '',
                operator: 'equals', // Set default operator to 'equals'
                value: ''
            };
            this.fieldOptions = [];
            this.filteredFieldOptions = [];
            this.fieldSearchValue = '';
            this.showFieldDropdown = false;
            this.showToast('Success', 'All filters cleared', 'success');
        } catch (error) {
            console.error('Error clearing all filters:', error);
            let errorMessage = 'Failed to clear all filters';
            
            if (error.body && error.body.message) {
                errorMessage += ': ' + error.body.message;
            } else if (error.message) {
                errorMessage += ': ' + error.message;
            }
            
            this.showToast('Error', errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async saveFilters() {
        if (this.filters.length === 0) {
            this.showToast('Warning', 'No filters to save', 'warning');
            return;
        }
        
        this.isSaving = true;
        
        try {
            // Validate filters before saving
            const validFilters = this.filters.filter(filter => {
                return filter.objectType && filter.field && filter.operator && filter.value;
            });
            
            if (validFilters.length !== this.filters.length) {
                this.showToast('Warning', 'Some filters have incomplete data and will be skipped', 'warning');
            }
            
            if (validFilters.length === 0) {
                this.showToast('Warning', 'No valid filters to save', 'warning');
                return;
            }
            
            // Prepare all filters as JSON data
            const filtersData = validFilters.map(filter => ({
                Id: filter.Id.toString().startsWith('temp_') ? null : filter.Id,
                object_type__c: filter.objectType,
                field__c: filter.field,
                operator__c: filter.operator,
                value__c: filter.value,
                autodial_campaign__c: this.recordId
            }));
            
            console.log('=== saveFilters data ===');
            console.log('filtersData:', JSON.parse(JSON.stringify(filtersData)));
            console.log('campaignId:', this.recordId);
            
            // Convert to JSON string for Apex
            const filtersJson = JSON.stringify(filtersData);
            
            const result = await saveFilters({ 
                filtersJson: filtersJson,
                campaignId: this.recordId 
            });
            
            console.log('Save result:', result);
            this.showToast('Success', 'Filters saved successfully', 'success');
            
            // Reload filters to get updated data
            await this.loadFilters();
            
        } catch (error) {
            console.error('Error saving filters:', error);
            let errorMessage = 'Failed to save filters';
            
            if (error.body && error.body.message) {
                errorMessage += ': ' + error.body.message;
            } else if (error.message) {
                errorMessage += ': ' + error.message;
            }
            
            this.showToast('Error', errorMessage, 'error');
        } finally {
            this.isSaving = false;
        }
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}