import { LightningElement, wire, api, track } from 'lwc';
import getTasksByOpportunity from '@salesforce/apex/TaskController.getTasksByOpportunity';
import getActivityDetailsForTask from '@salesforce/apex/TaskController.getActivityDetailsForTask';
import updateTask from '@salesforce/apex/TaskController.updateTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OpportunityTaskGrouping extends LightningElement {
    @api recordId;
    @track tasks = [];
    @track isLoading = true;
    @track activeSections = [];
    @track todayKey = '';

    connectedCallback() {
        const today = new Date();
        this.todayKey = today.toISOString().split('T')[0];
    }

    get groupedTasks() {
        if (!this.tasks || this.tasks.length === 0) return [];

        const groups = {};
        this.tasks.forEach(task => {
            if (!task.ActivityDate) return;

            const dateKey = task.ActivityDate;
            if (!groups[dateKey]) {
                const date = new Date(dateKey);
                let label = date.toLocaleDateString('en-US', {
                    weekday: 'short',
                    month: 'short',
                    day: 'numeric'
                });
                if (dateKey === this.todayKey) {
                    label = 'Today - ' + label;
                }
                groups[dateKey] = { key: dateKey, label, tasks: [] };
            }
            groups[dateKey].tasks.push(task);
        });

        return Object.values(groups).sort((a, b) => new Date(a.key) - new Date(b.key));
    }

    get hasData() {
        return this.tasks && this.tasks.length > 0;
    }

    @wire(getTasksByOpportunity, { opportunityId: '$recordId' })
    wiredTasks({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.tasks = data.tasks.map(task => ({
                ...task,
                WhoName: task.Who ? task.Who.Name : '',
                OwnerName: task.Owner ? task.Owner.Name : '',
                statusLabel: task.Status ? task.Status.toLowerCase() : '',
                IsCompleted: task.Status === 'Completed',
                missedPaymentCount: data.missedPaymentCount,
                showDetails: false,
                emails: [],
                calls: [],
                sms: [],
                hasEmails: false,
                hasCalls: false,
                hasSMS: false,
                noEmails: false,
                noCalls: false,
                noSMS: false
            }));
            this.setActiveSection();
        } else if (error) {
            console.error(error);
            this.tasks = [];
            this.showToast('Error', 'Failed to load tasks', 'error');
        }
        this.isLoading = false;
    }

    setActiveSection() {
        this.activeSections = [this.todayKey];
    }

    async handleToggleDetails(event) {
        event.preventDefault();
    
        const taskId = event.currentTarget.dataset.taskId;
        const taskIndex = this.tasks.findIndex(task => task.Id === taskId);
        if (taskIndex === -1) return;
    
        const task = this.tasks[taskIndex];
    
        // 1. Добавляем активную секцию (дату задачи) в список, если ещё не добавлена
        const dateKey = task.ActivityDate;
        if (!this.activeSections.includes(dateKey)) {
            this.activeSections = [...this.activeSections, dateKey];
        }
    
        // 2. Раскрытие вкладки внутри задачи
        task.showDetails = !task.showDetails;
    
        // 3. Проверка: если уже загружены — не запрашивать снова
        if (!task.showDetails ||
            task.hasEmails || task.hasCalls || task.hasSMS ||
            task.noEmails || task.noCalls || task.noSMS
        ) {
            this.tasks = [...this.tasks];
            return;
        }
    
        this.isLoading = true;
        try {
            const result = await getActivityDetailsForTask({ taskId });
            task.emails = result.emails || [];
            task.calls = result.calls || [];
            task.sms = result.sms || [];
    
            task.hasEmails = task.emails.length > 0;
            task.hasCalls = task.calls.length > 0;
            task.hasSMS = task.sms.length > 0;
    
            task.noEmails = task.emails.length === 0;
            task.noCalls = task.calls.length === 0;
            task.noSMS = task.sms.length === 0;
    
        } catch (error) {
            console.error(error);
            this.showToast('Error', 'Failed to load activity', 'error');
        } finally {
            this.isLoading = false;
            this.tasks = [...this.tasks]; // чтобы отрендерить детали
        }
    }
    
    
    
    async handleTaskComplete(event) {
        const taskId = event.target.dataset.taskId;
        const isCompleted = event.target.checked;

        try {
            this.isLoading = true;
            const taskToUpdate = this.tasks.find(task => task.Id === taskId);
            if (!taskToUpdate) return;

            await updateTask({
                taskId,
                status: isCompleted ? 'Completed' : 'Not Started',
                activityDate: taskToUpdate.ActivityDate
            });

            this.tasks = this.tasks.map(task =>
                task.Id === taskId
                    ? { ...task, Status: isCompleted ? 'Completed' : 'Not Started', statusLabel: isCompleted ? 'completed' : 'upcoming', IsCompleted: isCompleted }
                    : task
            );

            this.showToast('Success', 'Task status updated', 'success');
        } catch (error) {
            console.error(error);
            this.showToast('Error', 'Failed to update task', 'error');
            event.target.checked = !isCompleted;
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}