import { LightningElement, track } from 'lwc';

export default class HomeStatsStrip extends LightningElement {
    rafId;
    started = false;
    _wired = false;

    // Configure your stats here
    baseStats = [
        { key: 'uptime', label: 'Uptime SLA', target: 99.9, decimals: 1, suffix: '%' },
        { key: 'deploy',  label: 'Deployments', target: 500,  decimals: 0, suffix: '+' },
        { key: 'support', label: 'Support', targetText: '24/7', suffix: '' }, // static
        { key: 'teams',   label: 'Teams Served', target: 50,   decimals: 0, suffix: '+' }
    ];

    // ✅ reactive state (plain object)
    @track values = {
        uptime: 0,
        deploy: 0,
        teams: 0
    };

    renderedCallback() {
        if (this._wired) return;
        this._wired = true;

        const root = this.template.querySelector('.wrap');
        if (!root) return;

        const io = new IntersectionObserver(
            (entries) => {
                const e = entries && entries[0];
                if (e && e.isIntersecting) {
                    this.startCountUp();
                    io.disconnect();
                }
            },
            { threshold: 0.22 }
        );

        io.observe(root);
    }

    disconnectedCallback() {
        if (this.rafId) cancelAnimationFrame(this.rafId);
    }

    startCountUp() {
        if (this.started) return;
        this.started = true;

        const duration = 1100; // ms
        const start = performance.now();

        const tick = (now) => {
            const t = Math.min(1, (now - start) / duration);
            const eased = 1 - Math.pow(1 - t, 3); // smooth easing

            // ✅ update immutably so LWC rerenders
            const next = { ...this.values };

            this.baseStats.forEach((s) => {
                if (typeof s.target === 'number') {
                    next[s.key] = s.target * eased;
                }
            });

            this.values = next;

            if (t < 1) {
                this.rafId = requestAnimationFrame(tick);
            }
        };

        this.rafId = requestAnimationFrame(tick);
    }

    get stats() {
        return this.baseStats.map((s) => {
            if (s.targetText) {
                return { ...s, display: s.targetText };
            }

            const raw = this.values[s.key] || 0;
            return { ...s, display: this.formatNumber(raw, s.decimals) };
        });
    }

    formatNumber(val, decimals) {
        const factor = Math.pow(10, decimals || 0);
        const rounded = Math.round(val * factor) / factor;
        return decimals && decimals > 0 ? rounded.toFixed(decimals) : String(Math.round(rounded));
    }
}