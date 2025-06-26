export default class TestComp {
  connectedCallback() {
    const unusedVar = 'test'; // ESLint: no-unused-vars
    console.log('Hello'); // ESLint: no-console
  }
}
