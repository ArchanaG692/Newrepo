import { LightningElement } from 'lwc';

export default class RotatingServicesShowcase extends LightningElement {
    // --- SERVICES (Edit your purpose/content here) ---
    services = [
        {
            id: 'security',
            badge: 'Security',
            title: 'Security',
            highlight: '& Compliance',
            purpose: 'Ensure org health with proactive checks, risk controls, and compliance-ready configurations.',
            points: [
                'Security review & baseline hardening',
                'Guest user access checks (Experience Cloud)',
                'OWD / sharing / FLS validation',
                'Audit-friendly configuration recommendations'
            ],
            impact: 'Reduce risk & improve trust',
            bestFor: 'Admins, Security teams',
            icon: 'utility:lock'
        },
        {
            id: 'quality',
            badge: 'Code Quality Gate',
            title: 'Code',
            highlight: 'Quality Gate',
            purpose: 'Stop issues before deployment using automated scanning and quality rules that block risky commits.',
            points: [
                'PMD / Scanner rules enforcement',
                'Severity thresholds & delta scans',
                'Pre-commit + CI gating setup',
                'Readable reports for quick fixes'
            ],
            impact: 'Faster releases, fewer bugs',
            bestFor: 'Developers, DevOps',
            icon: 'utility:check'
        },
        {
            id: 'release',
            badge: 'Release',
            title: 'Release',
            highlight: 'Management',
            purpose: 'Plan, track, and ship releases with clear visibility across environments and stakeholders.',
            points: [
                'Release calendar + milestone tracking',
                'Copado/Git aligned promotion path',
                'Deployment readiness checklist',
                'Release notes & audit trail'
            ],
            impact: 'Predictable deployments',
            bestFor: 'Leads, Release managers',
            icon: 'utility:refresh'
        },
        {
            id: 'data',
            badge: 'Data',
            title: 'Data',
            highlight: 'Governance',
            purpose: 'Keep data accurate, consistent, and usable across apps with rules, monitoring, and clean flows.',
            points: [
                'Validation & standardization patterns',
                'Duplicate prevention strategy',
                'Data quality dashboards',
                'Safe imports & rollback approach'
            ],
            impact: 'Cleaner CRM decisions',
            bestFor: 'Ops, Analysts',
            icon: 'utility:database'
        },
        {
            id: 'automation',
            badge: 'Automation',
            title: 'Smart',
            highlight: 'Automation',
            purpose: 'Automate repeatable operations with flows, triggers, and notifications—without breaking scale.',
            points: [
                'Flow-first design with guardrails',
                'Bulk-safe trigger patterns',
                'Email/SMS/WhatsApp notifications',
                'Observability for failures'
            ],
            impact: 'Less manual work',
            bestFor: 'Admins, Developers',
            icon: 'utility:settings'
        },
        {
            id: 'analytics',
            badge: 'Analytics',
            title: 'Insights',
            highlight: '& Reporting',
            purpose: 'Turn platform activity into insights through dashboards, KPIs, and user-friendly visuals.',
            points: [
                'Executive dashboards & KPIs',
                'Operational views for teams',
                'Adoption + performance tracking',
                'Actionable reporting layouts'
            ],
            impact: 'Better decisions',
            bestFor: 'Leadership, Ops',
            icon: 'utility:chart'
        }
    ];

    activeIndex = 0;
    timer;
    isPaused = false;

    connectedCallback() {
        this._decorate();
        this._start();
    }

    disconnectedCallback() {
        this._stop();
    }

    // Left-side active content
    get active() {
        return this.services[this.activeIndex];
    }

    // Orbit speed
    get orbitStyle() {
        return 'animation-duration: 12s;';
    }

    // Orbit animation class
    get orbitClass() {
        return `orbit ${this.isPaused ? 'paused' : ''}`;
    }

    // Add positioning + active class to buttons
    _decorate() {
        const total = this.services.length;
        const radius = 118;

        this.services = this.services.map((s, i) => {
            const angle = (2 * Math.PI * i) / total - Math.PI / 2;
            const x = radius * Math.cos(angle);
            const y = radius * Math.sin(angle);

            // IMPORTANT: use CSS variables, not transform
            const posStyle = `--x:${x}px; --y:${y}px;`;

            return {
                ...s,
                posStyle,
                btnClass: `node ${i === this.activeIndex ? 'active' : ''}`
            };
        });
    }


    _setActive(index) {
        this.activeIndex = index;
        // re-render active button class
        this.services = this.services.map((s, i) => ({
            ...s,
            btnClass: `node ${i === this.activeIndex ? 'active' : ''}`
        }));

        // trigger left-side transition
        const left = this.template.querySelector('.left');
        if (left) {
            left.classList.remove('swap');
            // force reflow
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            requestAnimationFrame(() => left.classList.add('swap'));
        }
    }

    selectService(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        this._setActive(idx);
        this._restart();
    }

    // Auto rotate
    _start() {
        this._stop();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timer = setInterval(() => {
            if (this.isPaused) return;
            const next = (this.activeIndex + 1) % this.services.length;
            this._setActive(next);
        }, 4500);
    }

    _stop() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
    }

    _restart() {
        this._start();
    }

    pause() {
        this.isPaused = true;
    }

    resume() {
        this.isPaused = false;
    }
}