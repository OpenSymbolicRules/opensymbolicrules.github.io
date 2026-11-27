// The history charts: round axes, time labels and the zoom window.
const assert = require("node:assert/strict");
const { niceRange, fmtTime, clampView } = require("./history.js");
// The full view starts at zero; four round steps reach the maximum.
assert.deepEqual(niceRange(17, 3015, true), [0, 4000]);
assert.deepEqual(niceRange(0, 0, true), [0, 4]);
// A zoom fits the values shown, on round steps.
assert.deepEqual(niceRange(6257, 8372, false), [6000, 10000]);
assert.deepEqual(niceRange(852, 926, false), [850, 950]);
// Dates, and hours once the window is shorter than two days.
const t = Date.parse("2026-11-27T10:30:00Z");
assert.equal(fmtTime(t, 10 * 86400000), "2026-11-27");
assert.equal(fmtTime(t, 3600000), "11-27 10:30");
// The zoom window stays inside the data and keeps a minimum width.
assert.deepEqual(clampView(-5, 5, 0, 100, 1), [0, 10]);
assert.deepEqual(clampView(95, 120, 0, 100, 1), [75, 100]);
assert.deepEqual(clampView(40, 40, 0, 100, 10), [40, 50]);
assert.deepEqual(clampView(-10, 200, 0, 100, 1), [0, 100]);
console.log("History axes, time labels and zoom window passed.");
