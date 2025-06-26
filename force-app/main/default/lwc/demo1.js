export default class TestComp {
  connectedCallback() {
    const unusedVar = 'test'; // ESLint: no-unused-vars
    console.log('Hell1o11111111'); // ESLint: no-console
  }
}
