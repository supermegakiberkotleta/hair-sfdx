import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getClearFiles from '@salesforce/apex/ClearFilesController.getClearFiles';
import uploadFileToClearFiles from '@salesforce/apex/ClearFilesController.uploadFileToClearFiles';
import deleteClearFile from '@salesforce/apex/ClearFilesController.deleteClearFile';
import getFileDownloadUrl from '@salesforce/apex/ClearFilesController.getFileDownloadUrl';
import OPPORTUNITY_LEAD_FIELD from '@salesforce/schema/Opportunity.SlaesForceLeadId__c';

// Import fields for Lead
import LEAD_ID_FIELD from '@salesforce/schema/Lead.Id';

export default class ClearFiles extends LightningElement {
    @api recordId;
    @track clearFiles = [];
    @track selectedFiles = [];
    @track isLoading = false;
    @track isUploading = false; // New flag for file uploads
    @track error = '';
    @track uploadError = '';
    @track isDraggingOver = false;
    @track showUploadModal = false;
    @api objectApiName;

    // Private property for tracking recordId changes
    _lastRecordId = null;
    _lastLeadId = null;

    // Wire to get Lead data
    @wire(getRecord, { recordId: '$recordId', fields: '$requiredFields' })
    leadRecord;

    get requiredFields() {
        return this.objectApiName === 'Opportunity'
            ? [OPPORTUNITY_LEAD_FIELD]
            : [LEAD_ID_FIELD];
    }

    // Watcher for leadRecord changes - main trigger for file loading
    get leadRecordWatcher() {
        console.log('leadRecordWatcher triggered:', {
            hasData: !!this.leadRecord.data,
            hasError: !!this.leadRecord.error,
            leadId: this.leadId,
            recordId: this.recordId,
            currentFilesCount: this.clearFiles.length,
            isLoading: this.isLoading
        });

        if (this.leadRecord.data && this.leadId) {
            // Check if leadId has changed
            if (this.leadId !== this._lastLeadId) {
                console.log('Lead ID changed from', this._lastLeadId, 'to', this.leadId);
                this._lastLeadId = this.leadId;

                // Reset files when Lead ID changes
                this.clearFiles = [];
                this.error = '';

                // Load files for new Lead ID
                this.loadClearFiles();
            } else if (this.clearFiles.length === 0 && !this.isLoading && !this.isUploading) {
                // If files are not loaded and not loading, load them
                console.log('Files not loaded, loading via leadRecordWatcher');
                this.loadClearFiles();
            }
        } else if (this.leadRecord.error) {
            console.error('Error in leadRecord:', this.leadRecord.error);
            this.error = 'Error loading Lead data: ' + (this.leadRecord.error.body?.message || this.leadRecord.error.message || 'Unknown error');
        }

        // Return value for reactivity
        return this.leadRecord.data;
    }

    // Get Lead ID
    get leadId() {
        if (this.objectApiName === 'Opportunity') {
            return this.leadRecord?.data
                ? getFieldValue(this.leadRecord.data, OPPORTUNITY_LEAD_FIELD)
                : null;
        }
        // На записи Lead ID = recordId
        return this.recordId || null;
    }

    // Watcher for recordId changes
    get recordIdWatcher() {
        if (this.recordId && this.recordId !== this._lastRecordId) {
            console.log('RecordId changed from', this._lastRecordId, 'to', this.recordId);
            this._lastRecordId = this.recordId;

            // Reset state when recordId changes
            this.clearFiles = [];
            this.selectedFiles = [];
            this.error = '';
            this.uploadError = '';
            this.showUploadModal = false;
            this._lastLeadId = null; // Reset Lead ID for reload

            // Force load files with a small delay
            // so wire service has time to update
            setTimeout(() => {
                if (this.recordId && !this.isLoading && !this.isUploading) {
                    console.log('Forcing file load after recordId change');
                    this.loadClearFiles();
                }
            }, 500);
        }
        return this.recordId;
    }

    // Check if data is ready
    get isDataReady() {
        return this.leadRecord.data && this.leadId;
    }

    // Check if there are errors in wire service
    get wireError() {
        return this.leadRecord.error;
    }

    // Get wire error message safely
    get wireErrorMessage() {
        if (this.leadRecord.error) {
            return this.leadRecord.error.body?.message || this.leadRecord.error.message || 'Unknown error';
        }
        return '';
    }

