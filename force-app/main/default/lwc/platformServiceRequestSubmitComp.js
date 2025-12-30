import { LightningElement, track } from 'lwc';
import getConfig from '@salesforce/apex/PlatformRequestController.getConfig';
import createPlatformRequest from '@salesforce/apex/PlatformRequestController.createPlatformRequest';
import finalSubmitRequest from '@salesforce/apex/PlatformRequestController.finalSubmitRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const TYPES = {
    DESIGN: 'Design_Review',
    DATA: 'Data_Model',
    RELEASE: 'Release_Request'
};

export default class PlatformServiceRequestSubmitComp extends LightningElement {
    @track fields = [];
    @track recordTypeIds = {};
    @track values = {}; // api -> value

    active = TYPES.DESIGN;
    ready = false;
    submitting = false;

    // ✅ attachments state
    requestId;
    contentDocumentIds = [];
    uploadedNames = [];

    connectedCallback() {
        this.load();
    }

    /* ---------- tabs ---------- */
    get designCardClass() { return this.active === TYPES.DESIGN ? 'selCard active' : 'selCard'; }
    get dataCardClass() { return this.active === TYPES.DATA ? 'selCard active' : 'selCard'; }
    get releaseCardClass() { return this.active === TYPES.RELEASE ? 'selCard active' : 'selCard'; }

    get activeLabel() {
        if (this.active === TYPES.DESIGN) return 'Design Review';
        if (this.active === TYPES.DATA) return 'Data Model';
        return 'Release Request';
    }

    selectDesign() { this.switchType(TYPES.DESIGN); }
    selectData() { this.switchType(TYPES.DATA); }
    selectRelease() { this.switchType(TYPES.RELEASE); }

    switchType(type) {
        this.active = type;
        this.values = {};
        this.resetAttachments();
        this.load();
    }

    resetAttachments() {
        this.requestId = undefined;
        this.contentDocumentIds = [];
        this.uploadedNames = [];
    }

    async load() {
        this.ready = false;
        try {
            const cfg = await getConfig({ recordTypeDevName: this.active });
            this.recordTypeIds = cfg.recordTypeIds || {};
            this.fields = (cfg.fields || []).map(fc => this.toUiField(fc));
            this.ready = true;
        } catch (e) {
            this.toast('Error', this.reduceError(e), 'error');
        }
    }

    /* ---------- left content (same as your current) ---------- */
    get leftPurpose() {
        if (this.active === TYPES.DESIGN) {
            return 'Use this request when you need an official review on solution design, UI approach, and technical architecture before development starts.';
        }
        if (this.active === TYPES.DATA) {
            return 'Use this request to create or update Salesforce data model items like objects, fields, relationships, and picklists with governance review.';
        }
        return 'Use this request when your changes are ready for promotion and you need a controlled deployment to the target environment with proper tracking and evidence.';
    }

    get leftOutcome() {
        if (this.active === TYPES.DESIGN) {
            return 'You will receive structured feedback with recommendations, risks, and decision points so the build follows enterprise standards.';
        }
        if (this.active === TYPES.DATA) {
            return 'You will receive approved data model guidance covering naming, security/FLS, reporting impacts, and long-term maintainability.';
        }
        return 'You will receive release coordination with readiness checks, deployment validation, and a confirmed deployment plan.';
    }

    get leftHighlights() {
        if (this.active === TYPES.DESIGN) return ['Best Practices', 'Security Review', 'Performance', 'UX Guidance'];
        if (this.active === TYPES.DATA) return ['Schema Governance', 'FLS/Sharing', 'Reporting', 'Integration Ready'];
        return ['Deployment Plan', 'Readiness Check', 'Evidence Review', 'Rollback Notes'];
    }

    get leftTip() {
        if (this.active === TYPES.DESIGN) return 'Attach the design link and clearly mention what decision you need from the reviewers.';
        if (this.active === TYPES.DATA) return 'List exact API names and indicate whether fields are required, indexed, or used in integrations.';
        return 'Keep release notes structured: scope, dependencies, testing status, and rollback notes.';
    }

    get leftChecklist() {
        if (this.active === TYPES.DESIGN) {
            return [
                'Problem statement + desired outcome',
                'High-level architecture (data + flows + integrations)',
                'UI approach (LWC/Flow/Experience Cloud pages)',
                'Security plan (profiles/perm sets, guest access if any)',
                'Design doc link + diagrams/screenshots'
            ];
        }
        if (this.active === TYPES.DATA) {
            return [
                'Object + field list with data types',
                'Relationships (lookup/master-detail) and rollups',
                'Picklist values and validations (no dependencies)',
                'Reporting needs (filters, dashboards)',
                'Migration / backfill approach if data exists'
            ];
        }
        return [
            'Release scope and impacted components',
            'Source → Target environments',
            'Requested deployment date/time window',
            'Testing evidence link (UAT / regression)',
            'Deployment notes + post steps / rollback'
        ];
    }

