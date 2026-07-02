function parse_wiki_links(root) {
  $(root).find('p, li, td, th, h1, h2, h3, h4, h5, h6').each(function() {
    var html = $(this).html();
    if (!html || html.indexOf('[[') === -1) {
      return;
    }

    html = html.replace(/\[\[([^\[\]\|]+)(?:\|([^\[\]]+))?\]\]/g, function(match, target, alias) {
      var page = target.trim();
      var label = (alias || page).trim();
      return '<a class="wiki-link" href="?q=' + encodeURIComponent(page) + '">' + label + '</a>';
    });

    $(this).html(html);
  });
}

$(function() {
  console.log("Linking pages");
  $('.hash').each(function() {
    var link = $(this).html();
    $(this).contents().wrap('<a href="?q=' + link + '">#</a>');
  });

  parse_wiki_links(document.body);
});