import { LightningElement } from 'lwc';

export default class ResourcesShowcase extends LightningElement {
    resources = [
        {
            key: 'docs',
            icon: 'utility:description',
            title: 'Documentation',
            desc: 'Guides, standards, and technical references for consistent delivery.',
            cta: 'Browse Docs',
            href: 'https://developer.salesforce.com/docs',
            points: [
                'Architecture & patterns',
                'Security guidelines',
                'Coding standards',
                'Release playbooks',
                'Troubleshooting'
            ]
        },
        {
            key: 'videos',
            icon: 'utility:video',
            title: 'Training Videos',
            desc: 'Short walkthroughs to level up admin and developer skills quickly.',
            cta: 'Watch Now',
            href: 'https://www.salesforce.com/plus',
            points: [
                'LWC best practices',
                'Apex patterns',
                'DevOps & CI/CD',
                'Integrations',
                'Performance tips'
            ]
        },
        {
            key: 'kb',
            icon: 'utility:knowledge_base',
            title: 'Knowledge Base',
            desc: 'Search FAQs, known issues, and step-by-step resolution guides.',
            cta: 'Search KB',
            href: 'https://help.salesforce.com',
            points: [
                'Common fixes',
                'Known limitations',
                'How-to articles',
                'Runbooks',
                'Support triage'
            ]
        },
        {
            key: 'community',
            icon: 'utility:comments',
            title: 'Community Forum',
            desc: 'Connect with peers, share insights, and get answers from experts.',
            cta: 'Join Discussion',
            href: 'https://trailblazer.salesforce.com',
            points: [
                'Ask questions',
                'Share solutions',
                'Best practice threads',
                'Announcements',
                'Feature requests'
            ]
        }
    ];

    rendered = false;

    renderedCallback() {
        if (this.rendered) return;
        this.rendered = true;

        // staggered reveal animation
        window.requestAnimationFrame(() => {
            const cards = this.template.querySelectorAll('[data-reveal]');
            cards.forEach((el, i) => {
                el.style.setProperty('--d', `${i * 90}ms`);
                el.classList.add('is-ready');
            });
        });
    }

    get resourcesWithDelay() {
        return this.resources.map((r, idx) => ({
            ...r,
            delayStyle: `--d:${idx * 90}ms;`
        }));
    }
}