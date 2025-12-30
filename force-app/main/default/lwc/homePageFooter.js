import { LightningElement } from 'lwc';

export default class HomePageFooter extends LightningElement {
    get year() {
        return new Date().getFullYear();
    }
}