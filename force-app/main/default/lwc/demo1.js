export default class TestComp {
  connectedCallback() {
    const unusedVar = 'test'; // ESLint: no-unused-vars
    console.log('Hell1o1111'); // ESLint: no-console
  }
}
