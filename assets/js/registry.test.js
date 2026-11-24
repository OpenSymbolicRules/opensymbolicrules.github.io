// The client paginates the complete filtered and sorted result.
const assert = require("node:assert/strict");
const { readState, selectRows, pageWindow, viewURL } = require("./registry.js");
const records = Array.from({length: 1103}, (_, i) => ({
  anchor: "rule" + i,
  cells: ["rule" + i, "A test case", i < 3 ? "Algebra" : "Integration", "proved", "", "", "", "", ""]
}));
const root = "https://example.org/findings/";
for (const size of [100, 200, 500, 1000]) {
  const s = readState(new URL(root + "?size=" + size + "&page=2"));
  assert.equal(pageWindow(records.length, s).start, size);
  assert.equal(readState(new URL(viewURL(s), root)).size, size);
}
let s = readState(new URL(root + "page/5/"));
assert.equal(s.page, 5);
assert.equal(readState(new URL(root+"?size=13&page=-3")).size, 500);
assert.equal(pageWindow(0, s).page, 1);
s = readState(new URL(root+"?c2=Integration&c1=case+test&sort=-0&size=200&page=9"));
const matches = selectRows(records, s);
assert.equal(matches.length, 1100);
assert.equal(matches[0], 1102);
assert.equal(pageWindow(matches.length, s).page, 6);
s.filters[2] = "LinearAlgebra";
assert.deepEqual(selectRows(records, s), []);
assert.equal(readState(new URL(viewURL(s), root)).filters[2], "LinearAlgebra");
console.log("Registry pagination, sorting, filters and shareable state passed.");
