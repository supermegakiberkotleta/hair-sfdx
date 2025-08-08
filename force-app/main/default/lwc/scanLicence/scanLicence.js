import { LightningElement, api, track } from 'lwc';
import scanLicence from '@salesforce/apex/LicenseScanController.scanLicence';
import getScanDataByLeadId from '@salesforce/apex/ScanDataController.getScanDataByLeadId';
import saveScanData from '@salesforce/apex/ScanDataController.saveScanData';
import getFileInfo from '@salesforce/apex/ScanDataController.getFileInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Lead.Id';
import COMPANY_OWNER_NAME_FIELD from '@salesforce/schema/Lead.Company_owner_name__c';

export default class ScanLicence extends LightningElement {
    @api recordId; // Lead Id
    endpointUrl = 'https://lenderpro.itprofit.net/api/v1/driver-license/analyze';

    @track selectedFile;
    @track fileName;
    @track fileSize;
    @track fileType;
    @track isLoading = false;
    @track scannedName;
    @track errorMessage;
    @track scanDataId;
    @track hasExistingData = false;
    @track fileId;
    @track existingFileName;
    @track existingFileSize;
    @track existingFileType;

    get isScanDisabled() {
        return !this.hasExistingData || this.isLoading;
    }

    get hasFileToDisplay() {
        return this.hasExistingData;
    }

    get displayFileName() {
        return this.existingFileName || this.fileName;
    }

    get displayFileSize() {
        return this.existingFileSize || this.fileSize;
    }

    get displayFileType() {
        return this.existingFileType || this.fileType;
    }

    get isImageFile() {
        const fileType = this.displayFileType;
        return fileType && fileType.startsWith('image/');
    }

    get isPdfFile() {
        const fileType = this.displayFileType;
        return fileType === 'application/pdf';
    }

    get isOtherFile() {
        const fileType = this.displayFileType;
        return fileType && !this.isImageFile && !this.isPdfFile;
    }

    get isExistingImageFile() {
        return this.existingFileType && this.existingFileType.startsWith('image/');
    }

    get isExistingPdfFile() {
        return this.existingFileType === 'application/pdf';
    }

    get isExistingOtherFile() {
        return this.existingFileType && !this.isExistingImageFile && !this.isExistingPdfFile;
    }

    connectedCallback() {
        if (this.recordId) {
            this.loadExistingScanData();
        }
    }

    async loadExistingScanData() {
        try {
            const scanData = await getScanDataByLeadId({ leadId: this.recordId });
            if (scanData) {
                await this.loadExistingData(scanData);
            }
        } catch (error) {
            console.error('Error loading scan data:', error);
        }
    }

    async loadExistingData(scanData) {
        if (scanData) {
            this.scanDataId = scanData.Id;
            this.fileId = scanData.File_Id__c;
            this.scannedName = scanData.Name__c;
            this.hasExistingData = true;
            
            console.log('Loading existing data:', {
                scanDataId: this.scanDataId,
                fileId: this.fileId,
                scannedName: this.scannedName
            });
            
            // Получаем информацию о файле
            if (this.fileId) {
                try {
                    const fileInfo = await getFileInfo({ fileId: this.fileId });
                    if (fileInfo) {
                        this.existingFileName = fileInfo.fileName;
                        this.existingFileSize = this.formatFileSize(fileInfo.fileSize);
                        this.existingFileType = fileInfo.fileType;
                        console.log('File info loaded:', fileInfo);
                    }
                } catch (error) {
                    console.error('Error loading file info:', error);
                }
            }
        }
    }

