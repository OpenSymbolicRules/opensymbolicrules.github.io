// Column filters and multi-column sort for the findings registry.
// Click a header to sort by it; shift-click to add it as a further sort key.
// Filters accept several words, all of which must match (case-insensitive);
// the state is mirrored in the URL query (?c2=Integration&sort=3,-0).
(function () {
  "use strict";
  const table = document.querySelector("[data-osr-registry]");
  if (!table) return;
  const heads = Array.from(table.tHead.rows[0].cells);
  const body = table.tBodies[0];
  const rows = Array.from(body.rows);
  const text = rows.map((r) => Array.from(r.cells, (c) => c.textContent.replace(/\s+/g, " ").trim()));
  const lower = text.map((cells) => cells.map((t) => t.toLowerCase()));
  const shown = document.querySelector("[data-osr-shown]");
  let sortKeys = [];

  // A filter row under the headers.
  const filterRow = table.tHead.insertRow();
  const filters = heads.map((th, col) => {
    const cell = document.createElement("td");
    filterRow.appendChild(cell);
    const label = "Filter " + th.textContent.trim();
    let el;
    if (th.dataset.filter === "select") {
      el = document.createElement("select");
      el.appendChild(new Option("all", ""));
      const values = Array.from(new Set(text.map((c) => c[col]))).sort();
      values.forEach((v) => el.appendChild(new Option(v || "(empty)", v)));
    } else {
      el = document.createElement("input");
      el.type = "search";
      el.placeholder = "filter";
    }
    el.setAttribute("aria-label", label);
    el.addEventListener("input", update);
    cell.appendChild(el);
    return el;
  });

  heads.forEach((th, col) => {
    th.tabIndex = 0;
    th.setAttribute("role", "columnheader button");
    const activate = (ev) => {
      const i = sortKeys.findIndex((k) => k.col === col);
      if (ev.shiftKey) {
        if (i < 0) sortKeys.push({ col, dir: 1 });
        else sortKeys[i].dir = -sortKeys[i].dir;
      } else {
        sortKeys = [{ col, dir: i === 0 && sortKeys.length === 1 ? -sortKeys[0].dir : 1 }];
      }
      update();
    };
    th.addEventListener("click", activate);
    th.addEventListener("keydown", (ev) => {
      if (ev.key === "Enter" || ev.key === " ") { ev.preventDefault(); activate(ev); }
    });
  });

  const reset = document.querySelector("[data-osr-reset]");
  if (reset) reset.addEventListener("click", () => {
    filters.forEach((f) => (f.value = ""));
    sortKeys = [];
    update();
  });

  function matches(i) {
    return filters.every((f, col) => {
      const v = f.value.trim().toLowerCase();
      if (!v) return true;
      if (f.tagName === "SELECT") return lower[i][col] === v;
      return v.split(/\s+/).every((w) => lower[i][col].includes(w));
    });
  }

  function compare(a, b) {
    for (const { col, dir } of sortKeys) {
      const c = text[a][col].localeCompare(text[b][col], undefined, { numeric: true });
      if (c) return c * dir;
    }
    return a - b;
  }

  function update() {
    const order = rows.map((_, i) => i).sort(compare);
    let n = 0;
    const frag = document.createDocumentFragment();
    for (const i of order) {
      const ok = matches(i);
      rows[i].hidden = !ok;
      if (ok) n++;
      frag.appendChild(rows[i]);
    }
    body.appendChild(frag);
    if (shown) shown.textContent = n;
    heads.forEach((th, col) => {
      const k = sortKeys.findIndex((s) => s.col === col);
      if (k < 0) { th.removeAttribute("aria-sort"); th.dataset.rank = ""; return; }
      th.setAttribute("aria-sort", sortKeys[k].dir > 0 ? "ascending" : "descending");
      th.dataset.rank = sortKeys.length > 1 ? String(k + 1) : "";
    });
    const q = new URLSearchParams();
    filters.forEach((f, col) => { if (f.value) q.set("c" + col, f.value); });
    if (sortKeys.length) q.set("sort", sortKeys.map((k) => (k.dir < 0 ? "-" : "") + k.col).join(","));
    const s = q.toString();
    history.replaceState(null, "", s ? "?" + s + location.hash : location.pathname + location.hash);
  }

  // Restore the state from the URL query.
  const q = new URLSearchParams(location.search);
  filters.forEach((f, col) => {
    const v = q.get("c" + col);
    if (v === null) return;
    // Keep a domain filter even when it has no rows yet. Otherwise a select
    // drops the unknown value and a deep link misleadingly shows every rule.
    if (f.tagName === "SELECT" && v && !Array.from(f.options).some((o) => o.value === v)) {
      f.appendChild(new Option(v, v));
    }
    f.value = v;
  });
  const sort = q.get("sort");
  if (sort) sortKeys = sort.split(",").filter(Boolean).map((s) => ({ col: Math.abs(parseInt(s, 10)), dir: s.startsWith("-") ? -1 : 1 }))
    .filter((k) => k.col < heads.length);
  if (q.toString()) update();
})();
