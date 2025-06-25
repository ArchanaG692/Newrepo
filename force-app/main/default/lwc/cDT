import { LightningElement, api, wire, track } from 'lwc';
import getCSVData from '@salesforce/apex/CSVDataController.getCSVData';

const PAGE_SIZE = 5; // Display 5 rows per page

export default class CsvDataTable extends LightningElement {
    @api recordId;
    @track data = [];
    @track columns = [];
    @track summaryData = [];
    @track filteredData = [];
    @track paginatedData = [];
    @track paginatedFilteredData = [];
    @track isModalOpen = false;
    @track modalTitle = '';

    // Pagination variables
    currentPage = 1;
    totalPages = 1;
    disablePrev = true;
    disableNext = true;

    modalCurrentPage = 1;
    modalTotalPages = 1;
    disablePrevModal = true;
    disableNextModal = true;

    // Table columns for summary data
    summaryColumns = [
        { label: 'Violation Type', fieldName: 'category', type: 'text' },
        { 
            label: 'Count', 
            fieldName: 'count', 
            type: 'button', 
            typeAttributes: { 
                label: { fieldName: 'count' }, 
                variant: 'brand', 
                name: 'view_details'
            } 
        }
    ];

    @wire(getCSVData, { caseId: '$recordId' })
    wiredCSVData({ error, data }) {
        if (error) {
            console.error('Error fetching CSV data:', error);
            this.data = [];
            return;
        }

        if (data) {
            this.data = data.csvData || [];
            this.setPagination();

            if (this.data.length > 0) {
                this.columns = Object.keys(this.data[0]).map(field => ({
                    label: field.replace(/_/g, ' '),
                    fieldName: field,
                    type: 'text'
                }));
            }

            // Ensure all counts are valid
            this.summaryData = [
                { category: 'Total Apex Class Violations', count: data.clsViolationCount || 0, filterType: 'apex' },
                { category: 'Total LWC Violations', count: data.lwcViolationCount || 0, filterType: 'lwc' },
                { category: 'Total Aura Violations', count: data.auraViolationCount || 0, filterType: 'aura' },
                { category: 'Total Objects Violations', count: data.objectsViolationCount || 0, filterType: 'objects' }
            ];
        }
    }

    // Handle Click Event for Filtering Data in Modal
    handleRowAction(event) {
        const row = event.detail.row;

        if (row.filterType === 'apex') {
            this.modalTitle = 'Apex Class Violations';
            this.filteredData = this.data.filter(item => item.File && item.File.includes('classes'));
        } else if (row.filterType === 'lwc') {
            this.modalTitle = 'LWC Violations';
            this.filteredData = this.data.filter(item => item.File && item.File.includes('lwc'));
        } else if (row.filterType === 'aura') {
            this.modalTitle = 'Aura Violations';
            this.filteredData = this.data.filter(item => item.File && item.File.includes('aura'));
        } else if (row.filterType === 'objects') {
            this.modalTitle = 'Objects Violations';
            this.filteredData = this.data.filter(item => item.File && item.File.includes('objects'));
        }

        this.setModalPagination();
        this.isModalOpen = true;
    }

    // Ensure pagination works
    setPagination() {
        this.totalPages = Math.ceil(this.data.length / PAGE_SIZE);
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    updatePaginatedData() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.paginatedData = this.data.slice(start, end);

        this.disablePrev = this.currentPage === 1;
        this.disableNext = this.currentPage === this.totalPages;
    }

    // Pagination for modal
    setModalPagination() {
        this.modalTotalPages = Math.ceil(this.filteredData.length / PAGE_SIZE);
        this.modalCurrentPage = 1;
        this.updatePaginatedFilteredData();
    }

    updatePaginatedFilteredData() {
        const start = (this.modalCurrentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.paginatedFilteredData = this.filteredData.slice(start, end);

        this.disablePrevModal = this.modalCurrentPage === 1;
        this.disableNextModal = this.modalCurrentPage === this.modalTotalPages;
    }

    // Close Modal
    closeModal() {
        this.isModalOpen = false;
        this.filteredData = [];
    }
}