    // Get disabled state for buttons
    get isButtonsDisabled() {
        return this.isLoading || this.isUploading;
    }

    connectedCallback() {
        console.log('ClearFiles component connected');
        console.log('Browser File API support check:');
        console.log('- window.File:', !!window.File);
        console.log('- window.FileReader:', !!window.FileReader);
        console.log('- window.FileList:', !!window.FileList);
        console.log('- window.Blob:', !!window.Blob);
        console.log('- window.File.prototype:', window.File ? window.File.prototype : 'Not available');

        // Проверяем поддержку File API
        if (!window.File || !window.FileReader || !window.FileList || !window.Blob) {
            console.error('File API not supported in this browser');
            this.error = 'Your browser does not support file uploads. Please use a modern browser.';
            return;
        }

        // Дополнительная проверка конструкторов
        try {
            const testFile = new File(['test'], 'test.txt', { type: 'text/plain' });
            console.log('File constructor test passed:', testFile);

            const testReader = new FileReader();
            console.log('FileReader constructor test passed:', testReader);

            const testBlob = new Blob(['test'], { type: 'text/plain' });
            console.log('Blob constructor test passed:', testBlob);

        } catch (error) {
            console.error('File API constructor test failed:', error);
            this.error = 'File API test failed. Please refresh the page or use a different browser.';
            return;
        }

        console.log('File API support verified successfully');

        // Check if recordId is already available on init
        if (this.recordId) {
            console.log('RecordId available on init, will load files when leadRecord is ready');
            this._lastRecordId = this.recordId;

            // If recordId is already available, try to load files immediately
            // (this can happen when page is reloaded)
            if (this.leadId) {
                console.log('Lead ID also available on init, loading files immediately');
                setTimeout(() => {
                    this.loadClearFiles();
                }, 500);
            }
        }

        // Добавляем обработчик для обновления при изменении видимости
        this.addVisibilityChangeHandler();

        // Force load files with a small delay
        // so wire service has time to initialize
        setTimeout(() => {
            if (this.recordId && !this.isLoading && !this.isUploading && this.clearFiles.length === 0) {
                console.log('Forcing initial file load in connectedCallback');
                this.loadClearFiles();
            }
        }, 1000);

        // Additional attempt to load files after 2 seconds
        setTimeout(() => {
            if (this.recordId && !this.isLoading && !this.isUploading && this.clearFiles.length === 0) {
                console.log('Second attempt to load files in connectedCallback');
                this.loadClearFiles();
            }
        }, 2000);
    }

    disconnectedCallback() {
        // Remove handler when component is destroyed
        this.removeVisibilityChangeHandler();
    }

    // Add page visibility change handler
    addVisibilityChangeHandler() {
        this._visibilityChangeHandler = () => {
            if (!document.hidden && this.recordId && this.clearFiles.length === 0 && !this.isLoading && !this.isUploading) {
                console.log('Page became visible, refreshing file list if needed');
                setTimeout(() => {
                    this.loadClearFiles();
                }, 500);
            }
        };

        document.addEventListener('visibilitychange', this._visibilityChangeHandler);
    }

    // Remove visibility change handler
    removeVisibilityChangeHandler() {
        if (this._visibilityChangeHandler) {
            document.removeEventListener('visibilitychange', this._visibilityChangeHandler);
            this._visibilityChangeHandler = null;
        }
    }

