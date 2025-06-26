import { LightningElement, track, wire } from 'lwc';
import getAllFiles from '@salesforce/apex/FileController.getAllFiles';
import getFileContent from '@salesforce/apex/FileController.getFileContent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileDataTable extends LightningElement {
    @track files = [];
    @track selectedFileId = '';
    @track tableData = [];
    @track columns = [];
    @track isLoading = false;

    // Pagination Variables
    @track page = 1;
    @track totalPages = 1;
    @track displayedData = [];
    rowsPerPage = 5;

    // Computed properties for button disabling
    get isPrevDisabled() {
        return this.page <= 1;
    }

    get isNextDisabled() {
        return this.page >= this.totalPages;
    }

    // Fetch all files on component load
    @wire(getAllFiles)
    wiredFiles({ error, data }) {
        if (data) {
            this.files = [{ label: '-- Select a File --', value: '' }, ...data.map(file => ({ label: file.Title, value: file.Id }))];
        } else if (error) {
            this.showToast('Error', 'Error fetching files', 'error');
        }
    }

    // Handle file selection
    handleFileChange(event) {
        this.selectedFileId = event.detail.value;
        if (this.selectedFileId) {
            this.fetchFileContent();
        } else {
            this.resetFilter();
        }
    }

    // Fetch file content and parse CSV
    fetchFileContent() {
        if (!this.selectedFileId) return;
        this.isLoading = true;

        getFileContent({ fileId: this.selectedFileId })
            .then(base64Data => {
                let decodedData = atob(base64Data); // Decode Base64
                this.parseCSV(decodedData);
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching file content', 'error');
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Parse CSV content into columns and data
    parseCSV(csvData) {
        let rows = csvData.split('\n').map(row => row.split(','));
        if (rows.length > 1) {
            // Extract column headers
            this.columns = rows[0].map(header => ({
                label: header.trim(),
                fieldName: header.trim(),
                type: 'text'
            }));

            // Extract data rows
            this.tableData = rows.slice(1).map((row, index) => {
                let rowData = { Id: index + 1 };
                this.columns.forEach((col, i) => {
                    rowData[col.fieldName] = row[i]?.trim();
                });
                return rowData;
            });

            // Set up pagination
            this.page = 1;
            this.totalPages = Math.ceil(this.tableData.length / this.rowsPerPage);
            this.updateDisplayedData();
        } else {
            this.showToast('Error', 'Invalid file format', 'error');
        }
    }

    // Update displayed data for current page
    updateDisplayedData() {
        let start = (this.page - 1) * this.rowsPerPage;
        let end = start + this.rowsPerPage;
        this.displayedData = this.tableData.slice(start, end);
    }

    // Go to Previous Page
    previousPage() {
        if (this.page > 1) {
            this.page--;
            this.updateDisplayedData();
        }
    }

    // Go to Next Page
    nextPage() {
        if (this.page < this.totalPages) {
            this.page++;
            this.updateDisplayedData();
        }
    }

    // Reset Filter: Clears selection, table data, and dropdown
    resetFilter() {
        this.selectedFileId = '';
        this.tableData = [];
        this.columns = [];
        this.page = 1;
        this.totalPages = 1;
        this.displayedData = [];
    }

    // Show Toast Message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
