"""Derive the site's brand assets from the organization banner.

The visual identity of OpenSymbolicRules is defined in the organization
profile repository (OpenSymbolicRules/.github, profile/assets/banner.png).
This script copies the banner and derives a logo (the expression-tree motif
on the navy ink of the banner), a favicon and a social preview image, so the
site never carries a hand-made copy.

Usage: python3 -I scripts/brand-assets.py BANNER OUT
"""
import pathlib
import shutil
import sys

from PIL import Image, ImageDraw

# Palette sampled from the banner.
NAVY = (6, 33, 47)        # ink of the node labels
TEAL = (92, 187, 184)     # operator nodes
AMBER = (246, 173, 72)    # constant node
CREAM = (245, 238, 229)   # title and leaf nodes

# Box of the left expression tree (a × b + 0) in the 2170 × 725 banner.
TREE_BOX = (0.035, 0.205, 0.214, 0.785)


def rounded_square(size, color, radius):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle((0, 0, size - 1, size - 1), radius, fill=color + (255,))
    return img


def build(banner_path, out):
    banner_path = pathlib.Path(banner_path)
    if not banner_path.is_file():
        raise FileNotFoundError(banner_path)
    out = pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(banner_path, out / "banner.png")
    banner = Image.open(banner_path).convert("RGBA")
    w, h = banner.size

    x0, y0, x1, y1 = TREE_BOX
    tree = banner.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
    side = max(tree.size)
    canvas = rounded_square(int(side * 1.12), NAVY, int(side * 0.16))
    off = ((canvas.width - tree.width) // 2, (canvas.height - tree.height) // 2)
    canvas.alpha_composite(tree, off)
    canvas.resize((256, 256), Image.LANCZOS).save(out / "logo.png")
    canvas.resize((64, 64), Image.LANCZOS).save(out / "favicon.png")

    og = Image.new("RGBA", (1200, 630), NAVY + (255,))
    scaled = banner.resize((1120, int(h * 1120 / w)), Image.LANCZOS)
    og.alpha_composite(scaled, ((1200 - scaled.width) // 2, (630 - scaled.height) // 2))
    og.convert("RGB").save(out / "og.png")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    build(sys.argv[1], sys.argv[2])