    get leftExample() {
        if (this.active === TYPES.DESIGN) {
            return '“We are building an Experience Cloud intake form + approval flow. Need review on whether to use LWC vs Flow screens, data storage approach, and guest user security.”';
        }
        if (this.active === TYPES.DATA) {
            return '“Need a new custom object Vendor_Assignment__c with lookup to Project__c, picklist Category__c, and rollup fields for completion. Please validate naming + relationship type.”';
        }
        return '“Promote User Story US-123 to UAT. Includes 2 LWCs, 1 Apex class, 1 flow update. Regression passed, UAT evidence link attached. Deploy window: Wed 6PM–7PM.”';
    }

    get leftSteps() {
        if (this.active === TYPES.DESIGN) {
            return [
                { num: '1', title: 'Submit request', sub: 'Fill the form with design link, summary, and required details.' },
                { num: '2', title: 'Team review', sub: 'We review for best practices, security, performance, and UX.' },
                { num: '3', title: 'Feedback shared', sub: 'You receive notes + recommended updates/decisions.' },
                { num: '4', title: 'Proceed to build', sub: 'After confirmation, start implementation with confidence.' }
            ];
        }
        if (this.active === TYPES.DATA) {
            return [
                { num: '1', title: 'Submit request', sub: 'Provide object/field details, relationships, and justification.' },
                { num: '2', title: 'Governance review', sub: 'We validate naming, FLS, reporting, and downstream impacts.' },
                { num: '3', title: 'Approval / updates', sub: 'You’ll get approved structure or required changes.' },
                { num: '4', title: 'Implementation', sub: 'Once approved, build and proceed with release planning.' }
            ];
        }
        return [
            { num: '1', title: 'Submit request', sub: 'Add release notes, source/target, and evidence link.' },
            { num: '2', title: 'Readiness checks', sub: 'We confirm dependencies, tests, and deployment steps.' },
            { num: '3', title: 'Deployment scheduled', sub: 'We align on window and finalize deployment plan.' },
            { num: '4', title: 'Deploy & validate', sub: 'Deploy to target and verify post-deployment checks.' }
        ];
    }

    /* ---------- field rendering ---------- */
    toUiField(fc) {
        const api = fc.apiName;
        const isPicklist = fc.dataType === 'PICKLIST';
        const isTextarea = fc.dataType === 'TEXTAREA';
        const isInput = !isPicklist && !isTextarea;

        const isWide = isTextarea || fc.dataType === 'URL';
        const wrapClass = isWide ? 'fieldBox span2' : 'fieldBox';

        let inputType = 'text';
        if (fc.dataType === 'DATE') inputType = 'date';
        if (fc.dataType === 'EMAIL') inputType = 'email';
        if (fc.dataType === 'URL') inputType = 'url';

        return {
            ...fc,
            value: this.values[api] || '',
            isPicklist,
            isTextarea,
            isInput,
            inputType,
            wrapClass
        };
    }

    refreshFieldValues() {
        this.fields = this.fields.map(f => ({ ...f, value: this.values[f.apiName] || '' }));
    }

    handleChange = (e) => {
        const api = e.target.dataset.api;
        const value = e.detail?.value ?? e.target.value;
        this.values = { ...this.values, [api]: value };
        this.refreshFieldValues();
    };

    validate() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
        let ok = true;
        inputs.forEach(i => { if (!i.reportValidity()) ok = false; });
        return ok;
    }

    // ✅ file upload configuration
    get acceptedFormats() {
        return ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
    }

    get hasUploads() {
        return (this.contentDocumentIds || []).length > 0;
    }

    handleUploadFinished = (event) => {
        const files = event.detail.files || [];
        const newDocIds = [];
        const newNames = [];

        files.forEach(f => {
            // lightning-file-upload returns documentId
            newDocIds.push(f.documentId);
            newNames.push(f.name);
        });

        this.contentDocumentIds = [...this.contentDocumentIds, ...newDocIds];
        this.uploadedNames = [...this.uploadedNames, ...newNames];

        this.toast('Uploaded', `${files.length} file(s) uploaded successfully.`, 'success');
    };

    // ✅ Step-1 Create record
    async createRequest() {
        if (!this.validate()) return;

        try {
            this.submitting = true;
            const rtId = this.recordTypeIds?.[this.active];
            const payload = { ...this.values, RecordTypeId: rtId };

            const id = await createPlatformRequest({ req: payload });
            this.requestId = id;

            this.toast('Created', 'Request created. Now upload images, then click Final Submit.', 'success');
        } catch (e) {
            this.toast('Error', this.reduceError(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    // ✅ Step-2 Final submit (send email + attachments)
    async finalSubmit() {
        if (!this.requestId) {
            this.toast('Error', 'Please create the request first.', 'error');
            return;
        }

        try {
            this.submitting = true;

            await finalSubmitRequest({
                requestId: this.requestId,
                contentDocumentIds: this.contentDocumentIds
            });

            this.toast('Success', 'Request submitted successfully. Email sent with attachments.', 'success');

            // reset everything
            this.values = {};
            this.refreshFieldValues();
            this.resetAttachments();
        } catch (e) {
            this.toast('Error', this.reduceError(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(e) {
        if (Array.isArray(e?.body)) return e.body.map(x => x.message).join(', ');
        return e?.body?.message || e?.message || 'Unexpected error occurred.';
    }
}