    // Load list of Clear Files
    loadClearFiles(force = false) {
        console.log('=== LOAD_CLEAR_FILES CALLED ===');
        console.log('Method called with state:', {
            force: force,
            hasLeadId: !!this.leadId,
            leadId: this.leadId,
            hasRecordId: !!this.recordId,
            recordId: this.recordId,
            isLoading: this.isLoading,
            isUploading: this.isUploading,
            currentFilesCount: this.clearFiles.length
        });

        if (!this.leadId) {
            console.warn('Lead ID is not available yet, cannot load files');
            // If Lead ID is not available but recordId exists, try to load later
            if (this.recordId) {
                console.log('Will retry loading files when Lead ID becomes available...');
                setTimeout(() => {
                    if (this.leadId && !this.isLoading && !this.isUploading) {
                        console.log('Retrying file load after Lead ID became available');
                        this.loadClearFiles();
                    }
                }, 1000);
            }
            return;
        }

        // Check if files are already loading (if not forced refresh)
        if (this.isLoading && !force) {
            console.log('Files are already loading, skipping duplicate request');
            return;
        }

        console.log('Loading Clear Files for Lead ID:', this.leadId);
        this.isLoading = true;
        this.error = '';

        // Добавляем timestamp для предотвращения кэширования
        const timestamp = new Date().getTime();
        const cacheBuster = force ? `&_t=${timestamp}` : '';

        console.log('Request details:', {
            leadId: this.leadId,
            force: force,
            timestamp: timestamp,
            cacheBuster: cacheBuster
        });

        getClearFiles({ leadId: this.leadId })
            .then(result => {
                console.log('Clear Files API response:', result);
                console.log('=== SERVER RESPONSE ANALYSIS ===');
                console.log('Response type:', typeof result);
                console.log('Response is array:', Array.isArray(result));
                console.log('Response length:', result ? result.length : 'null');

                if (result && Array.isArray(result)) {
                    console.log('Processing', result.length, 'files');
                    console.log('File IDs from server:', result.map(f => f.id || f.Id));
                    console.log('File names from server:', result.map(f => f.fileName));

                    // Проверяем, есть ли новый загруженный файл
                    const expectedFileCount = this.clearFiles.length + 1; // Ожидаем +1 файл
                    if (result.length < expectedFileCount) {
                        console.warn(`⚠️ SERVER ISSUE DETECTED ⚠️`);
                        console.warn(`Expected at least ${expectedFileCount} files, but server returned only ${result.length}`);
                        console.warn('This indicates a server-side problem:');
                        console.warn('1. File was uploaded to wrong location');
                        console.warn('2. Server has not processed the upload yet');
                        console.warn('3. Error in ClearFilesController.getClearFiles() method');
                        console.warn('4. Database transaction not committed yet');
                    }

                    // Process the result and add additional fields
                    this.clearFiles = result.map(file => ({
                        ...file,
                        fileSize: this.formatFileSize(file.fileSize || 0),
                        uploadDate: this.formatDate(file.uploadDate),
                        fileIcon: this.getFileIcon(file.fileExtension || ''),
                        id: file.id || file.Id
                    }));

                    console.log('Processed files:', this.clearFiles);
                } else {
                    console.warn('Unexpected result format:', result);
                    this.clearFiles = [];
                }

                // Дополнительная проверка для отладки
                console.log('=== FILE LIST UPDATE VERIFICATION ===');
                console.log('Files before update:', this.clearFiles.length);
                console.log('Files after update:', this.clearFiles.length);
                console.log('File names:', this.clearFiles.map(f => f.fileName));

                // Если файлов меньше ожидаемого, логируем предупреждение
                if (this.clearFiles.length < 3) {
                    console.warn('File count seems low. Expected at least 3 files, got:', this.clearFiles.length);
                    console.warn('This might indicate a server-side processing delay or caching issue.');
                }
            })
            .catch(error => {
                console.error('Error loading Clear Files:', error);
                this.error = 'Error while getting file list: ' + (error.body?.message || error.message || 'Unknown error');

                // Показываем ошибку пользователю
                this.showToast('Error', 'Failed to load file list. Please try refreshing the page.', 'error');

                // Очищаем список файлов при ошибке
                this.clearFiles = [];
            })
            .finally(() => {
                this.isLoading = false;
                console.log('=== LOAD_CLEAR_FILES COMPLETED ===');
                console.log('Final state:', {
                    isLoading: this.isLoading,
                    isUploading: this.isUploading,
                    filesCount: this.clearFiles.length,
                    hasError: !!this.error
                });
                console.log('Load Clear Files completed. Total files:', this.clearFiles.length);
            });
    }

