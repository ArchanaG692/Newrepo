import { LightningElement } from "lwc";

export default class OurServicesShowcase extends LightningElement {
    services = [
        {
            key: "design-review",
            icon: "utility:search",
            title: "Design Review Consultations",
            desc:
                "Expert review of your solution architecture, UI/UX designs, and technical specifications before implementation.",
            tag: "Architecture",
            small: "UI/UX + Tech Review"
        },
        {
            key: "data-model",
            icon: "utility:database",
            title: "Data Model Consultations",
            desc:
                "Guidance on custom objects, fields, relationships, and data architecture to ensure scalability and performance.",
            tag: "Data",
            small: "Scalable Modeling"
        },
        {
            key: "release-mgmt",
            icon: "utility:upload",
            title: "Release Management",
            desc: "End-to-end deployment coordination across environments with proper change management and governance.",
            tag: "DevOps",
            small: "Controlled Deployments"
        },
        {
            key: "devsecops",
            icon: "utility:shield",
            title: "DevSecOps Administration",
            desc:
                "Comprehensive security, CI/CD pipelines, and DevOps practices for enterprise-grade platform management.",
            tag: "Security",
            small: "CI/CD + Policies"
        },
        {
            key: "code-quality",
            icon: "utility:check",
            title: "Code Quality Management",
            desc: "Static code analysis, best practice enforcement, and code review processes to maintain high standards.",
            tag: "Quality",
            small: "PMD + Standards"
        },
        {
            key: "platform-admin",
            icon: "utility:settings",
            title: "Platform Administration",
            desc:
                "User management, security configurations, and ongoing maintenance of your Salesforce environments.",
            tag: "Admin",
            small: "Ops + Maintenance"
        }
    ];

    _observer;
    _reducedMotion = false;

    renderedCallback() {
        if (this._observer) return;

        this._reducedMotion =
            typeof window !== "undefined" &&
            window.matchMedia &&
            window.matchMedia("(prefers-reduced-motion: reduce)").matches;

        // ✅ Make ALL cards BLACK (dark)
        this.services = this.services.map((s) => ({
            ...s,
            cardClass: "card card--dark"
        }));

        // Scroll reveal
        const cards = Array.from(this.template.querySelectorAll(".card"));
        if (!cards.length) return;

        if (this._reducedMotion) {
            cards.forEach((c) => c.classList.add("in"));
            return;
        }

        this._observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((e) => {
                    if (e.isIntersecting) {
                        e.target.classList.add("in");
                        this._observer.unobserve(e.target);
                    }
                });
            },
            { threshold: 0.15 }
        );

        cards.forEach((c) => this._observer.observe(c));
    }

    handleTilt(event) {
        if (this._reducedMotion) return;

        const card = event.currentTarget;
        const rect = card.getBoundingClientRect();

        if (window.matchMedia && window.matchMedia("(hover: none)").matches) return;

        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;

        const rx = ((y / rect.height) - 0.5) * -10;
        const ry = ((x / rect.width) - 0.5) * 10;

        card.style.setProperty("--rx", `${rx}deg`);
        card.style.setProperty("--ry", `${ry}deg`);
        card.style.setProperty("--mx", `${(x / rect.width) * 100}%`);
        card.style.setProperty("--my", `${(y / rect.height) * 100}%`);
        card.classList.add("tilting");
    }

    resetTilt(event) {
        const card = event.currentTarget;
        card.classList.remove("tilting");
        card.style.setProperty("--rx", `0deg`);
        card.style.setProperty("--ry", `0deg`);
        card.style.setProperty("--mx", `50%`);
        card.style.setProperty("--my", `50%`);
    }
}