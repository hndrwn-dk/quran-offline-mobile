"""Generates the DEV app launcher icon (the release icon plus a "DEV" badge).

Reads the release launcher layers from android/app/src/main/res and writes
the badged copies to android/app/src/dev/res, which Gradle only adds when
QO_APP_ID_SUFFIX is set. Release builds never see these files.

    python tools/make_dev_launcher_icon.py [path/to/bold.ttf]
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
MAIN = ROOT / "android/app/src/main/res"
DEV = ROOT / "android/app/src/dev/res"
FONT = sys.argv[1] if len(sys.argv) > 1 else "C:/Windows/Fonts/arialbd.ttf"

BADGE = (198, 40, 40, 255)
TEXT = (255, 255, 255, 255)
RING = (0xED, 0xF1, 0xD9, 255)  # ic_launcher_background

# Badge box on the 108dp adaptive canvas, inside the 66dp safe circle.
BOX_DP = (38.5, 72.0, 69.5, 83.0)
RING_DP = 1.5

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_dev_foreground"/>
  <monochrome android:drawable="@drawable/ic_launcher_dev_monochrome"/>
</adaptive-icon>
"""


def _badge(size, box, ring, monochrome):
    """A badge layer: a ring that cuts the art, then the pill with the text."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    h = y1 - y0
    font = ImageFont.truetype(FONT, round(h * 0.68))
    cut = Image.new("L", (size, size), 0)
    ImageDraw.Draw(cut).rounded_rectangle(
        (x0 - ring, y0 - ring, x1 + ring, y1 + ring), radius=h / 2 + ring, fill=255
    )
    if monochrome:
        fill, ink = (255, 255, 255, 255), (0, 0, 0, 0)
    else:
        fill, ink = BADGE, TEXT
    draw.rounded_rectangle(box, radius=h / 2, fill=fill)
    text = Image.new("L", (size, size), 0)
    ImageDraw.Draw(text).text(
        ((x0 + x1) / 2, (y0 + y1) / 2), "DEV", font=font, fill=255, anchor="mm"
    )
    if monochrome:
        alpha = layer.getchannel("A")
        alpha.paste(0, mask=text)
        layer.putalpha(alpha)
    else:
        layer.paste(Image.new("RGBA", (size, size), ink), mask=text)
    return layer, cut


def _compose(src, dst, box, ring, monochrome, ring_fill):
    base = Image.open(src).convert("RGBA")
    size = base.width
    layer, cut = _badge(size, box, ring, monochrome)
    if ring_fill is None:
        alpha = base.getchannel("A")
        alpha.paste(0, mask=cut)
        base.putalpha(alpha)
    else:
        base.paste(Image.new("RGBA", base.size, ring_fill), mask=cut)
    base.alpha_composite(layer)
    dst.parent.mkdir(parents=True, exist_ok=True)
    base.save(dst)


def main():
    for folder in sorted(MAIN.glob("drawable-*dpi")):
        fg = folder / "ic_launcher_foreground.png"
        if not fg.exists():
            continue
        scale = Image.open(fg).width / 108
        box = tuple(v * scale for v in BOX_DP)
        out = DEV / folder.name
        _compose(fg, out / "ic_launcher_dev_foreground.png", box,
                 RING_DP * scale, False, None)
        _compose(folder / "ic_launcher_monochrome.png",
                 out / "ic_launcher_dev_monochrome.png", box,
                 RING_DP * scale, True, None)

    # Legacy (pre-26) icons show the middle 72dp of the adaptive canvas.
    for folder in sorted(MAIN.glob("mipmap-*dpi")):
        icon = folder / "ic_launcher.png"
        scale = Image.open(icon).width / 72
        box = tuple((v - 18) * scale for v in BOX_DP)
        _compose(icon, DEV / folder.name / "ic_launcher_dev.png", box,
                 RING_DP * scale, False, RING)

    anydpi = DEV / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher_dev.xml").write_text(ADAPTIVE_XML, encoding="utf-8")


if __name__ == "__main__":
    main()