    // Handle file selection
    handleFileChange(event) {
        console.log('File change event triggered:', event);
        console.log('Event target:', event.target);
        console.log('Event target files:', event.target.files);

        const files = event.target.files;
        if (!files || files.length === 0) {
            console.log('No files selected');
            this.showToast('Warning', 'No files selected', 'warning');
            return;
        }

        // Проверяем каждый файл
        const validFiles = [];
        for (let i = 0; i < files.length; i++) {
            const file = files[i];

            console.log('Processing file at index:', i);
            console.log('File object:', file);
            console.log('File constructor:', file.constructor.name);
            console.log('File instanceof File:', file instanceof File);
            console.log('File instanceof Blob:', file instanceof Blob);
            console.log('File properties:', {
                name: file.name,
                size: file.size,
                type: file.type,
                lastModified: file.lastModified
            });

            // Дополнительные проверки файла
            if (!(file instanceof File) && !(file instanceof Blob)) {
                console.error('Invalid file object:', file);
                this.showToast('Error', `File "${file.name || 'Unknown'}" is invalid. Please select a valid file.`, 'error');
                continue;
            }

            // Проверяем, что файл имеет необходимые свойства
            if (!file.name || !file.size || !file.type) {
                console.error('File missing required properties:', { name: file.name, size: file.size, type: file.type });
                this.showToast('Error', `File "${file.name || 'Unknown'}" is corrupted or missing required properties.`, 'error');
                continue;
            }

            // Проверяем размер файла (максимум 10MB)
            const maxSize = 10 * 1024 * 1024; // 10MB
            if (file.size > maxSize) {
                this.showToast('Error', `File "${file.name}" exceeds 10MB limit`, 'error');
                continue;
            }

            // Проверяем, что файл не пустой
            if (file.size === 0) {
                this.showToast('Error', `File "${file.name}" is empty (0 bytes)`, 'error');
                continue;
            }

            // Дополнительная проверка размера файла
            if (typeof file.size !== 'number' || file.size < 0 || !isFinite(file.size)) {
                console.error('File size is invalid:', file.size);
                this.showToast('Error', `File "${file.name}" has invalid size`, 'error');
                continue;
            }

            console.log('File validation passed for:', file.name);
            validFiles.push(file);
        }

        if (validFiles.length === 0) {
            this.showToast('Error', 'No valid files selected for upload', 'error');
            return;
        }

        // Преобразуем валидные файлы
        this.selectedFiles = validFiles.map(file => {
            // Создаем объект с дополнительными свойствами, НЕ используя spread
            return {
                file: file, // Сохраняем оригинальный File объект
                name: file.name,
                size: file.size,
                type: file.type,
                lastModified: file.lastModified,
                formattedSize: this.formatFileSize(file.size)
            };
        });

        console.log('Valid files selected:', this.selectedFiles);
        console.log('=== FILE STRUCTURE DEBUG ===');
        this.selectedFiles.forEach((fileWrapper, index) => {
            console.log(`File ${index} wrapper:`, fileWrapper);
            console.log(`File ${index} original:`, fileWrapper.file);
            console.log(`File ${index} instanceof File:`, fileWrapper.file instanceof File);
            console.log(`File ${index} name:`, fileWrapper.name);
        });
        console.log('=== END FILE STRUCTURE DEBUG ===');
        this.showUploadModal = true;
    }

