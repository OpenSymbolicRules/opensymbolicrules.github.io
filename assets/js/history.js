// Progress over time (shortcode `history`): two small multiples, over ℝ and
// over ℂ, on one shared scale; a crosshair and a tooltip on hover or focus.
(function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";
  var SERIES = [
    { key: "total", label: "rules exported", short: "rules", get: function (p) { return p.rules; } },
    { key: "proved", label: "proved", get: function (p, d) { return p[d].proved; } },
    { key: "refuted", label: "refuted", get: function (p, d) { return p[d].counterexample; } },
    { key: "unproved", label: "unproved", get: function (p, d) { return p[d].unproved; } }
  ];
  function el(name, attrs, parent) {
    var e = document.createElementNS(NS, name);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }
  // The top of a four-step axis: the smallest round step (1, 2, 2.5, 5 × 10ⁿ)
  // whose four multiples reach v.
  function niceMax(v) {
    var raw = Math.max(v, 1) / 4, p = Math.pow(10, Math.floor(Math.log10(raw)));
    var steps = [1, 2, 2.5, 5, 10];
    for (var i = 0; i < steps.length; i++) if (steps[i] * p >= raw) return 4 * steps[i] * p;
    return 40 * p;
  }
  function fmtDay(t) { return new Date(t).toISOString().slice(0, 10); }

  function draw(fig) {
    var data = JSON.parse(fig.querySelector("[data-osr-history-data]").textContent);
    if (!data.length) return;
    var times = data.map(function (p) { return Date.parse(p.time); });
    var t0 = times[0], t1 = times[times.length - 1];
    if (t1 === t0) t1 = t0 + 86400000;
    var ymax = niceMax(Math.max.apply(null, data.map(function (p) { return p.rules; })));
    var tip = fig.querySelector(".osr-history-tip");
    var W = 460, H = 260, m = { l: 44, r: 74, t: 8, b: 26 };
    var iw = W - m.l - m.r, ih = H - m.t - m.b;
    function x(t) { return m.l + (t - t0) / (t1 - t0) * iw; }
    function y(v) { return m.t + ih - v / ymax * ih; }

    fig.querySelectorAll(".osr-history-panel").forEach(function (panel) {
      var dom = panel.getAttribute("data-domain");
      var svg = el("svg", { viewBox: "0 0 " + W + " " + H, class: "osr-history-svg" }, panel);
      var grid = el("g", { class: "osr-grid" }, svg);
      for (var i = 0; i <= 4; i++) {
        var v = ymax * i / 4, yy = y(v);
        el("line", { x1: m.l, x2: m.l + iw, y1: yy, y2: yy }, grid);
        el("text", { x: m.l - 6, y: yy + 4, "text-anchor": "end", class: "osr-tick" }, grid).textContent = Math.round(v);
      }
      var days = 4;
      for (var j = 0; j <= days; j++) {
        var tt = t0 + (t1 - t0) * j / days;
        el("text", { x: x(tt), y: H - 6, "text-anchor": j === 0 ? "start" : j === days ? "end" : "middle", class: "osr-tick" }, grid)
          .textContent = (j === 0 || j === days) ? fmtDay(tt) : fmtDay(tt).slice(5);
      }
      // Direct labels at the right end, nudged apart so they never overlap.
      var ends = [];
      SERIES.forEach(function (s) {
        var d = data.map(function (p, k) { return (k ? "L" : "M") + x(times[k]).toFixed(1) + "," + y(s.get(p, dom)).toFixed(1); }).join("");
        el("path", { d: d, class: "osr-line osr-line-" + s.key }, svg);
        ends.push({ s: s, v: s.get(data[data.length - 1], dom) });
      });
      ends.sort(function (a, b) { return b.v - a.v; });
      var lastY = -Infinity;
      ends.forEach(function (e) {
        var yy = Math.max(y(e.v) + 4, lastY + 12);
        lastY = yy;
        el("text", { x: m.l + iw + 6, y: yy, class: "osr-end" }, svg).textContent = e.v + " " + (e.s.short || e.s.label);
      });
      var cross = el("line", { y1: m.t, y2: m.t + ih, class: "osr-cross", visibility: "hidden" }, svg);
      var dots = SERIES.map(function (s) { return el("circle", { r: 4, class: "osr-dot osr-dot-" + s.key, visibility: "hidden" }, svg); });
      var hit = el("rect", { x: m.l, y: m.t, width: iw, height: ih, class: "osr-hit", tabindex: 0 }, svg);
      var cur = data.length - 1;
      function show(k) {
        cur = k;
        var p = data[k], xx = x(times[k]);
        cross.setAttribute("x1", xx); cross.setAttribute("x2", xx); cross.setAttribute("visibility", "visible");
        SERIES.forEach(function (s, i) {
          dots[i].setAttribute("cx", xx); dots[i].setAttribute("cy", y(s.get(p, dom))); dots[i].setAttribute("visibility", "visible");
        });
        tip.innerHTML = "<strong>" + p.date + "</strong> · report <code>" + p.report.slice(0, 8) + "</code> · " +
          (dom === "real" ? "over ℝ" : "over ℂ") + "<br>" +
          SERIES.map(function (s) { return '<span class="osr-key osr-key-' + s.key + '"></span>' + s.label + " " + s.get(p, dom); }).join("<br>");
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
      function nearest(evt) {
        var r = svg.getBoundingClientRect();
        var t = t0 + ((evt.clientX - r.left) / r.width * W - m.l) / iw * (t1 - t0);
        var best = 0;
        for (var k = 1; k < times.length; k++) if (Math.abs(times[k] - t) < Math.abs(times[best] - t)) best = k;
        return best;
      }
      hit.addEventListener("pointermove", function (e) { show(nearest(e)); });
      hit.addEventListener("pointerleave", hide);
      hit.addEventListener("focus", function () { show(cur); });
      hit.addEventListener("blur", hide);
      hit.addEventListener("keydown", function (e) {
        if (e.key === "ArrowLeft") { show(Math.max(0, cur - 1)); e.preventDefault(); }
        if (e.key === "ArrowRight") { show(Math.min(data.length - 1, cur + 1)); e.preventDefault(); }
      });
    });
  }
  document.querySelectorAll("[data-osr-history]").forEach(draw);
})();
