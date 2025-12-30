import { LightningElement } from 'lwc';

export default class ApplicationsWeSupport extends LightningElement {
    isVisible = false;
    _wired = false;

    apps = [
        { key: 'gps',     title: 'GPS',     desc: '',  icon: 'utility:location', colors: ['#7C5CFF', '#4AB3FF'] },
        { key: 'prms',    title: 'PRMS',    desc: '',  icon: 'utility:people',   colors: ['#FF5C93', '#FFB84A'] },
        { key: 'cec',     title: 'CEC',     desc: '',  icon: 'utility:chat',     colors: ['#00C6A7', '#4AB3FF'] },
        { key: 'compass', title: 'Compass', desc: '',  icon: 'utility:chart',  colors: ['#6A5BFF', '#00C6A7'] },
        { key: 'otchs',   title: 'OTCHS',   desc: '',  icon: 'utility:favorite', colors: ['#FF7A59', '#FF5C93'] },
        { key: 'bell',    title: 'Bell',    desc: '',  icon: 'utility:call',     colors: ['#4AB3FF', '#7C5CFF'] }
    ];

    renderedCallback() {
        if (this._wired) return;
        this._wired = true;

        const el = this.template.querySelector('.section');
        if (!el) return;

        const io = new IntersectionObserver(
            (entries) => {
                const entry = entries && entries[0];
                if (entry && entry.isIntersecting) {
                    this.isVisible = true;
                    io.disconnect();
                }
            },
            { threshold: 0.18 }
        );

        io.observe(el);
    }

    get cards() {
        return this.apps.map((a, i) => ({
            ...a,
            style: `--d:${i * 110}ms; --a:${a.colors[0]}; --b:${a.colors[1]};`,
            cardClass: `card ${this.isVisible ? 'in' : ''}`
        }));
    }
}