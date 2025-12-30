import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// ✅ Custom Labels (URLs)
import HERO_SUBMITREQUEST_URL from '@salesforce/label/c.Submit_Request_Page_URL';
import HERO_EXPLORESERVICES_URL from '@salesforce/label/c.Explore_Services_Page_URL';
import HERO_VIEWSTANDARDS_URL from '@salesforce/label/c.View_Standards_Page_URL';
import HERO_OPENCALENDAR_URL from '@salesforce/label/c.Open_Calendar_Page_URL';

export default class HeroComponent extends NavigationMixin(LightningElement) {
    @track slides = [];
    @track index = 0;

    slideMs = 7000;
    tickMs = 70;

    timerId;
    progId;
    progress = 0;
    isPaused = false;

    touchX;

    connectedCallback() {
        this.slides = this.buildSlides();
        this.startAuto();
    }

    disconnectedCallback() {
        this.stopAuto();
    }

    // ✅ URL map for all button actions (reusable)
    get actionUrlMap() {
        return {
            submit: HERO_SUBMITREQUEST_URL,
            services: HERO_EXPLORESERVICES_URL,
            standards: HERO_VIEWSTANDARDS_URL,
            calendar: HERO_OPENCALENDAR_URL
        };
    }

    // ✅ Navigate helper (works in Experience + internal)
    navigateToUrl(url) {
        if (!url) return;

        // If admin put full URL, use directly; if it's "/xyz" still works.
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    // compute circular positions
    decorateIcons(iconList, radiusPx) {
        const count = iconList.length;
        const startAngle = -90;
        return iconList.map((it, idx) => {
            const angle = (startAngle + (360 / count) * idx) * (Math.PI / 180);
            const x = Math.cos(angle) * radiusPx;
            const y = Math.sin(angle) * radiusPx;
            return {
                key: it.key,
                icon: it.icon,
                tip: it.tip,
                style: `--tx:${x.toFixed(1)}px; --ty:${y.toFixed(1)}px;`
            };
        });
    }

    buildSlides() {
        const ICONS_PLATFORM = [
            { key: 'p1', icon: 'utility:settings', tip: 'Architecture' },
            { key: 'p2', icon: 'utility:lock', tip: 'Security' },
            { key: 'p3', icon: 'utility:task', tip: 'Engineering' },
            { key: 'p4', icon: 'utility:chart', tip: 'Quality' },
            { key: 'p5', icon: 'utility:people', tip: 'Teams' },
            { key: 'p6', icon: 'utility:refresh', tip: 'Operations' }
        ];

        const ICONS_QUALITY = [
            { key: 'q1', icon: 'utility:search', tip: 'Scan' },
            { key: 'q2', icon: 'utility:warning', tip: 'Severity' },
            { key: 'q3', icon: 'utility:bug', tip: 'Fix' },
            { key: 'q4', icon: 'utility:task', tip: 'Gate' },
            { key: 'q5', icon: 'utility:chart', tip: 'Report' },
            { key: 'q6', icon: 'utility:check', tip: 'Pass' }
        ];

        const ICONS_RELEASE = [
            { key: 'r1', icon: 'utility:date_input', tip: 'Calendar' },
            { key: 'r2', icon: 'utility:approval', tip: 'Governance' },
            { key: 'r3', icon: 'utility:flow', tip: 'Pipeline' },
            { key: 'r4', icon: 'utility:people', tip: 'Stakeholders' },
            { key: 'r5', icon: 'utility:refresh', tip: 'Validate' },
            { key: 'r6', icon: 'utility:event', tip: 'Milestone' }
        ];

        const R = 118;

        return [
            {
                id: 's1',
                badge: 'ENTERPRISE PLATFORM',
                miniInfo: 'Architecture • Delivery • Operations',
                title: 'The expertise',
                highlight: 'your teams need.',
                subtitle: 'Architecture, delivery, and operational support to scale Salesforce with confidence.',
                points: [
                    'Design reviews & technical guidance',
                    'Hands-on delivery support',
                    'Release readiness & risk management',
                    'Enablement for admins & dev teams',
                    'Production-first best practices'
                ],
                primaryLabel: 'Submit Request',
                secondaryLabel: 'Explore Services',
                primaryAction: 'submit',
                secondaryAction: 'services',
                meta1: 'Trusted patterns',
                meta2: 'Fast turnaround',
                meta3: 'Secure by design',
                centerIcon: 'utility:settings',
                visualClass: 'visual v1',
                icons: this.decorateIcons(ICONS_PLATFORM, R)
            },
            {
                id: 's2',
                badge: 'CODE QUALITY GATE',
                miniInfo: 'Scanner • PMD • CI Quality Gates',
                title: 'Ship changes with',
                highlight: 'quality built-in.',
                subtitle: 'Automated scanning + actionable feedback to keep orgs stable and compliant.',
                points: [
                    'PMD + Scanner rules aligned to standards',
                    'Delta scanning for faster results',
                    'Pre-commit & CI enforcement',
                    'Severity-based quality gates',
                    'Readable reports for quick fixes'
                ],
                primaryLabel: 'View Standards',
                secondaryLabel: 'Run a Scan',
                primaryAction: 'standards',
                secondaryAction: 'standards',
                meta1: 'Less risk',
                meta2: 'Fewer rollbacks',
                meta3: 'Cleaner codebase',
                centerIcon: 'utility:check',
                visualClass: 'visual v2',
                icons: this.decorateIcons(ICONS_QUALITY, R)
            },
            {
                id: 's3',
                badge: 'RELEASE MANAGEMENT',
                miniInfo: 'Milestones • Governance • Visibility',
                title: 'Predictable releases,',
                highlight: 'less firefighting.',
                subtitle: 'Planning, governance, and communication so every release is controlled and transparent.',
                points: [
                    'Release calendar & milestones',
                    'Deployment readiness checklist',
                    'Change impact visibility',
                    'Stakeholder comms & reporting',
                    'Post-release validation support'
                ],
                primaryLabel: 'Open Calendar',
                secondaryLabel: 'See Process',
                primaryAction: 'calendar',
                secondaryAction: 'calendar',
                meta1: 'Controlled deploys',
                meta2: 'Clear ownership',
                meta3: 'Audit-ready',
                centerIcon: 'utility:event',
                visualClass: 'visual v3',
                icons: this.decorateIcons(ICONS_RELEASE, R)
            }
        ];
    }

    startAuto() {
        this.stopAuto();
        this.timerId = window.setInterval(() => {
            if (!this.isPaused) this.next();
        }, this.slideMs);
        this.startProgress();
    }

    stopAuto() {
        if (this.timerId) window.clearInterval(this.timerId);
        if (this.progId) window.clearInterval(this.progId);
        this.timerId = null;
        this.progId = null;
    }

    startProgress() {
        this.progress = 0;
        if (this.progId) window.clearInterval(this.progId);

        const step = (this.tickMs / this.slideMs) * 100;
        this.progId = window.setInterval(() => {
            if (this.isPaused) return;
            this.progress = Math.min(100, this.progress + step);
        }, this.tickMs);
    }

    resetAfterChange() {
        this.startProgress();
    }

    pause() { this.isPaused = true; }
    resume() { this.isPaused = false; }

    next() {
        const len = this.slides.length;
        if (!len) return;
        this.index = (this.index + 1) % len;
        this.resetAfterChange();
    }

    prev() {
        const len = this.slides.length;
        if (!len) return;
        this.index = (this.index - 1 + len) % len;
        this.resetAfterChange();
    }

    goTo(e) {
        this.index = Number(e.currentTarget.dataset.index);
        this.resetAfterChange();
    }

    // ✅ CTA click handler => navigates using label URL
    onAction(e) {
        const action = e.currentTarget.dataset.action;
        const url = this.actionUrlMap[action];
        this.navigateToUrl(url);
    }

    get activeSlide() {
        return this.slides[this.index] || {};
    }

    get stageStyle() {
        return `transform: translate3d(-${this.index * 100}%, 0, 0);`;
    }

    get progressStyle() {
        return `width:${this.progress}%;`;
    }

    get dotItems() {
        return this.slides.map((s, idx) => ({
            id: s.id,
            index: idx,
            label: `Go to ${s.badge}`,
            cls: idx === this.index ? 'navDot active' : 'navDot'
        }));
    }

    handleTouchStart(e) {
        this.touchX = e.changedTouches[0].clientX;
        this.pause();
    }
    handleTouchEnd(e) {
        const endX = e.changedTouches[0].clientX;
        const diff = endX - this.touchX;
        if (Math.abs(diff) > 40) diff < 0 ? this.next() : this.prev();
        this.resume();
    }
}