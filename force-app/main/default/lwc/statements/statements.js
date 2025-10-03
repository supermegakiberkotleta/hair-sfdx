import { LightningElement, api, track } from 'lwc';

export default class Statements extends LightningElement {
  @api recordId;
  @track statements;

  connectedCallback() {
    this.fetchStatements();
  }

  async fetchStatements() {
    const url = `https://lenderpro.ai/api/v1/leads/${this.recordId}/statements`;
    const response = await fetch(url);

    if (response.ok) {
      const { statements } = await response.json();
      this.statements = statements;
    }
  }

  handleDownload(event) {
    const { mailId, id } = event.currentTarget.dataset;
    const url = `https://lenderpro.ai/api/v1/mails/${mailId}/attachments/${id}/download`;
    window.open(url, '_blank');
  }
}