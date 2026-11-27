// Progress over time (shortcode `history`): small multiples on a shared time
// axis, a crosshair and a tooltip on hover or focus, and a zoom on any period:
// drag across a chart to select it, double-click or "Show all" to reset; with
// the keyboard, + and − zoom around the focused point and 0 resets.
(function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";
  var DAY = 86400000;
  function v1(key, label, get, short) { return { key: key, label: label, short: short, get: get }; }
  // Series per panel kind; panels with the same `group` share their y scale.
  var KINDS = {
    real: { group: "v1", title: "over ℝ", series: domainSeries("real") },
    complex: { group: "v1", title: "over ℂ", series: domainSeries("complex") },
    corrections: { group: "corrections", title: "corrected variants", series: [
      v1("total", "corrected variants", function (p) { return p.corrections ? p.corrections.total : 0; }, "variants"),
      v1("proved", "proved", function (p) { return p.corrections ? p.corrections.proved : 0; }),
      v1("unproved", "not yet proved", function (p) { return p.corrections ? p.corrections.total - p.corrections.proved : 0; }, "unproved")
    ] },
    v01: { group: "v01", title: "v0.1 source rules", step: true, series: [
      v1("total", "v0.1 entries", function (p) { return p.total; }, "entries"),
      v1("loaded", "in the default load manifests", function (p) { return p.loaded; }, "loaded")
    ] }
  };
  function domainSeries(d) {
    return [
      v1("total", "rules exported", function (p) { return p.rules; }, "rules"),
      v1("proved", "proved", function (p) { return p[d].proved; }),
      v1("refuted", "refuted", function (p) { return p[d].counterexample; }),
      v1("unproved", "unproved", function (p) { return p[d].unproved; })
    ];
  }
  function el(name, attrs, parent) {
    var e = document.createElementNS(NS, name);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }
  // A four-step axis over [lo, hi] with a round step (1, 2, 2.5, 5 × 10ⁿ);
  // from zero when `fromZero`.
  function niceRange(lo, hi, fromZero) {
    if (fromZero) lo = 0;
    // Counts are integers: at least one unit per step.
    if (hi - lo < 4) hi = lo + 4;
    var raw = (hi - lo) / 4, p = Math.pow(10, Math.floor(Math.log10(raw)));
    var steps = [1, 2, 2.5, 5, 10, 20];
    for (var i = 0; i < steps.length; i++) {
      var st = steps[i] * p, a = Math.floor(lo / st) * st;
      if (a + 4 * st >= hi) return [a, a + 4 * st];
    }
    return [lo, hi];
  }
  function fmtTime(t, span) {
    var s = new Date(t).toISOString();
    return span < 2 * DAY ? s.slice(5, 10) + " " + s.slice(11, 16) : s.slice(0, 10);
  }

  function draw(fig) {
    var data = JSON.parse(fig.querySelector("[data-osr-history-data]").textContent);
    if (!data.length) return;
    var times = data.map(function (p) { return Date.parse(p.time); });
    var T0 = times[0], T1 = times[times.length - 1];
    if (T1 === T0) T1 = T0 + DAY;
    var view = [T0, T1];
    var tip = fig.querySelector(".osr-history-tip");
    var reset = fig.querySelector(".osr-history-reset");
    var W = 460, H = 260, m = { l: 52, r: 78, t: 8, b: 26 };
    var iw = W - m.l - m.r, ih = H - m.t - m.b;
    var uid = Math.random().toString(36).slice(2);
    var panels = Array.prototype.map.call(fig.querySelectorAll(".osr-history-panel"), function (panel, n) {
      var kind = KINDS[panel.getAttribute("data-kind") || panel.getAttribute("data-domain")];
      var svg = el("svg", { viewBox: "0 0 " + W + " " + H, class: "osr-history-svg" }, panel);
      return { el: panel, kind: kind, svg: svg, clip: "osr-clip-" + uid + "-" + n, cur: data.length - 1 };
    });
    function x(t) { return m.l + (t - view[0]) / (view[1] - view[0]) * iw; }
    function tAt(px) { return view[0] + (px - m.l) / iw * (view[1] - view[0]); }
    // Indices of the points shown: those in the view, and one on each side so
    // that the lines reach the edges.
    function visible() {
      var a = 0, b = data.length - 1;
      while (a < b && times[a + 1] < view[0]) a++;
      while (b > a && times[b - 1] > view[1]) b--;
      return [a, b];
    }
    function yScale(group, range) {
      var lo = Infinity, hi = -Infinity;
      panels.forEach(function (pn) {
        if (pn.kind.group !== group) return;
        for (var k = range[0]; k <= range[1]; k++) pn.kind.series.forEach(function (s) {
          var v = s.get(data[k]); if (v < lo) lo = v; if (v > hi) hi = v;
        });
      });
      var zoomed = view[0] > T0 || view[1] < T1;
      // The full view starts at zero; a zoom fits the values it shows.
      return niceRange(lo, hi, !zoomed || lo - (hi - lo) < 0);
    }
    function render() {
      var range = visible(), scales = {};
      var zoomed = view[0] > T0 || view[1] < T1;
      if (reset) reset.hidden = !zoomed;
      panels.forEach(function (pn) {
        var g = pn.kind.group;
        if (!scales[g]) scales[g] = yScale(g, range);
        renderPanel(pn, scales[g], range);
      });
    }
    function renderPanel(pn, ys, range) {
      var svg = pn.svg, series = pn.kind.series;
      while (svg.firstChild) svg.removeChild(svg.firstChild);
      function y(v) { return m.t + ih - (v - ys[0]) / (ys[1] - ys[0]) * ih; }
      var defs = el("defs", {}, svg);
      el("rect", { x: m.l, y: m.t - 2, width: iw, height: ih + 4 }, el("clipPath", { id: pn.clip }, defs));
      var grid = el("g", { class: "osr-grid" }, svg);
      for (var i = 0; i <= 4; i++) {
        var v = ys[0] + (ys[1] - ys[0]) * i / 4, yy = y(v);
        el("line", { x1: m.l, x2: m.l + iw, y1: yy, y2: yy }, grid);
        el("text", { x: m.l - 6, y: yy + 4, "text-anchor": "end", class: "osr-tick" }, grid).textContent = Math.round(v);
      }
      var span = view[1] - view[0];
      for (var j = 0; j <= 4; j++) {
        var tt = view[0] + span * j / 4, lab = fmtTime(tt, span);
        el("text", { x: x(tt), y: H - 6, "text-anchor": j === 0 ? "start" : j === 4 ? "end" : "middle", class: "osr-tick" }, grid)
          .textContent = (j === 0 || j === 4 || span < 2 * DAY) ? lab : lab.slice(5);
      }
      var lines = el("g", { "clip-path": "url(#" + pn.clip + ")" }, svg);
      // Direct labels at the right end (the last point shown), nudged apart.
      var ends = [], last = range[1];
      while (last > range[0] && times[last] > view[1]) last--;
      series.forEach(function (s) {
        var d = "";
        for (var k = range[0]; k <= range[1]; k++) {
          var xx = x(times[k]).toFixed(1), yy = y(s.get(data[k])).toFixed(1);
          if (k === range[0]) d += "M" + xx + "," + yy;
          else if (pn.kind.step) d += "H" + xx + "V" + yy;
          else d += "L" + xx + "," + yy;
        }
        if (pn.kind.step && times[range[1]] < view[1]) d += "H" + x(view[1]).toFixed(1);
        el("path", { d: d, class: "osr-line osr-line-" + s.key }, lines);
        ends.push({ s: s, v: s.get(data[last]) });
      });
      ends.sort(function (a, b) { return b.v - a.v; });
      var lastY = -Infinity;
      ends.forEach(function (e) {
        var yy = Math.max(y(e.v) + 4, lastY + 12);
        lastY = yy;
        el("text", { x: m.l + iw + 6, y: yy, class: "osr-end" }, svg).textContent = e.v + " " + (e.s.short || e.s.label);
      });
      var cross = el("line", { y1: m.t, y2: m.t + ih, class: "osr-cross", visibility: "hidden" }, svg);
      var dots = series.map(function (s) { return el("circle", { r: 4, class: "osr-dot osr-dot-" + s.key, visibility: "hidden" }, svg); });
      var sel = el("rect", { y: m.t, height: ih, class: "osr-select", visibility: "hidden" }, svg);
      var hit = el("rect", { x: m.l, y: m.t, width: iw, height: ih, class: "osr-hit", tabindex: 0,
        "aria-label": pn.kind.title + ": drag to zoom into a period, double-click to show all" }, svg);
      if (pn.cur < range[0] || pn.cur > range[1]) pn.cur = last;
      function show(k) {
        pn.cur = k;
        var p = data[k], xx = x(times[k]);
        cross.setAttribute("x1", xx); cross.setAttribute("x2", xx); cross.setAttribute("visibility", "visible");
        series.forEach(function (s, i) {
          dots[i].setAttribute("cx", xx); dots[i].setAttribute("cy", y(s.get(p))); dots[i].setAttribute("visibility", "visible");
        });
        var head = p.report ? "report <code>" + p.report.slice(0, 8) + "</code>"
          : p.repo + " <code>" + p.commit.slice(0, 7) + "</code>";
        tip.innerHTML = "<strong>" + p.date + "</strong> · " + head + " · " + pn.kind.title + "<br>" +
          series.map(function (s) { return '<span class="osr-key osr-key-' + s.key + '"></span>' + s.label + " " + s.get(p); }).join("<br>");
        tip.hidden = false;
        var fr = fig.getBoundingClientRect(), pr = svg.getBoundingClientRect();
        var px = pr.left - fr.left + xx / W * pr.width;
        tip.style.left = Math.min(Math.max(px + 12, 0), fr.width - tip.offsetWidth) + "px";
        tip.style.top = (pr.top - fr.top + 8) + "px";
      }
      function hide() {
        cross.setAttribute("visibility", "hidden");
        dots.forEach(function (d) { d.setAttribute("visibility", "hidden"); });
        tip.hidden = true;
      }
      function svgX(evt) { var r = svg.getBoundingClientRect(); return (evt.clientX - r.left) / r.width * W; }
      function nearest(px) {
        var t = tAt(px), best = range[0];
        for (var k = range[0] + 1; k <= range[1]; k++) if (Math.abs(times[k] - t) < Math.abs(times[best] - t)) best = k;
        return best;
      }
      var drag = null;
      hit.addEventListener("pointerdown", function (e) {
        drag = { x0: Math.min(Math.max(svgX(e), m.l), m.l + iw) };
        hit.setPointerCapture(e.pointerId);
      });
      hit.addEventListener("pointermove", function (e) {
        var px = Math.min(Math.max(svgX(e), m.l), m.l + iw);
        if (drag) {
          sel.setAttribute("x", Math.min(drag.x0, px)); sel.setAttribute("width", Math.abs(px - drag.x0));
          sel.setAttribute("visibility", "visible");
        }
        show(nearest(px));
      });
      hit.addEventListener("pointerup", function (e) {
        if (!drag) return;
        var px = Math.min(Math.max(svgX(e), m.l), m.l + iw), x0 = drag.x0;
        drag = null;
        sel.setAttribute("visibility", "hidden");
        if (Math.abs(px - x0) > 6) zoomTo(tAt(Math.min(x0, px)), tAt(Math.max(x0, px)));
      });
      hit.addEventListener("pointerleave", function () { if (!drag) hide(); });
      hit.addEventListener("dblclick", function () { zoomTo(T0, T1); });
      hit.addEventListener("focus", function () { show(pn.cur); });
      hit.addEventListener("blur", hide);
      hit.addEventListener("keydown", function (e) {
        var t = times[pn.cur], half = (view[1] - view[0]) / 2;
        if (e.key === "ArrowLeft") show(Math.max(range[0], pn.cur - 1));
        else if (e.key === "ArrowRight") show(Math.min(range[1], pn.cur + 1));
        else if (e.key === "+" || e.key === "=") zoomTo(t - half / 2, t + half / 2, true);
        else if (e.key === "-" || e.key === "_") zoomTo(t - half * 2, t + half * 2, true);
        else if (e.key === "0" || e.key === "Escape") zoomTo(T0, T1, true);
        else return;
        e.preventDefault();
      });
      pn.focus = function () { pn.svg.querySelector(".osr-hit").focus(); };
    }
    // Zoom to [a, b], kept inside the data and at least an hour wide.
    function zoomTo(a, b, keepFocus) {
      view = clampView(a, b, T0, T1, 3600000);
      var focused = panels.filter(function (pn) { return pn.svg.contains(document.activeElement); })[0];
      tip.hidden = true;
      render();
      if (keepFocus && focused) focused.focus();
    }
    if (reset) reset.addEventListener("click", function () { zoomTo(T0, T1); });
    render();
  }
  // Zoom to [a, b] within [t0, t1], at least `min` wide.
  function clampView(a, b, t0, t1, min) {
    var w = Math.max(b - a, min);
    if (w >= t1 - t0) return [t0, t1];
    a = Math.max(t0, Math.min(a, t1 - w));
    return [a, a + w];
  }
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { niceRange: niceRange, fmtTime: fmtTime, clampView: clampView };
  }
  if (typeof document !== "undefined") document.querySelectorAll("[data-osr-history]").forEach(draw);
})();
