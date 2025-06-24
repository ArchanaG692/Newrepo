import { LightningElement } from 'lwc';

export default class Demo extends LightningElement {
    myVar; // ❌ `no-unused-vars`: Variable is declared but not used

    connectedCallback() {
        console.log('Component Loading'); // ❌ `no-console`: `console.log()` is not allowed
        debugger; // ❌ `no-debugger`: Debugger statement is not allowed

        if (this.myVar == null) { // ❌ `eqeqeq`: Use `===` instead of `==`
            console.warn("Warning: Variable is null");
        }

        if (this.myVar) console.log("No curly brackets found"); // ❌ `curly`: Requires curly brackets `{}` for if statements

        this.testFunction();
    }

    testFunction() { // ❌ `no-unused-vars`: Function is defined but never used
        let myUndefinedVar; // ❌ `no-undef`: Variable is used before being defined
        console.log(myUndefinedVar);
    }
}