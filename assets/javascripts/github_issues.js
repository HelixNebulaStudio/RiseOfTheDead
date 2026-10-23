/*
 * github_issues.js
 * Embeds GitHub issues into the MkDocs "Issues" page.
 * GitHub blocks iframing (X-Frame-Options: DENY), so we pull issues
 * live from the public GitHub REST API and render them client-side.
 *
 * The API supports CORS, so this works without a backend.
 * Unauthenticated rate limit is 60 req/hour per IP; results are cached
 * in localStorage for CACHE_TTL to stay well under that.
 */
(function () {
  "use strict";

  // --- Configuration -------------------------------------------------------
  var REPO = "HelixNebulaStudio/RiseOfTheDead"; // owner/name
  var API = "https://api.github.com/repos/" + REPO + "/issues";
  var CACHE_KEY = "rotd_gh_issues_cache_v1";
  var CACHE_TTL = 60 * 60 * 1000; // 1 hour (full pagination is expensive)

  // Tag categories for the sidebar. Order defines display order.
  // A label is placed in the first category whose keywords appear (case-
  // insensitively) in its name. Anything unmatched falls into "Other".
  // Adjust the keywords to match your repository's actual label names.
  var TAG_CATEGORIES = [
    {
      name: "Type",
      keywords: [
        "bug", "enhancement", "development", "feature", "question", "docs", "duplicate", "wontfix"
      ],
    },
    {
      name: "Branch",
      keywords: ["live-branch", "dev-branch"],
    },
    {
      name: "Severity",
      keywords: [
        "negligible", "nuisance", "considerable", "moderate", "severe" 
      ],
    },
  ];
  var OTHER_CATEGORY = "Other";

  function categoryOf(name) {
    var n = name.toLowerCase();
    for (var i = 0; i < TAG_CATEGORIES.length; i++) {
      var cats = TAG_CATEGORIES[i].keywords;
      for (var j = 0; j < cats.length; j++) {
        if (n.indexOf(cats[j].toLowerCase()) !== -1) {
          return TAG_CATEGORIES[i].name;
        }
      }
    }
    return OTHER_CATEGORY;
  }

  // Position of the first matching keyword within a category (for ordering).
  // Returns Infinity if the label doesn't match any keyword in that category.
  function keywordIndexOf(cat, name) {
    var n = name.toLowerCase();
    for (var j = 0; j < cat.keywords.length; j++) {
      if (n.indexOf(cat.keywords[j].toLowerCase()) !== -1) return j;
    }
    return Infinity;
  }

  // --- Helpers -------------------------------------------------------------
  function el(tag, attrs, children) {
    var node = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        if (k === "class") node.className = attrs[k];
        else if (k === "text") node.textContent = attrs[k];
        else if (k === "html") node.innerHTML = attrs[k];
        else node.setAttribute(k, attrs[k]);
      });
    }
    (children || []).forEach(function (c) {
      if (c) node.appendChild(c);
    });
    return node;
  }

  function timeAgo(iso) {
    var then = new Date(iso).getTime();
    var diff = Math.max(0, Date.now() - then);
    var mins = Math.floor(diff / 60000);
    if (mins < 1) return "just now";
    if (mins < 60) return mins + "m ago";
    var hrs = Math.floor(mins / 60);
    if (hrs < 24) return hrs + "h ago";
    var days = Math.floor(hrs / 24);
    if (days < 30) return days + "d ago";
    var months = Math.floor(days / 30);
    if (months < 12) return months + "mo ago";
    return Math.floor(months / 12) + "y ago";
  }

  function readCache() {
    try {
      return JSON.parse(localStorage.getItem(CACHE_KEY) || "{}");
    } catch (e) {
      return {};
    }
  }

  function writeCache(obj) {
    try {
      localStorage.setItem(CACHE_KEY, JSON.stringify(obj));
    } catch (e) {
      /* ignore quota / privacy-mode errors */
    }
  }

  // --- Data ----------------------------------------------------------------
  // Set when a fetch is cut short by the GitHub rate limit (403), so the
  // UI can show a non-fatal notice instead of breaking.
  var gRateLimited = false;

  function fetchIssues(state) {
    var cache = readCache();
    if (cache[state] && Date.now() - cache[state].ts < CACHE_TTL) {
      return Promise.resolve(cache[state].data);
    }

    // Paginate through every page so counts/stats are accurate.
    // GitHub's REST API caps results at 1000 per query (page 10 with
    // per_page=100); beyond that it returns 422, which we treat as "no
    // more pages". A 403 means we hit the hourly rate limit, so we stop
    // and use whatever we already collected rather than throwing.
    gRateLimited = false;
    var collected = [];
    var MAX_PAGE = 10;
    function page(n) {
      if (n > MAX_PAGE) return collected;
      var url =
        API +
        "?state=" +
        state +
        "&per_page=100&sort=created&direction=desc&page=" +
        n;
      return fetch(url, { headers: { Accept: "application/vnd.github+json" } })
        .then(function (res) {
          if (res.status === 422) return collected; // hit the 1000-result cap
          if (res.status === 403) {
            gRateLimited = true;
            return collected; // rate limited: use partial data
          }
          if (!res.ok) {
            var err = new Error("GitHub API returned " + res.status);
            err.status = res.status;
            throw err;
          }
          return res.json();
        })
        .then(function (data) {
          if (!data || !data.length) return collected;
          collected = collected.concat(data);
          if (data.length < 100) return collected; // last page
          return page(n + 1);
        });
    }

    return page(1).then(function (data) {
      cache[state] = { ts: Date.now(), data: data };
      writeCache(cache);
      return data;
    });
  }

  // --- Rendering -----------------------------------------------------------
  function renderIssue(issue) {
    var stateClass =
      issue.state === "closed" ? "gh-state-closed" : "gh-state-open";

    var labels = el("div", { class: "gh-issue-labels" });
    (issue.labels || []).forEach(function (label) {
      var color = "#" + (label.color || "888888");
      var textColor = pickTextColor(color);
      labels.appendChild(
        el("span", {
          class: "gh-label",
          text: label.name,
          style:
            "background:" +
            color +
            ";color:" +
            textColor +
            ";border-color:" +
            color +
            ";",
        })
      );
    });

    var meta = el("div", { class: "gh-issue-meta" }, [
      el("span", { text: "#" + issue.number }),
      el("span", { text: "opened by " + issue.user.login }),
      el("span", { text: timeAgo(issue.created_at) }),
      el("span", { text: issue.comments + " comments" }),
    ]);

    var titleLink = el("a", {
      class: "gh-issue-title",
      href: issue.html_url,
      target: "_blank",
      rel: "noopener",
      text: issue.title,
    });

    var header = el("div", { class: "gh-issue-header" }, [
      titleLink,
      el("span", { class: "gh-state " + stateClass, text: issue.state }),
    ]);

    var main = el("div", { class: "gh-issue-main" }, [
      header,
      meta,
    ]);

    return el("div", { class: "gh-issue", "data-title": issue.title.toLowerCase() }, [
      main,
      labels,
    ]);
  }

  function pickTextColor(hex) {
    var c = hex.replace("#", "");
    if (c.length === 3) c = c[0] + c[0] + c[1] + c[1] + c[2] + c[2];
    var r = parseInt(c.substr(0, 2), 16);
    var g = parseInt(c.substr(2, 2), 16);
    var b = parseInt(c.substr(4, 2), 16);
    var lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return lum > 0.6 ? "#1a1a1a" : "#ffffff";
  }

  // Tags currently selected in the sidebar (multi-select, OR semantics).
  var selectedLabels = [];

  function renderList(container, issues, query) {
    // Filter out pull requests (the API returns PRs as issues).
    var real = issues.filter(function (i) {
      return !i.pull_request;
    });

    if (query) {
      var q = query.toLowerCase();
      real = real.filter(function (i) {
        return (
          i.title.toLowerCase().indexOf(q) !== -1 ||
          String(i.number).indexOf(q) !== -1 ||
          (i.user && i.user.login.toLowerCase().indexOf(q) !== -1)
        );
      });
    }

    if (selectedLabels.length) {
      real = real.filter(function (i) {
        var names = (i.labels || []).map(function (l) {
          return l.name;
        });
        return selectedLabels.some(function (name) {
          return names.indexOf(name) !== -1;
        });
      });
    }

    container.innerHTML = "";

    if (!real.length) {
      container.appendChild(
        el("p", { class: "gh-empty", text: "No issues found." })
      );
      return;
    }

    var summary = el("p", {
      class: "gh-summary",
      text: real.length + (query ? " matching issue(s)" : " issue(s)"),
    });
    container.appendChild(summary);

    real.forEach(function (issue) {
      container.appendChild(renderIssue(issue));
    });
  }

  function showError(container, err) {
    container.innerHTML = "";
    var msg =
      err && err.status === 403
        ? "GitHub API rate limit reached. Please try again later or view issues directly on GitHub."
        : "Could not load issues. " +
          (err && err.message ? err.message : "") +
          " You can view them on GitHub instead.";
    container.appendChild(
      el("div", { class: "gh-error" }, [
        el("p", { text: msg }),
        el("p", {}, [
          el("a", {
            href: "https://github.com/" + REPO + "/issues",
            target: "_blank",
            rel: "noopener",
            text: "Open GitHub Issues →",
          }),
        ]),
      ])
    );
  }

  // --- Init ----------------------------------------------------------------
  function init() {
    var container = document.getElementById("gh-issues");
    if (!container) return;

    var filters = document.querySelectorAll(".gh-filter");
    var search = document.getElementById("gh-issues-search");
    var labelsContainer = document.getElementById("gh-labels");
    var clearBtn = document.getElementById("gh-labels-clear");
    var currentState = "open";
    var allData = []; // full dataset (all states), fetched once
    var data = []; // filtered view for the list

    function refresh() {
      renderList(container, data, search ? search.value.trim() : "");
    }

    // Build the tag sidebar from the currently loaded issues, grouped by
    // category (Type / Branch / Severity / Other).
    function buildLabels() {
      if (!labelsContainer) return;

      var map = {};
      allData.forEach(function (i) {
        (i.labels || []).forEach(function (l) {
          if (!map[l.name]) map[l.name] = l;
        });
      });

      var names = Object.keys(map).sort(function (a, b) {
        return a.toLowerCase().localeCompare(b.toLowerCase());
      });

      labelsContainer.innerHTML = "";

      if (!names.length) {
        labelsContainer.appendChild(
          el("p", { class: "gh-empty", text: "No tags." })
        );
        if (clearBtn) clearBtn.hidden = true;
        return;
      }

      // Bucket labels by category, preserving TAG_CATEGORIES order then Other.
      var buckets = {};
      var catByName = {};
      TAG_CATEGORIES.forEach(function (c) {
        buckets[c.name] = [];
        catByName[c.name] = c;
      });
      buckets[OTHER_CATEGORY] = [];

      names.forEach(function (name) {
        buckets[categoryOf(name)].push(name);
      });

      // Order each bucket by its category's keyword order (Other = alpha).
      TAG_CATEGORIES.forEach(function (c) {
        buckets[c.name].sort(function (a, b) {
          return keywordIndexOf(c, a) - keywordIndexOf(c, b);
        });
      });
      buckets[OTHER_CATEGORY].sort(function (a, b) {
        return a.toLowerCase().localeCompare(b.toLowerCase());
      });

      var orderedCats = TAG_CATEGORIES.map(function (c) {
        return c.name;
      }).concat(OTHER_CATEGORY);

      orderedCats.forEach(function (catName) {
        var bucket = buckets[catName];
        if (!bucket.length) return;

        labelsContainer.appendChild(
          el("p", { class: "gh-label-cat", text: catName })
        );

        bucket.forEach(function (name) {
          var label = map[name];
          var color = "#" + (label.color || "888888");
          var chip = el("button", {
            class: "gh-label-filter",
            type: "button",
            "data-label": name,
            text: name,
            style:
              "background:" +
              color +
              ";color:" +
              pickTextColor(color) +
              ";border-color:" +
              color +
              ";",
          });
          if (selectedLabels.indexOf(name) !== -1) chip.classList.add("active");
          chip.addEventListener("click", function () {
            var idx = selectedLabels.indexOf(name);
            if (idx === -1) selectedLabels.push(name);
            else selectedLabels.splice(idx, 1);
            chip.classList.toggle("active");
            if (clearBtn) clearBtn.hidden = selectedLabels.length === 0;
            refresh();
          });
          labelsContainer.appendChild(chip);
        });
      });

      if (clearBtn) clearBtn.hidden = selectedLabels.length === 0;
    }

    // Filter the full dataset by the selected state and refresh the list.
    // No network request — tab switches are instant and free.
    function applyState(state) {
      currentState = state;
      data = allData.filter(function (i) {
        return state === "all" ? true : i.state === state;
      });
      // Drop selections that no longer exist in the full dataset.
      var present = {};
      allData.forEach(function (i) {
        (i.labels || []).forEach(function (l) {
          present[l.name] = true;
        });
      });
      selectedLabels = selectedLabels.filter(function (n) {
        return present[n];
      });
      buildLabels();
      refresh();
      if (gRateLimited) {
        container.appendChild(
          el("p", {
            class: "gh-note",
            text:
              "GitHub API rate limit reached — showing partial results. " +
              "Full data loads after the limit resets.",
          })
        );
      }
    }

    // Fetch the full dataset ONCE (covers open + closed) and derive both
    // the list and the leaderboard from it. This keeps us well under the
    // 60 req/hour unauthenticated limit.
    function load() {
      container.innerHTML = '<p class="gh-loading">Loading issues…</p>';
      if (labelsContainer)
        labelsContainer.innerHTML = '<p class="gh-loading">Loading tags…</p>';
      fetchIssues("all")
        .then(function (issues) {
          allData = issues;
          applyState(currentState);
        })
        .catch(function (err) {
          showError(container, err);
        });
    }

    filters.forEach(function (btn) {
      btn.addEventListener("click", function () {
        filters.forEach(function (b) {
          b.classList.remove("active");
        });
        btn.classList.add("active");
        applyState(btn.getAttribute("data-state"));
      });
    });

    if (search) {
      search.addEventListener("input", refresh);
    }

    if (clearBtn) {
      clearBtn.addEventListener("click", function () {
        selectedLabels = [];
        if (labelsContainer) {
          var chips = labelsContainer.querySelectorAll(".gh-label-filter");
          chips.forEach(function (c) {
            c.classList.remove("active");
          });
        }
        clearBtn.hidden = true;
        refresh();
      });
    }

    load();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
