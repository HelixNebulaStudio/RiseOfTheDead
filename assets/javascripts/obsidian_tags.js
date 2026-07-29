// Obsidian-style [[wiki links]] and .hash anchors, vanilla JS (no jQuery).
function parse_wiki_links(root) {
  var nodes = root.querySelectorAll(
    "p, li, td, th, h1, h2, h3, h4, h5, h6"
  );
  Array.prototype.forEach.call(nodes, function (el) {
    var html = el.innerHTML;
    if (!html || html.indexOf("[[") === -1) return;

    html = html.replace(
      /\[\[([^\[\]\|]+)(?:\|([^\[\]]+))?\]\]/g,
      function (match, target, alias) {
        var page = target.trim();
        var label = (alias || page).trim();
        return (
          '<a class="wiki-link" href="?q=' +
          encodeURIComponent(page) +
          '">' +
          label +
          "</a>"
        );
      }
    );

    el.innerHTML = html;
  });
}

function initObsidianTags() {
  console.log("Linking pages");

  var hashes = document.querySelectorAll(".hash");
  Array.prototype.forEach.call(hashes, function (el) {
    var link = el.innerHTML;
    var wrapper = document.createElement("a");
    wrapper.setAttribute("href", "?q=" + link);
    wrapper.textContent = "#";
    while (el.firstChild) {
      wrapper.appendChild(el.firstChild);
    }
    el.appendChild(wrapper);
  });

  parse_wiki_links(document.body);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initObsidianTags);
} else {
  initObsidianTags();
}
