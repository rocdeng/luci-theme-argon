/* Liquid Glass runtime — tab slider, wallpaper fallback, accent presets */
(function () {
  "use strict";

  // ---------- Accent palette (MUST match tokens.less + dark.less) ----------
  var ACCENTS = {
    blue:   { light: "#007aff", dark: "#0a84ff" },
    purple: { light: "#af52de", dark: "#bf5af2" },
    pink:   { light: "#ff2d55", dark: "#ff375f" },
    green:  { light: "#34c759", dark: "#30d158" },
    orange: { light: "#ff9500", dark: "#ff9f0a" }
  };

  function hexToRgba(hex, a) {
    var h = hex.replace("#", "");
    var r = parseInt(h.substring(0, 2), 16);
    var g = parseInt(h.substring(2, 4), 16);
    var b = parseInt(h.substring(4, 6), 16);
    return "rgba(" + r + "," + g + "," + b + "," + a + ")";
  }

  function applyAccent(preset) {
    var palette = ACCENTS[preset];
    if (!palette) return;
    var isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    var color = isDark ? palette.dark : palette.light;
    var root = document.documentElement;
    root.style.setProperty("--accent", color);
    root.style.setProperty("--accent-tint", hexToRgba(color, isDark ? 0.18 : 0.12));
    root.style.setProperty("--accent-soft", hexToRgba(color, isDark ? 0.28 : 0.25));
  }

  // ---------- Tab slider ----------
  function positionTabSlider(menu) {
    if (!menu) return;
    var active = menu.querySelector("li.active > a, li a.active, li.active, a.active");
    // If active item is <a>, move up to its parent <li>
    if (active && active.tagName === "A" && active.parentElement && active.parentElement.tagName === "LI") {
      active = active.parentElement;
    }
    if (!active) {
      active = menu.querySelector("li, .tab");
    }
    if (!active) return;
    var menuRect = menu.getBoundingClientRect();
    var r = active.getBoundingClientRect();
    var left = r.left - menuRect.left;
    var w = r.width;
    menu.style.setProperty("--tab-left", left + "px");
    menu.style.setProperty("--tab-width", w + "px");
  }

  function initTabSliders(root) {
    root = root || document;
    var menus = root.querySelectorAll(".cbi-tabmenu, .tabs");
    menus.forEach(function (m) {
      positionTabSlider(m);
      // Guard against duplicate listeners across MutationObserver re-runs
      if (m.dataset.lgInit === "1") return;
      m.dataset.lgInit = "1";
      m.addEventListener("click", function () {
        requestAnimationFrame(function () { positionTabSlider(m); });
      });
    });
  }

  // ---------- Wallpaper fallback ----------
  function initWallpaperFallback() {
    var cs = getComputedStyle(document.body);
    var bg = cs.backgroundImage;
    if (!bg || bg === "none") return;
    var m = bg.match(/url\(["']?([^"')]+)["']?\)/);
    if (!m) return;
    var url = m[1];
    var img = new Image();
    img.onerror = function () {
      document.body.style.backgroundImage = "none";
      document.body.classList.add("lg-no-wallpaper");
    };
    img.src = url;
  }

  // ---------- Boot ----------
  function boot() {
    initTabSliders();
    initWallpaperFallback();
    var preset = document.body.getAttribute("data-accent-preset");
    if (preset) applyAccent(preset);

    // Watch DOM for LuCI AJAX swaps that add tab menus
    var main = document.getElementById("maincontent");
    if (main) {
      var mo = new MutationObserver(function () { initTabSliders(); });
      mo.observe(main, { childList: true, subtree: true });
    }
    window.addEventListener("resize", function () {
      document.querySelectorAll(".cbi-tabmenu, .tabs").forEach(positionTabSlider);
    });
    // Dark-mode change re-applies accent dark variant
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
      var p = document.body.getAttribute("data-accent-preset");
      if (p) applyAccent(p);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
