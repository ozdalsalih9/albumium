"""Converts the generated paper and scrapbook art from PNG to WebP.

The Dart renderers in this folder can only write PNG: Flutter's
`toByteData` offers no other format and the `image` package decodes WebP
but does not encode it. PNG costs about five times the bytes here, all of
it in the download users pay for, so the renderers are followed by this.

Run it after `render_scrapbook_assets.dart` or
`render_scrapbook_previews.dart`:

    python -I tool/png_to_webp.py

Quality 95 rather than lossless: these are paper textures and patterns,
where the noise hides what little the encoder throws away, and lossless
WebP saves a third where this saves four fifths. Transparency is not at
risk either way - libwebp compresses the alpha channel separately and
losslessly, so cut edges and lace stay crisp.

A test asserts no PNG is left in these folders, so a regeneration that
forgets this step fails the suite rather than shipping.
"""

import pathlib
import sys

from PIL import Image

FOLDERS = ("assets/paper_kit", "assets/scrapbook")
QUALITY = 95


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    before = after = 0
    converted = 0
    for folder in FOLDERS:
        for png in sorted((root / folder).glob("*.png")):
            webp = png.with_suffix(".webp")
            with Image.open(png) as image:
                image.load()
                image.save(webp, "WEBP", quality=QUALITY, method=6)
            before += png.stat().st_size
            after += webp.stat().st_size
            png.unlink()
            converted += 1
    if not converted:
        print("No PNG left to convert.")
        return 0
    mb = 1024 * 1024
    print(
        f"{converted} files: {before / mb:.2f} MB PNG -> "
        f"{after / mb:.2f} MB WebP "
        f"({100 - 100 * after / before:.0f}% smaller)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
