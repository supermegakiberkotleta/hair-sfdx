import { LightningElement, api, track } from 'lwc';
import getUploadedFiles from '@salesforce/apex/FileServiceController.getUploadedFiles';
import uploadFile from '@salesforce/apex/FileServiceController.uploadFile';
import triggerNewScoring from '@salesforce/apex/FileServiceController.triggerNewScoring';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploader extends LightningElement {
    @api recordId;
    @track leadId;
    @track rawFiles = [];
    @track selectedFiles = [];
    @track isLoading = false;
    @track error = '';
    @track uploadError = '';
    @track manualFileNames = new Set();

    // --- localStorage helpers ---
    saveManualFileNames() {
        if (!this.leadId) return;
        try {
            const key = `manualFiles_${this.leadId}`;
            const names = Array.from(this.manualFileNames);
            localStorage.setItem(key, JSON.stringify(names));
        } catch (e) {
            console.warn('Не удалось сохранить manualFileNames в localStorage', e);
        }
    }

    loadManualFileNames() {
        if (!this.leadId) {
            this.manualFileNames = new Set();
            return;
        }
        try {
            const key = `manualFiles_${this.leadId}`;
            const stored = localStorage.getItem(key);
            if (stored) {
                const names = JSON.parse(stored);
                this.manualFileNames = new Set(names);
            } else {
                this.manualFileNames = new Set();
            }
        } catch (e) {
            console.warn('Не удалось загрузить manualFileNames из localStorage', e);
            this.manualFileNames = new Set();
        }
    }

    // --- computed property ---
    get files() {
        const MAX_NAME_LENGTH = 35;
        return this.rawFiles.map(file => {
            let displayName = file.name;
            console.log(JSON.stringify(file, null, 2));
            if (displayName.length > MAX_NAME_LENGTH) {
                displayName = displayName.substring(0, MAX_NAME_LENGTH - 3) + '...';
            }
            const prefix = file.type === 'M' ? 'M' : 'A';
            displayName = `[${prefix}] ${displayName}`;
            return { ...file, displayName };
        });
    }

    // --- lifecycle ---
    connectedCallback() {
        if (this.recordId) {
            this.leadId = this.recordId;
            this.loadManualFileNames(); // ← загружаем сохранённые имена
            this.handleRefresh();
        } else {
            this.error = 'Не удалось получить ID лида.';
        }
    }

    // --- handlers ---
    handleFileChange(event) {
        if (event.target.files) {
            this.selectedFiles = Array.from(event.target.files);
            this.handleUploadToOcrolus();
        }
    }

    handleRefresh() {
        if (!this.leadId) return;
        this.isLoading = true;
        this.error = '';
        this.uploadError = '';

        getUploadedFiles({ leadId: this.leadId })
            .then(result => {
                this.rawFiles = result.map(file => ({
                    name: file.name,
                    status: file.status
                }));
            })
            .catch(error => {
                this.error = 'Ошибка при получении списка файлов.';
                console.error('Ошибка при получении загруженных файлов:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleUploadToOcrolus() {
        if (!this.leadId || this.selectedFiles.length === 0) {
            console.warn('leadId или файлы не указаны');
            return;
        }

        this.isLoading = true;
        this.uploadError = '';

        const uploadPromises = this.selectedFiles.map(file => {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const base64 = reader.result.split(',')[1];
                    uploadFile({ fileName: file.name, base64Data: base64, leadId: this.leadId })
                        .then(() => resolve())
                        .catch(reject);
                };
                reader.onerror = () => reject(new Error('Ошибка чтения файла'));
                reader.readAsDataURL(file);
            });
        });

        Promise.all(uploadPromises)
            .then(() => {
                const newFileNames = this.selectedFiles.map(f => f.name);
                this.manualFileNames = new Set([...this.manualFileNames, ...newFileNames]);
                this.saveManualFileNames(); // ← сохраняем!

                this.selectedFiles = [];
                this.showToast('Успех', 'Файлы успешно загружены', 'success');
                this.handleRefresh();
            })
            .catch(error => {
                this.uploadError = 'Ошибка при отправке одного или нескольких файлов.';
                console.error('Ошибка при отправке файлов:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRescore() {
        if (!this.leadId) {
            this.error = 'Lead ID не найден.';
            return;
        }

        this.isLoading = true;
        this.error = '';
        this.uploadError = '';

        triggerNewScoring({ leadId: this.leadId })
            .then(() => {
                console.log('Повторный скоринг запущен');
            })
            .catch(error => {
                console.error('Ошибка при повторном формировании скоринга:', error);
                this.error = 'Не удалось повторно сформировать скоринг.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}