    async handleFileChange(event) {
        this.errorMessage = undefined;
        const file = event.target.files && event.target.files[0];
        if (!file) {
            this.resetFileData();
            return;
        }
        
        console.log('File selected:', {
            name: file.name,
            type: file.type,
            size: file.size
        });
        
        // Проверяем поддерживаемые типы файлов
        const supportedTypes = [
            'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp',
            'application/pdf',
            'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        ];
        
        if (!supportedTypes.includes(file.type)) {
            this.showToast('Error', 'Unsupported file type. Please upload an image, PDF, or Word document.', 'error');
            this.resetFileData();
            return;
        }
        
        // Проверяем размер файла (максимум 5MB)
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (file.size > maxSize) {
            this.showToast('Error', 'File size exceeds 5MB limit', 'error');
            this.resetFileData();
            return;
        }
        
        this.isLoading = true;
        
        try {
            // Читаем файл и получаем base64 данные
            console.log('Reading file as base64...');
            const base64Data = await this.readFileAsBase64(file);
            console.log('Base64 data length:', base64Data.length);
            
            // Сохраняем файл в Files и создаем/обновляем запись в Scan_Data__c
            console.log('Saving file...');
            const savedData = await saveScanData({ 
                leadId: this.recordId, 
                fileName: file.name,
                base64Data: base64Data,
                scannedName: '' // Пока пустое, заполним после сканирования
            });
            console.log('File saved:', savedData);
            
            // Обновляем локальные переменные
            this.fileName = file.name;
            this.fileType = file.type;
            this.fileSize = this.formatFileSize(file.size);
            this.selectedFile = file;
            this.scanDataId = savedData.Id;
            this.fileId = savedData.File_Id__c;
            this.hasExistingData = true;
            this.scannedName = undefined; // Сбрасываем результат сканирования
            
            // Обновляем информацию о существующем файле
            this.existingFileName = file.name;
            this.existingFileSize = this.formatFileSize(file.size);
            this.existingFileType = file.type;
            
            this.showToast('Success', 'File uploaded successfully', 'success');
            
        } catch (error) {
            console.error('Error uploading file:', error);
            let message = 'Unknown error';
            if (error && error.body && error.body.message) {
                message = error.body.message;
            } else if (error && error.message) {
                message = error.message;
            }
            this.errorMessage = message;
            this.showToast('Error', message, 'error');
            this.resetFileData();
        } finally {
            this.isLoading = false;
        }
    }

    resetFileData() {
        this.selectedFile = undefined;
        this.fileName = undefined;
        this.fileSize = undefined;
        this.fileType = undefined;
        this.hasExistingData = false;
        this.scannedName = undefined;
        this.scanDataId = undefined;
        this.fileId = undefined;
        this.existingFileName = undefined;
        this.existingFileSize = undefined;
        this.existingFileType = undefined;
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    async handleScan() {
        if (!this.hasExistingData) {
            this.showToast('Error', 'No file uploaded', 'error');
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;
        
        try {
            console.log('Starting scan with recordId:', this.recordId);
            console.log('File type:', this.existingFileType);
            console.log('File size:', this.existingFileSize);
            
            // Получаем base64 данные из сохраненного файла
            console.log('Getting file data for scanning...');
            const base64Data = await this.getFileBase64Data(this.fileId);
            console.log('Base64 data length:', base64Data.length);
            
            // Отправляем запрос на сканирование
            console.log('Sending scan request...');
            const nameValue = await scanLicence({ 
                base64Data: base64Data,
                fileName: this.existingFileName,
                endpointUrl: this.endpointUrl 
            });
            console.log('Scanned name:', nameValue);
            this.scannedName = nameValue;
            
            // Обновляем запись в Scan_Data__c с результатом сканирования
            console.log('Updating scan data with result...');
            await this.updateScanDataWithResult(nameValue);
            
            await this.updateLeadName(nameValue);
            this.showToast('Success', 'Document scanned successfully', 'success');
        } catch (error) {
            console.error('Error in handleScan:', error);
            console.error('Error details:', {
                message: error.message,
                body: error.body,
                stack: error.stack
            });
            
            let message = 'Unknown error';
            if (error && error.body && error.body.message) {
                message = error.body.message;
            } else if (error && error.message) {
                message = error.message;
            }
            
            this.errorMessage = message;
            this.showToast('Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async getFileBase64Data(fileId) {
        try {
            const response = await fetch(`/sfc/servlet.shepherd/document/download/${fileId}`);
            const blob = await response.blob();
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const base64 = reader.result.split(',')[1];
                    resolve(base64);
                };
                reader.onerror = reject;
                reader.readAsDataURL(blob);
            });
        } catch (error) {
            console.error('Error getting file base64 data:', error);
            throw new Error('Error getting file data: ' + error.message);
        }
    }

    async updateScanDataWithResult(scannedName) {
        try {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.scanDataId;
            fields['Name__c'] = scannedName;
            await updateRecord({ fields });
            console.log('Updated scan data with name:', scannedName);
        } catch (error) {
            console.error('Error updating scan data:', error);
            throw new Error('Error updating scan data: ' + error.message);
        }
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            console.log('Starting file read for:', file.name);
            const reader = new FileReader();
            
            reader.onloadend = () => {
                try {
                    const base64 = reader.result.split(',')[1]; // Убираем data:image/...;base64,
                    console.log('File read successful, base64 length:', base64.length);
                    resolve(base64);
                } catch (error) {
                    console.error('Error processing file data:', error);
                    reject(new Error('Error processing file data: ' + error.message));
                }
            };
            
            reader.onerror = () => {
                console.error('FileReader error:', reader.error);
                reject(new Error('Error reading file: ' + reader.error.message));
            };
            
            reader.onabort = () => {
                console.error('FileReader aborted');
                reject(new Error('File reading was aborted'));
            };
            
            reader.readAsDataURL(file);
        });
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

    handleDownload() {
        if (this.fileUrl) {
            window.open(this.fileUrl, '_blank');
        }
    }

    handleImageError() {
        console.error('Failed to load image from URL:', this.fileUrl);
        this.showToast('Warning', 'Failed to load image preview', 'warning');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
} 