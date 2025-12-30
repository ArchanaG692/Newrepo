import { LightningElement, track } from 'lwc';

export default class ServiceShowcase extends LightningElement {
    @track selectedKey = 'release';

    // ✅ FIX: rename base array (avoid conflict with getter)
    serviceItems = [
        {
            key: 'release',
            title: 'Release Management',
            short: 'Plan • Validate • Promote',
            // ✅ FIX: use safe icon (ship is missing in some orgs)
            icon: 'utility:package',
            badge: 'Controlled delivery',
            chips: ['Copado / CI', 'Approvals', 'Rollback-ready'],
            purpose:
                'Structured releases with predictable promotions, dependency checks, and clear ownership from build to production.',
            deliverables: [
                'Release calendar and scope tracking',
                'Promotion plan with validation gates',
                'Deployment checklist & runbook',
                'Post-release verification steps',
                'Release notes & audit trail'
            ],
            outcomes: [
                'Fewer hotfixes after go-live',
                'Faster, safer deployments',
                'Clear visibility for stakeholders',
                'Lower risk through governance',
                'Repeatable delivery process'
            ]
        },
        {
            key: 'quality',
            title: 'Code Quality Gate',
            short: 'PMD • Scan • Enforce',
            icon: 'utility:shield',
            badge: 'Quality enforced',
            chips: ['PMD', 'SFDX Scanner', 'Delta scan'],
            purpose:
                'Automated checks that prevent risky code from entering the branch — keeping performance, security, and standards consistent.',
            deliverables: [
                'Ruleset alignment to your standards',
                'Delta scanning on changed files',
                'Severity-based blocking (quality gates)',
                'Actionable reports for developers',
                'Continuous improvement recommendations'
            ],
            outcomes: [
                'Reduced technical debt',
                'Stronger security posture',
                'Cleaner, maintainable Apex/LWC',
                'Faster reviews and merges',
                'Consistent coding standards'
            ]
        },
        {
            key: 'support',
            title: 'Platform Support',
            short: 'Monitor • Fix • Improve',
            icon: 'utility:settings',
            badge: 'Always-on support',
            chips: ['Incidents', 'Enhancements', 'Ops'],
            purpose:
                'Operational support for production stability, proactive monitoring, and small improvements without disrupting delivery.',
            deliverables: [
                'Triage and incident resolution',
                'Root cause analysis (RCA)',
                'Minor enhancements & optimizations',
                'Monitoring and admin assistance',
                'Knowledge base updates'
            ],
            outcomes: [
                'Higher system reliability',
                'Faster issue resolution',
                'Improved user satisfaction',
                'Reduced support backlog',
                'Better operational visibility'
            ]
        },
        {
            key: 'enable',
            title: 'Best Practices Enablement',
            short: 'Guide • Coach • Scale',
            icon: 'utility:education',
            badge: 'Team enablement',
            chips: ['Standards', 'Templates', 'Coaching'],
            purpose:
                'Reusable patterns and guidance that help teams ship consistently — with clarity on design, security, and performance.',
            deliverables: [
                'Reference architecture & guidelines',
                'Reusable LWC/Apex patterns',
                'Security & sharing best practices',
                'Performance checklists',
                'Team coaching sessions'
            ],
            outcomes: [
                'Faster onboarding',
                'Consistent implementations',
                'Reduced rework',
                'Higher delivery confidence',
                'Improved long-term scalability'
            ]
        }
    ];

    // ===== Auto rotate config =====
    intervalMs = 10000; // ✅ 10 seconds
    timerId;
    isPaused = false;

    get active() {
        return this.serviceItems.find((s) => s.key === this.selectedKey) || this.serviceItems[0];
    }

    // ✅ this is what template uses
    get services() {
        return this.serviceItems.map((s) => ({
            ...s,
            btnClass: `railBtn ${s.key === this.selectedKey ? 'active' : ''}`
        }));
    }

    connectedCallback() {
        this.startAutoRotate();
        // trigger initial detail animation
        requestAnimationFrame(() => {
            const panel = this.template?.querySelector?.('.panel');
            if (panel) panel.classList.add('pop');
        });
    }

    disconnectedCallback() {
        this.stopAutoRotate();
    }

    startAutoRotate() {
        this.stopAutoRotate();
        this.timerId = setInterval(() => {
            if (this.isPaused) return;
            this.selectNext();
        }, this.intervalMs);
    }

    stopAutoRotate() {
        if (this.timerId) {
            clearInterval(this.timerId);
            this.timerId = null;
        }
    }

    pauseAuto() {
        this.isPaused = true;
    }

    resumeAuto() {
        this.isPaused = false;
    }

    resetAutoRotate() {
        this.startAutoRotate();
    }

    selectNext() {
        const keys = this.serviceItems.map((s) => s.key);
        const idx = keys.indexOf(this.selectedKey);
        const next = keys[(idx + 1) % keys.length];
        this.selectedKey = next;
        this.reTriggerPanelAnim();
    }

    handleSelect(event) {
        const key = event.currentTarget?.dataset?.key;
        if (key && key !== this.selectedKey) {
            this.selectedKey = key;
            this.reTriggerPanelAnim();
            this.resetAutoRotate(); // ✅ user click resets 10s timer
        }
    }

    reTriggerPanelAnim() {
        const panel = this.template.querySelector('.panel');
        if (panel) {
            panel.classList.remove('pop');
            requestAnimationFrame(() => panel.classList.add('pop'));
        }
    }
}