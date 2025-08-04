import { LightningElement, api, track } from 'lwc';
import getUploadedFiles from '@salesforce/apex/FileServiceController.getUploadedFiles';
import uploadFile from '@salesforce/apex/FileServiceController.uploadFile';
import triggerNewScoring from '@salesforce/apex/FileServiceController.triggerNewScoring';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploader extends LightningElement {
    @api recordId;
    @track leadId;
    @track files = [];
    @track selectedFiles = [];
    @track isLoading = false;
    @track error = '';
    @track uploadError = '';
    @track isDraggingOver = false;

    connectedCallback() {
        if (this.recordId) {
            this.leadId = this.recordId;
            this.handleRefresh();
        } else {
            this.error = 'Не удалось получить ID лида.';
        }
    }

    handleFileChange(event) {
        if (event.target.files) {
            this.selectedFiles = Array.from(event.target.files);
            // Автоматически запускаем загрузку после выбора файлов
            this.handleUploadToOcrolus();
        }
    }

    handleRefresh() {
        if (!this.leadId) return;
        console.log(this.leadId)    
        this.isLoading = true;
        this.error = '';
        this.uploadError = '';

        getUploadedFiles({ leadId: this.leadId })
            .then(result => {
                console.log('Полученные файлы:', result);
                this.files = result.map(file => ({
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
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    handleUploadToOcrolus() {
        if (!this.leadId || this.selectedFiles.length === 0) {
            console.warn('leadId или файлы не указаны');
            return;
        }
        console.log(this.leadId)

        this.isLoading = true;
        this.uploadError = '';

        const uploadPromises = this.selectedFiles.map(file => {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();

                reader.onloadend = () => {
                    const base64 = reader.result.split(',')[1];

                    uploadFile({
                        fileName: file.name,
                        base64Data: base64,
                        leadId: this.leadId
                    })
                        .then(response => {
                            console.log('Файл успешно отправлен:', response);
                            resolve();
                        })
                        .catch(uploadError => {
                            console.error('Ошибка при загрузке файла:', uploadError);
                            reject(uploadError);
                        });
                };

                reader.onerror = () => {
                    console.error('Ошибка чтения файла');
                    reject(new Error('Ошибка чтения файла'));
                };

                reader.readAsDataURL(file);
            });
        });

        Promise.all(uploadPromises)
            .then(() => {
                this.selectedFiles = [];
                this.handleRefresh();
                // Автоматически запускаем повторное формирование скоринга после загрузки файлов
            
                this.showToast('Успех', 'Файлы успешно загружены', 'success');
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
                    console.log(this.leadId)
                    //this.handleRefresh();
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