import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/FraudMonitoringFileUploader.uploadFile';
import deleteFile from '@salesforce/apex/FraudMonitoringFileUploader.deleteFile';
import getFraudMonitoringFiles from '@salesforce/apex/FraudMonitoringFileUploader.getFraudMonitoringFiles';
import getFileBase64Data from '@salesforce/apex/FraudMonitoringFileUploader.getFileBase64Data';
import getBookUuid from '@salesforce/apex/FraudMonitoringFileUploader.getBookUuid';

export default class FraudMonitoringFilesUploader extends LightningElement {
  @api recordId;
  @track uploadedFiles = [];
  @track bookUuid;
  endpointUrl = 'https://lenderpro.itprofit.net/api/v1/fraud/statement/upload';

  connectedCallback() {
    this.loadFiles();
    this.loadBookUuid();
  }

  async loadFiles() {
    try {
      const files = await getFraudMonitoringFiles({ leadId: this.recordId });
      this.uploadedFiles = files.map(file => ({
        Id: file.Id,
        Title: file.Title,
        FileExtension: file.FileExtension || 'pdf',
        VersionData: file.VersionData,
        ContentDocumentId: file.ContentDocumentId
      }));
    } catch (error) {
      console.error('Error fetching fraud files:', JSON.stringify(error, null, 2));
    }
  }

  async loadBookUuid() {
    try {
      this.bookUuid = await getBookUuid({ leadId: this.recordId });
      console.log('Lead UUID:', this.bookUuid);
    } catch (error) {
      console.error('Error fetching Lead uuid__c:', JSON.stringify(error, null, 2));
    }
  }

  readFileAsDataUrl(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = (e) => reject(e);
      reader.readAsDataURL(file);
    });
  }

  handleFileUpload(event) {
    const files = event.target.files;
    if (!files || files.length === 0) return;
    this.uploadFiles(files);
  }

  async uploadFiles(files) {
    try {
      for (let file of files) {
        const dataUrl = await this.readFileAsDataUrl(file);
        await uploadFile({
          leadId: this.recordId,
          fileName: file.name,
          base64Data: dataUrl
        });
        this.showToast('File Uploaded', `File ${file.name} has been uploaded successfully`, 'success');
      }
      await this.loadFiles();
      console.log('Files uploaded');
    } catch (error) {
      console.error('Upload error', JSON.stringify(error, null, 2));
      this.showToast('Upload Failed', 'File could not be uploaded', 'error');
    }
  }

  async handleDelete(event) {
    const fileId = event.currentTarget.dataset.id;
    const fileName = event.currentTarget.dataset.name;
    try {
      await deleteFile({ contentDocumentId: fileId });
      this.showToast('File Deleted', `The file ${fileName} has been deleted successfully`, 'success');
      await this.loadFiles();
    } catch (error) {
      console.error('Delete error:', JSON.stringify(error, null, 2));
      this.showToast('Delete Failed', `The file ${fileName} could not be deleted`, 'error');
    }
  }

  async handleStartChecking() {
    try {
      if (!this.uploadedFiles || this.uploadedFiles.length === 0) {
        this.showToast('No Files', 'No files available to send', 'warning');
        return;
      }

      if (!this.bookUuid) {
        throw new Error('Lead UUID is not loaded');
      }

      const filesData = [];
      for (const file of this.uploadedFiles) {
        const fileExtension = file.FileExtension || 'pdf';
        const fileName = file.Title.endsWith(`.${fileExtension}`)
          ? file.Title
          : `${file.Title}.${fileExtension}`;

        const fileData = await getFileBase64Data({ fileId: file.ContentDocumentId });

        if (!fileData || typeof fileData !== 'string') {
          throw new Error(`Invalid fileData for ${file.Title}`);
        }

        filesData.push({
          fileName: fileName,
          fileData: fileData
        });
      }
      const payload = {
        leadId: this.recordId,
        uuid: this.bookUuid,
        files: filesData
      };

      const response = await fetch(this.endpointUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP error! Status: ${response.status}, Body: ${errorText}`);
      }

      let result;
      try {
        result = await response.json();
        console.log('Response:', JSON.stringify(result, null, 2));
      } catch (jsonError) {
        console.error('JSON parse error:', jsonError.message);
        throw jsonError;
      }

      this.showToast('Success', `All files sent to endpoint`, 'success');
    } catch (error) {
      console.error('Error sending files:', JSON.stringify(error, null, 2));
      this.showToast('Error', `Failed to send files: ${error.message}`, 'error');
    }
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
}