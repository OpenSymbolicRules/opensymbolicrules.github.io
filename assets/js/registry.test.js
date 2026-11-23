// Test URL filtering against a small DOM, including domains with no rows.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('assets/js/registry.js', 'utf8');

function run(search) {
  class Element {
    constructor(tag) { this.tagName = tag.toUpperCase(); this.children = []; this.dataset = {}; this._value = ''; this.hidden = false; }
    appendChild(child) { this.children.push(child); return child; }
    setAttribute() {}
    removeAttribute() {}
    addEventListener() {}
    set value(v) {
      this._value = this.tagName === 'SELECT' && !this.children.some((o) => o.value === v) ? '' : v;
    }
    get value() { return this._value; }
    get options() { return this.children; }
  }
  class Option { constructor(label, value) { this.text = label; this.value = value; } }
  const heads = ['ID', 'Rule', 'Domain'].map((name, i) => {
    const h = new Element('th'); h.textContent = name;
    if (i === 2) h.dataset.filter = 'select';
    return h;
  });
  const row = (domain) => ({cells: ['id', 'identity', domain].map((textContent) => ({textContent})), hidden: false});
  const rows = [row('Algebra'), row('Integration')];
  const tbody = {rows, appendChild() {}};
  const filterRow = new Element('tr');
  const table = {tHead: {rows: [{cells: heads}], insertRow: () => filterRow}, tBodies: [tbody]};
  const shown = {textContent: ''};
  const document = {
    querySelector: (selector) => selector === '[data-osr-registry]' ? table : selector === '[data-osr-shown]' ? shown : null,
    createElement: (tag) => new Element(tag),
    createDocumentFragment: () => new Element('fragment'),
  };
  const location = {search, hash: '', pathname: '/findings/'};
  let replaced = '';
  const history = {replaceState: (_a, _b, value) => { replaced = value; }};
  vm.runInNewContext(source, {document, location, history, Option, URLSearchParams});
  return {rows, shown, replaced, selected: filterRow.children[2].children[0].value};
}

const existing = run('?c2=Algebra');
assert.equal(existing.selected, 'Algebra');
assert.equal(existing.shown.textContent, 1);
assert.deepEqual(existing.rows.map((r) => r.hidden), [false, true]);

const missing = run('?c2=LinearAlgebra');
assert.equal(missing.selected, 'LinearAlgebra');
assert.equal(missing.shown.textContent, 0);
assert.deepEqual(missing.rows.map((r) => r.hidden), [true, true]);
assert.match(missing.replaced, /c2=LinearAlgebra/);
console.log('Registry URL filtering: existing and empty domains passed.');
