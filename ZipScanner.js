import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import startZipScan from '@salesforce/apex/ZipScanService.startZipScan';
import fetchReportCsv from '@salesforce/apex/ZipScanService.fetchReportCsv';
import saveReportCsvToFiles from '@salesforce/apex/ZipScanService.saveReportCsvToFiles';

export default class ZipScanner extends NavigationMixin(LightningElement) {

    @api recordId;

    acceptedFormats = ['.zip'];

    contentDocumentId;
    reportPath;

    @track working = false;
    @track statusText = '';
    @track error = '';

    @track rows = [];

    // ✅ Store raw CSV for download
    csvText = '';

    @track fileUploaded = false;
    @track uploadedFileName = '';

    columns = [
        { label: 'Problem', fieldName: 'problem' },
        { label: 'Rule', fieldName: 'rule' },
        { label: 'Package', fieldName: 'pkg' },
        { label: 'File', fieldName: 'file' },
        { label: 'Priority', fieldName: 'priority' },
        { label: 'Line', fieldName: 'line' },
        { label: 'Description', fieldName: 'description' }
    ];

    /* Pagination */
    pageSize = 10;
    pageNumber = 1;

    pageSizeOptions = [
        { label: '10', value: 10 },
        { label: '25', value: 25 },
        { label: '50', value: 50 },
        { label: '100', value: 100 }
    ];

    get totalPages() {
        return Math.ceil(this.rows.length / this.pageSize);
    }

    get paginatedRows() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.rows.slice(start, end);
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
        }
    }

    prevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
        }
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.pageNumber = 1;
    }

    /* Summary counts */
    get criticalCount() {
        return this.rows.filter(r => r.priority === '1').length;
    }

    get highCount() {
        return this.rows.filter(r => r.priority === '2').length;
    }

    get mediumCount() {
        return this.rows.filter(r => r.priority === '3').length;
    }

    get lowCount() {
        return this.rows.filter(r => r.priority === '4' || r.priority === '5').length;
    }

    get hasRows() {
        return this.rows && this.rows.length > 0;
    }
    /* Upload */
    handleUploadFinished(event) {
        this.error = '';

        const files = event.detail.files;

        if (files?.length) {

            this.contentDocumentId = files[0].documentId;

            // NEW UI INFO
            this.fileUploaded = true;
            this.uploadedFileName = files[0].name;
        }
    }

    get disableRun() {
        return !this.contentDocumentId || this.working;
    }

    get disableDownload() {
        return !this.csvText || this.working;
    }

    /* Run Scan */
    async runScan() {

        this.error = '';
        this.rows = [];
        this.csvText = '';
        this.pageNumber = 1;

        this.working = true;
        this.statusText = 'Triggering GitHub workflow...';

        try {

            const res = await startZipScan({
                contentDocumentId: this.contentDocumentId
            });

            this.reportPath = res.reportPath;
            this.statusText = res.message + ' (' + this.reportPath + ')';

            await this.pollForReport();

        } catch (e) {

            this.error =
                e?.body?.message ||
                e.message ||
                JSON.stringify(e);

        } finally {
            this.working = false;
        }
    }

    async pollForReport() {

        for (let i = 0; i < 40; i++) {

            this.statusText = `Waiting for report... (${i + 1}/40)`;

            const csv = await fetchReportCsv({
                reportPath: this.reportPath
            });

            if (csv) {

                this.statusText = 'Report ready ✅';

                // ✅ Save raw CSV for download
                this.csvText = csv;

                this.rows = this.parseCsv(csv);
                return;
            }

            await new Promise(r => setTimeout(r, 3000));
        }

        this.statusText = 'Report not found yet. Check GitHub Actions run.';
    }

    // ✅ FIXED DOWNLOAD (LWS safe): Save as Salesforce File then download
    async downloadCsv() {
        try {
            this.error = '';

            if (!this.csvText) {
                this.error = 'CSV not available yet. Please run scan first.';
                return;
            }

            const scanId =
                (this.reportPath || '').includes('scan_')
                    ? (this.reportPath.split('scan_')[1] || '').replace('.csv', '')
                    : String(Date.now());

            const fileName = `Scanner_Report_${scanId}.csv`;

            // Create ContentVersion file
            const contentVersionId = await saveReportCsvToFiles({
                fileName: fileName,
                csvText: this.csvText,
                parentRecordId: this.recordId
            });

            // Download URL (works in Lightning + LWS)
            const downloadUrl = `/sfc/servlet.shepherd/version/download/${contentVersionId}`;

            // Open download
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: downloadUrl
                }
            });

        } catch (e) {
            this.error = 'CSV download failed: ' + (e?.body?.message || e.message || JSON.stringify(e));
        }
    }

    parseCsv(csvText) {

        const lines = csvText.split(/\r?\n/).filter(l => l.trim());
        if (lines.length <= 1) return [];

        const header = this.safeCsvSplit(lines[0]);

        const idx = name =>
            header.findIndex(h => h.trim().toLowerCase() === name.toLowerCase());

        const iRule = idx('rule');
        const iSeverity = idx('severity');
        const iFile = idx('file');
        const iLine = idx('startLine');
        const iMessage = idx('message');
        const iEngine = idx('engine');

        const rows = [];

        for (let r = 1; r < lines.length; r++) {

            const cols = this.safeCsvSplit(lines[r]);

            rows.push({
                id: r,
                problem: cols[iEngine] || '',
                pkg: '',
                file: cols[iFile] || '',
                priority: cols[iSeverity] || '',
                line: cols[iLine] || '',
                description: cols[iMessage] || '',
                rule: cols[iRule] || ''
            });
        }

        return rows;
    }
    safeCsvSplit(line) {

        const out = [];
        let cur = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i++) {

            const ch = line[i];

            if (ch === '"' && line[i + 1] === '"') {
                cur += '"';
                i++;
                continue;
            }

            if (ch === '"') {
                inQuotes = !inQuotes;
                continue;
            }

            if (ch === ',' && !inQuotes) {
                out.push(cur);
                cur = '';
                continue;
            }

            cur += ch;
        }

        out.push(cur);
        return out.map(v => (v || '').trim());
    }
}
