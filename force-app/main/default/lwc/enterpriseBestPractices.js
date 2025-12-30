import { LightningElement } from 'lwc';

export default class EnterpriseBestPractices extends LightningElement {
    _io;

    get cards() {
        const data = [
            {
                key: 'dev',
                icon: 'utility:code_playground',
                title: 'Development Standards',
                tag: 'CODE',
                desc: 'Build readable, testable, governor-safe implementations.',
                points: [
                    'Bulkify logic and avoid SOQL/DML inside loops.',
                    'Use clear naming and single-responsibility methods.',
                    'Centralize exception handling and surface friendly errors.',
                    'Avoid hardcoding (use Custom Labels/Metadata where needed).',
                    'Maintain strong unit tests with realistic datasets.'
                ]
            },
            {
                key: 'data',
                icon: 'utility:database',
                title: 'Data Architecture',
                tag: 'MODEL',
                desc: 'Design scalable data models aligned to reporting and growth.',
                points: [
                    'Prefer standard objects/fields before creating custom ones.',
                    'Choose Lookup vs Master-Detail intentionally (ownership, rollups).',
                    'Normalize relationships and avoid duplicated data.',
                    'Apply FLS/sharing early; design for least-privilege visibility.',
                    'Document ERD, dependencies, and data lifecycle decisions.'
                ]
            },
            {
                key: 'sec',
                icon: 'utility:shield',
                title: 'Security & Compliance',
                tag: 'SECURE',
                desc: 'Operate with least-privilege and audit-friendly practices.',
                points: [
                    'Enforce least-privilege access for all profiles/roles.',
                    'Use Permission Sets and Permission Set Groups for access control.',
                    'Secure integrations (Named Credentials, OAuth, no secrets in code).',
                    'Protect sensitive data (encryption + secure storage patterns).',
                    'Run Security Health Check and periodic access reviews.'
                ]
            },
            {
                key: 'auto',
                icon: 'utility:settings',
                title: 'Automation Guidelines',
                tag: 'FLOW',
                desc: 'Keep automation predictable, centralized, and maintainable.',
                points: [
                    'Prefer Flow Builder for orchestration and UI automation.',
                    'Avoid recursion with entry criteria and guardrails.',
                    'Keep triggers thin; move logic to handler/service layers.',
                    'Document automation ownership, purpose, and change history.',
                    'Validate edge cases (bulk, nulls, retries) in sandbox.'
                ]
            },
            {
                key: 'test',
                icon: 'utility:change_request',
                title: 'Testing & Deployment',
                tag: 'RELEASE',
                desc: 'Ship safely with repeatable delivery and rollback options.',
                points: [
                    'Complete UAT sign-off and regression validation steps.',
                    'Use CI/CD pipelines with quality gates (PMD, scanner, tests).',
                    'Maintain environment strategy (Dev/QA/UAT/Prod) with refresh plan.',
                    'Prepare rollback strategy and deployment runbooks.',
                    'Track changes with release notes and audit-friendly documentation.'
                ]
            },
            {
                key: 'perf',
                icon: 'utility:trend',
                title: 'Performance',
                tag: 'SCALE',
                desc: 'Optimize runtime, UI responsiveness, and query efficiency.',
                points: [
                    'Write selective SOQL (indexed filters) and limit field selection.',
                    'Cache and reuse data (Platform Cache / storable actions where fit).',
                    'Lazy load non-critical UI data and reduce payload sizes.',
                    'Avoid heavy client rendering; paginate and virtualize when needed.',
                    'Monitor limits (CPU, heap) and optimize slow transactions.'
                ]
            }
        ];

        // Add stagger delay for reveal animation
        return data.map((c, i) => ({
            ...c,
            cardClass: 'bpCard',
            style: `--d:${i * 90}ms;`
        }));
    }

    renderedCallback() {
        if (this._io) return;

        const cards = Array.from(this.template.querySelectorAll('.bpCard'));
        if (!cards.length) return;

        this._io = new IntersectionObserver(
            (entries) => {
                entries.forEach((e) => {
                    if (e.isIntersecting) {
                        e.target.classList.add('isVisible');
                        this._io.unobserve(e.target);
                    }
                });
            },
            { threshold: 0.18 }
        );

        cards.forEach((el, idx) => {
            el.style.setProperty('--d', `${idx * 90}ms`);
            this._io.observe(el);
        });
    }

    disconnectedCallback() {
        if (this._io) {
            this._io.disconnect();
            this._io = null;
        }
    }
}