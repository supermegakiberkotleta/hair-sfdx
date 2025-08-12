import { LightningElement, api, track } from 'lwc';
import scanCheck from '@salesforce/apex/CheckScanController.scanCheck';
import getScanDataByLeadId from '@salesforce/apex/CheckScanDataController.getScanDataByLeadId';
import saveScanData from '@salesforce/apex/CheckScanDataController.saveScanData';
import getFileInfo from '@salesforce/apex/CheckScanDataController.getFileInfo';
import getFileBase64Data from '@salesforce/apex/CheckScanDataController.getFileBase64Data';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Lead.Id';
import ROUTING_NUMBER_FIELD from '@salesforce/schema/Lead.Routing_Number__c';
import ACCOUNT_NUMBER_FIELD from '@salesforce/schema/Lead.Account_Number__c';
import COMPANY_NAME_FIELD from '@salesforce/schema/Lead.Company_name__c';
import ADDRESS_FIELD from '@salesforce/schema/Lead.Address__c';

export default class ScanCheck extends LightningElement {
    @api recordId; // Lead Id
    endpointUrl = 'https://lenderpro.ai/api/v1/check/analyze';

    @track selectedFile;
    @track fileName;
    @track fileSize;
    @track fileType;
    @track isLoading = false;
    @track routingNumber;
    @track accountNumber;
    @track companyName;
    @track address;
    @track scanDataId;
    @track hasExistingData = false;
    @track fileId;
    @track existingFileName;
    @track existingFileSize;
    @track existingFileType;

    get isScanDisabled() {
        return !this.recordId || this.isLoading;
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
            this.routingNumber = scanData.Routing_Number__c;
            this.accountNumber = scanData.Account_Number__c;
            this.companyName = scanData.Company_name__c;
            this.address = scanData.Address__c;
            this.hasExistingData = true;
            
            console.log('Loading existing data:', {
                scanDataId: this.scanDataId,
                fileId: this.fileId,
                routingNumber: this.routingNumber,
                accountNumber: this.accountNumber,
                companyName: this.companyName,
                address: this.address
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
                routingNumber: '', // Пока пустое, заполним после сканирования
                accountNumber: '', // Пока пустое, заполним после сканирования
                companyName: '', // Пока пустое, заполним после сканирования
                address: '' // Пока пустое, заполним после сканирования
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
            this.routingNumber = undefined; // Сбрасываем результат сканирования
            this.accountNumber = undefined; // Сбрасываем результат сканирования
            this.companyName = undefined; // Сбрасываем результат сканирования
            this.address = undefined; // Сбрасываем результат сканирования
            
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
        this.routingNumber = undefined;
        this.accountNumber = undefined;
        this.companyName = undefined;
        this.address = undefined;
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
        if (!this.recordId) {
            this.showToast('Error', 'No Lead ID provided', 'error');
            return;
        }

        this.isLoading = true;
        
        try {
            console.log('Starting scan with recordId:', this.recordId);
            
            let scanData, fileInfo, fileId;
            
            // Проверяем, есть ли у нас локальные данные
            if (this.scanDataId && this.fileId && this.existingFileName) {
                console.log('Using local data for scanning...');
                scanData = {
                    Id: this.scanDataId,
                    File_Id__c: this.fileId
                };
                fileInfo = {
                    fileName: this.existingFileName,
                    fileSize: this.existingFileSize,
                    fileType: this.existingFileType
                };
                fileId = this.fileId;
            } else {
                // Получаем данные из Scan_Data__c по Lead__c
                console.log('Getting scan data from database...');
                scanData = await getScanDataByLeadId({ leadId: this.recordId });
                console.log('Raw scan data response:', scanData);
                
                if (!scanData) {
                    throw new Error('No scan data found for this Lead. Please upload a file first.');
                }
                
                if (!scanData.File_Id__c) {
                    throw new Error('No file ID found in scan data. The file may have been corrupted.');
                }
                
                console.log('Scan data found:', scanData);
                console.log('File ID:', scanData.File_Id__c);
                
                // Получаем информацию о файле
                console.log('Getting file info for fileId:', scanData.File_Id__c);
                fileInfo = await getFileInfo({ fileId: scanData.File_Id__c });
                console.log('File info response:', fileInfo);
                
                if (!fileInfo) {
                    throw new Error('File information not found. The file may have been deleted or is not accessible.');
                }
                
                fileId = scanData.File_Id__c;
            }
            
            console.log('File info:', fileInfo);
            
            // Получаем base64 данные из сохраненного файла используя серверный метод
            console.log('Getting file data for scanning...');
            const base64Data = await this.getFileBase64DataFromServer(fileId);
            console.log('Base64 data length:', base64Data.length);
            
            // Отправляем запрос на сканирование
            console.log('Sending scan request...');
            const scanResult = await scanCheck({ 
                base64Data: base64Data,
                fileName: fileInfo.fileName,
                endpointUrl: this.endpointUrl 
            });
            console.log('Scan result:', scanResult);
            
            // Извлекаем routing_number и account_number из результата
            this.routingNumber = scanResult.routing_number || '';
            this.accountNumber = scanResult.account_number || '';
            this.companyName = scanResult.company_name || '';
            this.address = scanResult.address || '';
            
            // Обновляем запись в Scan_Data__c с результатом сканирования
            console.log('Updating scan data with result...');
            await this.updateScanDataWithResult(this.routingNumber, this.accountNumber, this.companyName, this.address, scanData.Id);
            
            // Обновляем поля в Lead
            await this.updateLeadFields(this.routingNumber, this.accountNumber, this.companyName, this.address);
            this.showToast('Success', 'Check scanned successfully', 'success');
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
            
            this.showToast('Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async getFileBase64DataFromServer(fileId) {
        try {
            console.log('Getting file base64 data from server for fileId:', fileId);
            const base64Data = await getFileBase64Data({ fileId: fileId });
            console.log('Base64 data received from server, length:', base64Data.length);
            return base64Data;
        } catch (error) {
            console.error('Error getting file base64 data from server:', error);
            throw new Error('Error getting file data from server: ' + error.message);
        }
    }

    async updateScanDataWithResult(routingNumber, accountNumber, companyName, address, scanDataId) {
        try {
            const fields = {};
            fields[ID_FIELD.fieldApiName] = scanDataId;
            fields['Routing_Number__c'] = routingNumber;
            fields['Account_Number__c'] = accountNumber;
            fields['Company_name__c'] = companyName;
            fields['Address__c'] = address;
            await updateRecord({ fields });
            console.log('Updated scan data with routing number:', routingNumber, 'account number:', accountNumber, 'company name:', companyName, 'address:', address);
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

    async updateLeadFields(routingNumber, accountNumber, companyName, address) {
        if (!this.recordId) {
            return;
        }
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        if (routingNumber) {
            fields[ROUTING_NUMBER_FIELD.fieldApiName] = routingNumber;
        }
        if (accountNumber) {
            fields[ACCOUNT_NUMBER_FIELD.fieldApiName] = accountNumber;
        }
        if (companyName) {
            fields[COMPANY_NAME_FIELD.fieldApiName] = companyName;
        }
        if (address) {
            fields[ADDRESS_FIELD.fieldApiName] = address;
        }
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