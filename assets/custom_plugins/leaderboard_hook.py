"""
leaderboard_hook.py — MkDocs build-time hook for the "Top Exceptionists" leaderboard.

Used as a MkDocs ``hooks`` entry (see mkdocs.yml). Unlike a registered plugin,
a hook is loaded directly from its file path, so it needs no entry point or
PYTHONPATH manipulation.

At build time this hook fetches GitHub issues once, computes per-user stats,
and injects static HTML into the Issues page wherever the ``<!-- LEADERBOARD -->``
marker appears. The result is fast, works without JS, and keeps any GitHub
token server-side.
"""

import os
import json
import urllib.request
import urllib.error

# --- Defaults ---------------------------------------------------------------
REPO = "HelixNebulaStudio/RiseOfTheDead"
RESOLVED_LABEL = "resolved"
EXCLUDE_LABELS = ["duplicate", "invalid", "wontfix", "non-issue"]
TOP_N = 20
TOKEN_ENV = "GITHUB_TOKEN"
MARKER = "<!-- LEADERBOARD -->"

# Cached HTML, computed once in on_config and reused for every page.
_LEADERBOARD_HTML = ""


# --- Data fetching ----------------------------------------------------------
def _fetch_issues():
    """Paginate every issue (incl. closed) from the GitHub REST API."""
    token = os.environ.get(TOKEN_ENV)
    url = (
        "https://api.github.com/repos/" + REPO + "/issues"
        "?state=all&per_page=100&sort=created&direction=desc&page=1"
    )
    headers = {"Accept": "application/vnd.github+json"}
    if token:
        headers["Authorization"] = "Bearer " + token

    collected = []
    page_num = 1
    while page_num <= 10:  # GitHub caps results at 1000 per query
        paged = url.rsplit("page=", 1)[0] + "page=" + str(page_num)
        req = urllib.request.Request(paged, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                if resp.status == 422:  # hit the 1000-result cap
                    break
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 403:  # rate limited
                break
            raise
        if not data or not isinstance(data, list):
            break
        collected.extend(data)
        if len(data) < 100:
            break
        page_num += 1
    return collected


def _compute_stats(issues):
    resolved = RESOLVED_LABEL.lower()
    exclude = [l.lower() for l in EXCLUDE_LABELS]
    stats = {}
    for i in issues:
        if i.get("pull_request"):
            continue
        labels = [l["name"].lower() for l in (i.get("labels") or [])]
        if any(l in exclude for l in labels):
            continue
        user = i.get("user") or {}
        login = user.get("login")
        if not login:
            continue
        entry = stats.get(login)
        if entry is None:
            entry = {"opened": 0, "fixed": 0, "avatar": user.get("avatar_url")}
            stats[login] = entry
        entry["opened"] += 1
        if i.get("state") == "closed" and resolved in labels:
            entry["fixed"] += 1
    return stats


def _build_html():
    try:
        issues = _fetch_issues()
        stats = _compute_stats(issues)
    except Exception:  # build should not hard-fail on network errors
        return (
            '<h3 class="gh-sidebar-title">Top Exceptionists</h3>'
            '<p class="gh-empty">Leaderboard unavailable (build-time fetch failed).</p>'
        )

    rows = [
        {"user": u, "fixed": s["fixed"], "avatar": s["avatar"]}
        for u, s in stats.items()
        if s["fixed"] > 0
    ]
    rows.sort(key=lambda r: r["fixed"], reverse=True)
    rows = rows[:TOP_N]

    if not rows:
        return (
            '<h3 class="gh-sidebar-title">Top Exceptionists</h3>'
            '<p class="gh-empty">No data.</p>'
        )

    parts = ['<h3 class="gh-sidebar-title">Top Exceptionists</h3>', '<div class="gh-lb-list">']
    for idx, r in enumerate(rows, start=1):
        if r["avatar"]:
            avatar = (
                '<img class="gh-lb-avatar" src="' + r["avatar"] +
                '" alt="' + r["user"] + '" loading="lazy">'
            )
        else:
            avatar = '<span class="gh-lb-avatar gh-lb-avatar--empty"></span>'
        parts.append(
            '<div class="gh-lb-row">'
            '<span class="gh-lb-rank">' + str(idx) + "</span>"
            + avatar
            + '<a class="gh-lb-user" href="https://github.com/' + r["user"]
            + '" target="_blank" rel="noopener">' + r["user"] + "</a>"
            '<span class="gh-lb-count">' + str(r["fixed"]) + "</span>"
            "</div>"
        )
    parts.append("</div>")
    return "".join(parts)


# --- MkDocs hook events -----------------------------------------------------
def on_config(config):
    global _LEADERBOARD_HTML
    _LEADERBOARD_HTML = _build_html()
    return config


def on_page_markdown(markdown, page, config, files):
    if page.file.src_path.lower().endswith("issues.md"):
        global _LEADERBOARD_HTML
        markdown = markdown.replace(MARKER, _LEADERBOARD_HTML)
    return markdown
