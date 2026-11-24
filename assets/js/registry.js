// Static pages work without JavaScript. Search and sort use a separate index.
(function () {
  "use strict";
  const sizes = [100, 200, 500, 1000];
  const defaultSize = 500;
  const selectColumns = [2, 3, 4, 5];
  const collator = new Intl.Collator(undefined, { numeric: true });

  function readState(url) {
    const q = url.searchParams;
    const size = Number(q.get("size"));
    const pathPage = url.pathname.match(/\/page\/(\d+)\/?$/);
    const page = Number(q.get("page") || (pathPage && pathPage[1]) || 1);
    return {
      size: sizes.includes(size) ? size : defaultSize,
      page: Number.isSafeInteger(page) && page > 0 ? page : 1,
      filters: Array.from({length: 9}, (_, col) => q.get("c" + col) || ""),
      sort: (q.get("sort") || "").split(",").filter(k => /^-?[0-8]$/.test(k))
    };
  }

  function viewURL(state) {
    const params = new URLSearchParams();
    state.filters.forEach((value, col) => { if (value) params.set("c" + col, value); });
    if (state.sort.length) params.set("sort", state.sort.join(","));
    if (state.size !== defaultSize) params.set("size", state.size);
    if (!params.size) return state.page > 1 ? "/findings/page/" + state.page + "/" : "/findings/";
    if (state.page > 1) params.set("page", state.page);
    return "/findings/?" + params;
  }

  function selectRows(index, state) {
    const terms = state.filters.map(s => s.trim().toLowerCase());
    const matches = [];
    index.forEach(({cells}, i) => {
      if (terms.every((term, col) => {
        if (!term) return true;
        const text = cells[col].toLowerCase();
        return selectColumns.includes(col) ? text === term : term.split(/\s+/).every(word => text.includes(word));
      })) matches.push(i);
    });
    if (state.sort.length) matches.sort((a, b) => {
      for (const key of state.sort) {
        const col = Math.abs(Number(key));
        const order = collator.compare(index[a].cells[col], index[b].cells[col]);
        if (order) return key.startsWith("-") ? -order : order;
      }
      return a - b;
    });
    return matches;
  }

  function pageWindow(total, {page, size}) {
    const pages = Math.max(1, Math.ceil(total / size));
    page = Math.min(page, pages);
    return {page, pages, start: (page - 1) * size, end: Math.min(total, page * size)};
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = {readState, selectRows, pageWindow, viewURL};
    return;
  }
  const table = document.querySelector("[data-osr-registry]");
  if (!table) return;
  const all = selector => Array.from(document.querySelectorAll(selector));
  const heads = Array.from(table.tHead.rows[0].cells);
  const body = table.tBodies[0];
  const total = Number(table.dataset.total);
  const chunks = JSON.parse(table.dataset.chunks);
  const choices = JSON.parse(table.dataset.choices);
  const rows = new Map();
  const loading = document.querySelector("[data-osr-loading]");
  const base = (Number(table.dataset.page) - 1) * Number(table.dataset.size);
  Array.from(body.rows).forEach((row, i) => rows.set(base + i, row));
  let state = readState(new URL(location.href));
  let revision = 0;
  let pendingInput;
  const requests = new Map();

  function cached(url, decode) {
    if (!requests.has(url)) {
      const request = fetch(url).then(response => {
        if (!response.ok) throw new Error("HTTP " + response.status);
        return decode(response);
      }).catch(error => { requests.delete(url); throw error; });
      requests.set(url, request);
    }
    return requests.get(url);
  }

  async function loadRows(indices) {
    const missing = new Set(indices.filter(i => !rows.has(i)).map(i => Math.floor(i / chunks.size)));
    await Promise.all(Array.from(missing, chunk => cached(chunks.urls[chunk], async response => {
      const page = new DOMParser().parseFromString(await response.text(), "text/html");
      Array.from(page.querySelectorAll("tbody tr")).forEach((row, i) => rows.set(chunk * chunks.size + i, row));
    })));
  }

  const filterRow = table.tHead.insertRow();
  const filters = heads.map((head, col) => {
    const cell = filterRow.insertCell();
    let input;
    if (selectColumns.includes(col)) {
      input = document.createElement("select");
      input.add(new Option("all", ""));
      Object.keys(choices[col] || {}).filter(Boolean).sort().forEach(value => input.add(new Option(value, value)));
    } else {
      input = document.createElement("input");
      input.type = "search";
      input.placeholder = "filter";
    }
    input.setAttribute("aria-label", "Filter " + head.textContent.trim());
    cell.appendChild(input);
    input.addEventListener("input", () => {
      state.filters[col] = input.value;
      state.page = 1;
      ++revision;
      clearTimeout(pendingInput);
      pendingInput = setTimeout(() => render("replaceState"), input.type === "search" ? 150 : 0);
    });
    return input;
  });

  function syncControls() {
    filters.forEach((el, col) => {
      const value = state.filters[col];
      if (el.tagName === "SELECT" && value && !Array.from(el.options).some(o => o.value === value))
        el.add(new Option(value, value));
      el.value = value;
      const rank = state.sort.findIndex(k => Math.abs(Number(k)) === col);
      const head = heads[col];
      if (rank < 0) head.removeAttribute("aria-sort");
      else head.setAttribute("aria-sort", state.sort[rank].startsWith("-") ? "descending" : "ascending");
      head.dataset.rank = rank >= 0 && state.sort.length > 1 ? String(rank + 1) : "";
    });
    all("[data-osr-size]").forEach(el => { el.value = String(state.size); });
  }

  function updatePager(window, count) {
    all("[data-osr-range]").forEach(el => {
      el.textContent = (count ? (window.start + 1) + "–" + window.end : "0") + " of " + count;
    });
    for (const [direction, step] of [["prev", -1], ["next", 1]]) {
      const target = window.page + step;
      all("[data-osr-" + direction + "]").forEach(link => {
        link.hidden = target < 1 || target > window.pages;
        if (link.hidden) link.removeAttribute("href");
        else link.href = viewURL({...state, page:target});
      });
    }
  }

  async function render(historyMethod, hash = "") {
    const version = ++revision;
    syncControls();
    const needsIndex = state.filters.some(Boolean) || state.sort.length || hash;
    loading.hidden = false;
    loading.textContent = "Loading findings…";
    table.setAttribute("aria-busy", "true");
    try {
      let matches;
      if (needsIndex) {
        const index = await cached(table.dataset.index, response => response.json());
        if (version !== revision) return;
        matches = selectRows(index, state);
        if (hash) {
          const position = matches.findIndex(i => index[i].anchor === hash.slice(1));
          if (position >= 0) state.page = 1 + Math.floor(position / state.size);
        }
      }
      const count = matches ? matches.length : total;
      const window = pageWindow(count, state);
      const indices = matches ? matches.slice(window.start, window.end) :
        Array.from({length:window.end - window.start}, (_, i) => window.start + i);
      await loadRows(indices);
      if (version !== revision) return;
      body.replaceChildren(...indices.map(i => rows.get(i)));
      state.page = window.page;
      updatePager(window, count);
      const url = viewURL(state) + hash;
      if (url !== location.pathname + location.search + location.hash) history[historyMethod](null, "", url);
      loading.hidden = true;
      if (hash) document.getElementById(hash.slice(1))?.scrollIntoView();
    } catch {
      if (version === revision) {
        loading.textContent = "Could not load the requested findings. Reload the page to retry.";
      }
    } finally {
      if (version === revision) table.removeAttribute("aria-busy");
    }
  }

  heads.forEach((head, col) => {
    const activate = ev => {
      const i = state.sort.findIndex(k => Math.abs(Number(k)) === col);
      const key = i >= 0 && !state.sort[i].startsWith("-") ? "-" + col : String(col);
      if (!ev.shiftKey) state.sort = [key];
      else if (i < 0) state.sort.push(key);
      else state.sort[i] = key;
      state.page = 1;
      render("replaceState");
    };
    head.tabIndex = 0;
    head.addEventListener("click", activate);
    head.addEventListener("keydown", ev => {
      if (ev.key === "Enter" || ev.key === " ") { ev.preventDefault(); activate(ev); }
    });
  });
  all("[data-osr-size-label], [data-osr-reset]").forEach(el => { el.hidden = false; });
  all("[data-osr-size]").forEach(el => el.addEventListener("change", () => {
    state.size = Number(el.value);
    state.page = 1;
    render("pushState");
  }));
  all("[data-osr-reset]").forEach(el => el.addEventListener("click", () => {
    state.filters.fill(""); state.sort = []; state.page = 1;
    render("replaceState");
  }));
  all("[data-osr-prev], [data-osr-next]").forEach(link => link.addEventListener("click", ev => {
    if (ev.ctrlKey || ev.metaKey || ev.shiftKey || ev.altKey || ev.button !== 0) return;
    ev.preventDefault();
    state = readState(new URL(link.href));
    render("pushState");
    document.querySelector(".osr-pagination").scrollIntoView();
  }));
  function restore() {
    clearTimeout(pendingInput);
    state = readState(new URL(location.href));
    render("replaceState", location.hash);
  }
  window.addEventListener("popstate", restore);
  window.addEventListener("hashchange", restore);
  syncControls();
  if (location.search || (location.hash && !document.getElementById(location.hash.slice(1)))) restore();
})();