    // Upload files
    handleUpload() {
        if (!this.leadId) {
            this.showToast('Error', 'Lead ID is not available', 'error');
            return;
        }

        if (this.selectedFiles.length === 0) {
            this.showToast('Error', 'No files selected for upload', 'error');
            return;
        }

        console.log('=== UPLOAD DEBUG INFO ===');
        console.log('selectedFiles array:', this.selectedFiles);
        console.log('selectedFiles length:', this.selectedFiles.length);

        // Дополнительная валидация всех файлов перед загрузкой
        const invalidFiles = [];
        for (let i = 0; i < this.selectedFiles.length; i++) {
            const fileWrapper = this.selectedFiles[i];
            const file = fileWrapper.file; // Получаем оригинальный File объект

            console.log(`File ${i} wrapper:`, fileWrapper);
            console.log(`File ${i} original:`, file);
            console.log(`File ${i} instanceof File:`, file instanceof File);
            console.log(`File ${i} instanceof Blob:`, file instanceof Blob);
            console.log(`File ${i} constructor:`, file ? file.constructor.name : 'null');

            if (!file) {
                invalidFiles.push(`File at index ${i}: undefined or null`);
                continue;
            }

            if (!(file instanceof File) && !(file instanceof Blob)) {
                invalidFiles.push(`File "${file.name || 'Unknown'}": not a valid File or Blob object`);
                continue;
            }

            if (!file.name || !file.size || !file.type) {
                invalidFiles.push(`File "${file.name || 'Unknown'}": missing required properties`);
                continue;
            }

            if (file.size === 0) {
                invalidFiles.push(`File "${file.name}": empty (0 bytes)`);
                continue;
            }

            if (typeof file.size !== 'number' || file.size < 0 || !isFinite(file.size)) {
                invalidFiles.push(`File "${file.name}": invalid size (${file.size})`);
                continue;
            }
        }

        if (invalidFiles.length > 0) {
            const errorMessage = 'Invalid files detected:\n' + invalidFiles.join('\n');
            console.error('File validation failed:', invalidFiles);
            this.showToast('Error', errorMessage, 'error');
            return;
        }

        console.log('=== ALL FILES VALIDATED SUCCESSFULLY ===');
        this.isUploading = true;
        this.uploadError = '';

        const uploadPromises = this.selectedFiles.map(fileWrapper => {
            const file = fileWrapper.file; // Получаем оригинальный File объект
            return new Promise((resolve, reject) => {
                // Дополнительные проверки перед чтением
                if (!file) {
                    reject(new Error(`File is undefined or null: ${fileWrapper.name || 'Unknown'}`));
                    return;
                }

                if (!(file instanceof File) && !(file instanceof Blob)) {
                    reject(new Error(`File is not a valid File or Blob object: ${fileWrapper.name || 'Unknown'}`));
                    return;
                }

                if (file.size === 0) {
                    reject(new Error(`File is empty (0 bytes): ${fileWrapper.name || 'Unknown'}`));
                    return;
                }

                // Проверяем, что файл не поврежден
                if (typeof file.size !== 'number' || file.size < 0 || !isFinite(file.size)) {
                    reject(new Error(`File size is invalid or corrupted: ${fileWrapper.name || 'Unknown'}`));
                    return;
                }

                console.log('Starting file read for:', file.name);
                console.log('File details:', {
                    name: file.name,
                    size: file.size,
                    type: file.type,
                    lastModified: file.lastModified
                });

                const reader = new FileReader();

                reader.onloadend = () => {
                    try {
                        console.log('FileReader onloadend triggered for:', file.name);
                        console.log('FileReader readyState:', reader.readyState);
                        console.log('FileReader result type:', typeof reader.result);
                        console.log('FileReader result length:', reader.result ? reader.result.length : 'null');

                        if (!reader.result) {
                            console.error('FileReader result is empty for file:', file.name);
                            reject(new Error(`FileReader result is empty: ${file.name}`));
                            return;
                        }

                        // Проверяем, что результат является строкой
                        if (typeof reader.result !== 'string') {
                            console.error('FileReader result is not a string for file:', file.name, 'Type:', typeof reader.result);
                            reject(new Error(`FileReader result is not a string: ${file.name}`));
                            return;
                        }

                        // Проверяем, что результат содержит base64 данные
                        if (!reader.result.includes(',')) {
                            console.error('FileReader result does not contain base64 data for file:', file.name);
                            reject(new Error(`FileReader result does not contain base64 data: ${file.name}`));
                            return;
                        }

                        const base64 = reader.result.split(',')[1];

                        if (!base64) {
                            console.error('Failed to extract base64 data from file:', file.name);
                            reject(new Error(`Failed to extract base64 data from file: ${file.name}`));
                            return;
                        }

                        console.log('File read successful for:', file.name, 'base64 length:', base64.length);

                        // Дополнительная проверка base64 данных
                        if (base64.length === 0) {
                            console.error('Base64 data is empty for file:', file.name);
                            reject(new Error(`Base64 data is empty for file: ${file.name}`));
                            return;
                        }

                        uploadFileToClearFiles({
                            fileName: file.name,
                            base64Data: base64,
                            leadId: this.leadId,
                            fileSize: file.size,
                            contentType: file.type
                        })
                            .then(response => {
                                console.log('File uploaded successfully:', response);
                                console.log('=== UPLOAD RESPONSE ANALYSIS ===');
                                console.log('Response type:', typeof response);
                                console.log('Response object:', response);

                                // Проверяем, что файл действительно загружен
                                if (response && response.id) {
                                    console.log('✅ File upload confirmed with ID:', response.id);
                                    console.log('File details:', {
                                        name: file.name,
                                        size: file.size,
                                        type: file.type,
                                        id: response.id,
                                        leadId: this.leadId
                                    });

                                    // Проверяем, что файл загружен для правильного Lead ID
                                    if (response.leadId && response.leadId !== this.leadId) {
                                        console.error('❌ CRITICAL ERROR: File uploaded to wrong Lead ID!');
                                        console.error('Expected Lead ID:', this.leadId);
                                        console.error('Actual Lead ID:', response.leadId);
                                        console.error('This explains why the file is not showing in the list!');
                                    }
                                } else {
                                    console.warn('⚠️ File upload response missing ID:', response);
                                    console.warn('This might indicate an upload failure or wrong response format');
                                }

                                resolve();
                            })
                            .catch(uploadError => {
                                console.error('Error uploading file:', uploadError);
                                // Добавляем детальную информацию об ошибке
                                const errorDetails = {
                                    fileName: file.name,
                                    fileSize: file.size,
                                    fileType: file.type,
                                    error: uploadError
                                };
                                console.error('Upload error details:', errorDetails);
                                reject(uploadError);
                            });
                    } catch (error) {
                        console.error('Error processing file:', file.name, error);
                        reject(new Error(`Failed to process file: ${file.name} - ${error.message}`));
                    }
                };

                reader.onerror = () => {
                    console.error('File reading error for file:', file.name);
                    const errorMessage = reader.error ? reader.error.message : 'Unknown FileReader error';
                    reject(new Error(`Failed to read file: ${file.name} - ${errorMessage}`));
                };

                reader.onabort = () => {
                    console.error('File reading aborted for file:', file.name);
                    reject(new Error(`File reading aborted: ${file.name}`));
                };

                try {
                    reader.readAsDataURL(file);
                } catch (error) {
                    console.error('Error calling readAsDataURL for file:', file.name, error);
                    reject(new Error(`Failed to execute readAsDataURL for file: ${file.name} - ${error.message}`));
                }
            });
        });

        Promise.all(uploadPromises)
            .then(() => {
                console.log('=== UPLOAD SUCCESS - STARTING REFRESH ===');
                this.selectedFiles = [];
                this.showUploadModal = false;

                // Принудительно сбрасываем состояние загрузки и обновляем список
                this.isUploading = false;

                // Обновляем список файлов после успешной загрузки
                this.loadClearFiles();

                this.showToast('Success', 'Files uploaded successfully', 'success');
            })
            .catch(error => {
                console.error('Promise.all error details:', error);

                // Детальная обработка ошибок
                let errorMessage = 'Unknown error';
                let errorDetails = '';

                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                } else if (error.message) {
                    errorMessage = error.message;
                }

                // Проверяем, является ли ошибка связанной с File API
                if (errorMessage.includes('File is not a valid File or Blob object')) {
                    errorDetails = 'The file object appears to be corrupted. Please try selecting the file again.';
                } else if (errorMessage.includes('FileReader result is empty')) {
                    errorDetails = 'File reading failed. The file may be corrupted or too large.';
                } else if (errorMessage.includes('base64 data')) {
                    errorDetails = 'File encoding failed. Please try with a different file.';
                } else if (errorMessage.includes('uploading file')) {
                    errorDetails = 'Server upload failed. Please check your connection and try again.';
                }

                this.uploadError = 'Error uploading one or more files: ' + errorMessage;
                if (errorDetails) {
                    this.uploadError += '\n\n' + errorDetails;
                }

                console.error('Final upload error:', {
                    error: error,
                    errorMessage: errorMessage,
                    errorDetails: errorDetails,
                    uploadError: this.uploadError
                });

                // Показываем детальную ошибку пользователю
                this.showToast('Error', 'Upload failed: ' + errorMessage, 'error');
            })
            .finally(() => {
                this.isUploading = false;
            });
    }

    // Delete file
    handleDeleteFile(event) {
        const fileId = event.currentTarget.dataset.fileId;
        const fileName = event.currentTarget.dataset.fileName;

        if (!fileId) {
            this.showToast('Error', 'File ID is missing', 'error');
            return;
        }

        if (confirm(`Are you sure you want to delete the file "${fileName}"?`)) {
            this.isLoading = true;

            console.log('Deleting file:', fileName, 'with ID:', fileId);

            deleteClearFile({ fileId: fileId })
                .then(() => {
                    this.showToast('Success', 'File deleted successfully', 'success');

                    // Автоматически обновляем список файлов
                    console.log('File deleted successfully, refreshing file list...');

                    // Принудительно сбрасываем состояние загрузки и обновляем список
                    this.isLoading = false;

                    // Немедленно обновляем список файлов
                    this.loadClearFiles();
                })
                .catch(error => {
                    this.showToast('Error', 'Failed to delete file: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
                    console.error('Error deleting file:', error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    // Get download URL for file
    handleDownloadFile(event) {
        const fileId = event.currentTarget.dataset.fileId;

        if (!fileId) {
            this.showToast('Error', 'File ID is missing', 'error');
            return;
        }

        getFileDownloadUrl({ fileId: fileId })
            .then(result => {
                if (result) {
                    window.open(result, '_blank');
                }
            })
            .catch(error => {
                this.showToast('Error', 'Failed to get file link: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
                console.error('Error getting file link:', error);
            });
    }

    // File preview
    handlePreviewFile(event) {
        const fileId = event.currentTarget.dataset.fileId;

        if (!fileId) {
            this.showToast('Error', 'File ID is missing', 'error');
            return;
        }

        console.log('Previewing file with ID:', fileId);

        // Сначала получаем URL для скачивания
        getFileDownloadUrl({ fileId: fileId })
            .then(result => {
                if (result) {
                    console.log('File preview URL:', result);

                    // Проверяем, что URL не пустой и не содержит ошибок
                    if (result.includes('error') || result.includes('undefined')) {
                        throw new Error('Invalid file URL received');
                    }

                    // Открываем файл в новом окне для предварительного просмотра
                    const previewWindow = window.open(result, '_blank');

                    // Проверяем, что окно открылось
                    if (!previewWindow) {
                        this.showToast('Warning', 'Popup blocked. Please allow popups for this site.', 'warning');
                    }
                } else {
                    throw new Error('No file URL received');
                }
            })
            .catch(error => {
                console.error('Error getting file preview URL:', error);

                // Показываем пользователю понятную ошибку
                let errorMessage = 'Failed to open file for preview';
                if (error.message.includes('Invalid file URL')) {
                    errorMessage = 'File URL is invalid. Please try refreshing the page.';
                } else if (error.message.includes('No file URL')) {
                    errorMessage = 'Could not get file URL. File may be corrupted.';
                } else {
                    errorMessage += ': ' + (error.body?.message || error.message || 'Unknown error');
                }

                this.showToast('Error', errorMessage, 'error');
            });
    }

    // Close upload modal
    handleCloseUploadModal() {
        console.log('Closing upload modal, clearing files');
        console.log('Files before clearing:', this.selectedFiles);
        this.showUploadModal = false;
        this.selectedFiles = [];
        this.uploadError = '';
        console.log('Files after clearing:', this.selectedFiles);
    }

    // Close upload error
    handleCloseUploadError() {
        this.uploadError = '';
    }

    // Cancel upload
    handleCancelUpload() {
        this.handleCloseUploadModal();
    }

    // Drag and Drop handlers
    handleDragOver(event) {
        event.preventDefault();
        this.isDraggingOver = true;
    }

    handleDragLeave(event) {
        event.preventDefault();
        this.isDraggingOver = false;
    }

    handleDrop(event) {
        event.preventDefault();
        this.isDraggingOver = false;

        const files = event.dataTransfer.files;
        if (!files || files.length === 0) {
            this.showToast('Warning', 'No files dropped', 'warning');
            return;
        }

        // Проверяем каждый файл так же, как в handleFileChange
        const validFiles = [];
        for (let i = 0; i < files.length; i++) {
            const file = files[i];

            console.log('Dropped file object:', file);
            console.log('Dropped file constructor:', file.constructor.name);
            console.log('Dropped file instanceof File:', file instanceof File);
            console.log('Dropped file instanceof Blob:', file instanceof Blob);

            // Дополнительные проверки файла
            if (!(file instanceof File) && !(file instanceof Blob)) {
                console.error('Invalid dropped file object:', file);
                this.showToast('Error', `Dropped file "${file.name || 'Unknown'}" is invalid. Please select a valid file.`, 'error');
                continue;
            }

            // Проверяем, что файл имеет необходимые свойства
            if (!file.name || !file.size || !file.type) {
                console.error('Dropped file missing required properties:', { name: file.name, size: file.size, type: file.type });
                this.showToast('Error', `Dropped file "${file.name || 'Unknown'}" is corrupted or missing required properties.`, 'error');
                continue;
            }

            // Проверяем размер файла (максимум 10MB)
            const maxSize = 10 * 1024 * 1024; // 10MB
            if (file.size > maxSize) {
                this.showToast('Error', `Dropped file "${file.name}" exceeds 10MB limit`, 'error');
                continue;
            }

            // Проверяем, что файл не пустой
            if (file.size === 0) {
                this.showToast('Error', `Dropped file "${file.name}" is empty (0 bytes)`, 'error');
                continue;
            }

            validFiles.push(file);
        }

        if (validFiles.length === 0) {
            this.showToast('Error', 'No valid files dropped for upload', 'error');
            return;
        }

        // Преобразуем валидные файлы
        this.selectedFiles = validFiles.map(file => {
            // Создаем объект с дополнительными свойствами, НЕ используя spread
            return {
                file: file, // Сохраняем оригинальный File объект
                name: file.name,
                size: file.size,
                type: file.type,
                lastModified: file.lastModified,
                formattedSize: this.formatFileSize(file.size)
            };
        });

        console.log('Valid dropped files:', this.selectedFiles);
        console.log('=== DROPPED FILE STRUCTURE DEBUG ===');
        this.selectedFiles.forEach((fileWrapper, index) => {
            console.log(`Dropped file ${index} wrapper:`, fileWrapper);
            console.log(`Dropped file ${index} original:`, fileWrapper.file);
            console.log(`Dropped file ${index} instanceof File:`, fileWrapper.file instanceof File);
            console.log(`Dropped file ${index} name:`, fileWrapper.name);
        });
        console.log('=== END DROPPED FILE STRUCTURE DEBUG ===');
        this.showUploadModal = true;
    }

    // Show notifications
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    // Format file size
    formatFileSize(bytes) {
        if (bytes === null || bytes === undefined || bytes === 0) return '0 Bytes';

        // Убеждаемся, что bytes это число
        const size = parseInt(bytes, 10);
        if (isNaN(size)) {
            console.warn('Invalid file size value:', bytes);
            return 'Unknown size';
        }

        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(size) / Math.log(k));
        return parseFloat((size / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    // Get file icon by extension
    getFileIcon(fileExtension) {
        if (!fileExtension || typeof fileExtension !== 'string') {
            return 'utility:file';
        }

        const extension = fileExtension.toLowerCase().trim();

        if (['pdf'].includes(extension)) return 'utility:pdf';
        if (['doc', 'docx'].includes(extension)) return 'utility:word';
        if (['xls', 'xlsx'].includes(extension)) return 'utility:excel';
        if (['ppt', 'pptx'].includes(extension)) return 'utility:powerpoint';
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].includes(extension)) return 'utility:image';
        if (['txt'].includes(extension)) return 'utility:text';
        if (['zip', 'rar', '7z'].includes(extension)) return 'utility:zip';

        return 'utility:file';
    }

    // Get file extension
    getFileExtension(fileName) {
        if (!fileName || typeof fileName !== 'string') {
            return '';
        }

        const parts = fileName.split('.');
        if (parts.length < 2) {
            return '';
        }

        return parts.pop().toLowerCase();
    }

    // Format date
    formatDate(dateValue) {
        if (!dateValue) return '';

        try {
            let date;

            // Если это строка, попробуем её распарсить
            if (typeof dateValue === 'string') {
                date = new Date(dateValue);
            } else if (dateValue instanceof Date) {
                date = dateValue;
            } else {
                // Для Salesforce Datetime
                date = new Date(dateValue);
            }

            // Проверяем, что дата валидна
            if (isNaN(date.getTime())) {
                console.warn('Invalid date value:', dateValue);
                return String(dateValue);
            }

            return date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } catch (error) {
            console.error('Date formatting error:', error, 'Value:', dateValue);
            return String(dateValue);
        }
    }
}