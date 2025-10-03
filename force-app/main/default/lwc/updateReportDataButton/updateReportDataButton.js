import { LightningElement, track } from 'lwc';
import updateDataFromApi from '@salesforce/apex/ApiDataController.updateDataFromApi';
import updateOpportunityStageReport from '@salesforce/apex/ApiOpportunityStageController.updateOpportunityStageReport';
import updateBrokersCommissionsReport from '@salesforce/apex/ApiBrokersCommissionsController.updateBrokersCommissionsReport';
import updateLeadStageReport from '@salesforce/apex/ApiLeadStageController.updateLeadStageReport';
import updateWorkBriefcaseReport from '@salesforce/apex/ApiWorkBriefcaseController.updateWorkBriefcaseReport';
import updateMonthResultReport from '@salesforce/apex/ApiMonthResultController.updateMonthResultReport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApiDataUpdater extends LightningElement {
    @track dateStart;
    @track dateFinish;
    @track lender;
    @track report;

    lenderOptions = [
        { label: 'Boostra', value: 'boostra' },
        { label: 'Eduelevator', value: 'eduelevator' },
        { label: 'Liberty', value: 'liberty' },
        { label: 'Biz capital', value: 'biz_capital' }
    ];
    reportOptions = [
        { label: 'Woc lender-pro', value: 'woc_lender_pro' },
        { label: 'Check Opportunities stages', value: 'check_opportunity_stages' },
        { label: 'Brokers commissions report', value: 'brokers_commissions' },
        { label: 'Lead stages history report', value: 'lead_stage_history' },
        { label: 'Work briefcase report', value: 'work_briefcase' },
        { label: 'Month result report', value: 'month_result' }
    ];

    handleDateStartChange(event) {
        this.dateStart = event.target.value;
    }

    handleDateFinishChange(event) {
        this.dateFinish = event.target.value;
    }

    handleLenderChange(event) {
        this.lender = event.detail.value;
    }

    handleReportChange(event) {
        this.report = event.detail.value;
    }

    handleUpdate() {
        if (!this.dateStart || !this.dateFinish || !this.report) {
            this.showToast('Error', 'Please fill all fields', 'error');
            return;
        }
        if (new Date(this.dateStart) > new Date(this.dateFinish)) {
            this.showToast('Error', 'Start Date must be before Finish Date', 'error');
            return;
        }

        if (this.report === 'woc_lender_pro') {
            updateDataFromApi({ dateStart: this.dateStart, dateFinish: this.dateFinish, lender: this.lender })
                .then(() => {
                    this.showToast('Success', 'Report updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                });
        } else if (this.report === 'check_opportunity_stages') {
            updateOpportunityStageReport({ dateStart: this.dateStart, dateFinish: this.dateFinish, lender: this.lender })
                .then(() => {
                    this.showToast('Success', 'Report updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                });
        } else if (this.report === 'brokers_commissions') {
            updateBrokersCommissionsReport({ lender: this.lender })
                .then(() => {
                    this.showToast('Success', 'Report updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                });
        } else if (this.report === 'lead_stage_history') {
            updateLeadStageReport({ dateStart: this.dateStart, dateFinish: this.dateFinish})
                .then(() => {
                    this.showToast('Success', 'Report updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                });
        } else if (this.report === 'work_briefcase') {
            updateWorkBriefcaseReport({ dateStart: this.dateStart, dateFinish: this.dateFinish, lender: this.lender})
                .then(() => {
                    this.showToast('Success', 'Report updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                });
        } else if (this.report === 'month_result') {
            updateMonthResultReport({ dateStart: this.dateStart, dateFinish: this.dateFinish, lender: this.lender})
                .then(() => {
                    this.showToast('Success', 'Report updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                });
        }

    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}