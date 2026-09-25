import os
from markdown import Markdown
from pymdownx import emoji as pymdownx_emoji

def custom_emoji_index(options: dict, md: Markdown):
    """Build a custom emoji index from local PNGs."""
    base_path = options.get("custom_emoji_base_path")
    if not base_path:
        raise ValueError("custom_emoji_base_path is required for custom emoji index.")

    custom_index = {}
    # Scan the directory for PNG files
    for filename in os.listdir(base_path):
        if filename.endswith(".png"):
            shortname = os.path.splitext(filename)[0]
            # The format is a tuple: (category, path)
            custom_index[f":{shortname}:"] = ("custom", f"{base_path}/{filename}")

    return custom_index

def custom_emoji_generator(index, shortname, alias, uc, alt, title, category, options, md):
    """Generate HTML for a custom PNG emoji."""
    # Find the path from our custom index
    path = index.get(shortname)
    if path:
        return f'<img class="emoji" src="/{path[1]}" alt="{alt}" title="{title}">'

    # Fallback to the default generator if not found
    return pymdownx_emoji.to_png(index, shortname, alias, uc, alt, title, category, options, md)
