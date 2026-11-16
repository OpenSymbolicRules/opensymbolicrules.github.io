"""Tests for brand-assets.py (run: python3 -I scripts/test_brand_assets.py)."""
import importlib.util
import pathlib
import sys
import tempfile
import unittest

from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("brand_assets", HERE / "brand-assets.py")
brand = importlib.util.module_from_spec(spec)
spec.loader.exec_module(brand)


class BrandAssetsTest(unittest.TestCase):
    def test_derived_assets(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = pathlib.Path(tmp)
            banner = tmp / "banner.png"
            Image.new("RGBA", (2170, 725), (92, 187, 184, 255)).save(banner)
            out = tmp / "out"
            brand.build(banner, out)
            self.assertEqual(Image.open(out / "banner.png").size, (2170, 725))
            self.assertEqual(Image.open(out / "logo.png").size, (256, 256))
            self.assertEqual(Image.open(out / "favicon.png").size, (64, 64))
            self.assertEqual(Image.open(out / "og.png").size, (1200, 630))
            # The logo sits on the navy ink of the identity, so it reads on light pages.
            self.assertEqual(Image.open(out / "logo.png").convert("RGB").getpixel((128, 4)), brand.NAVY)

    def test_missing_banner_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(FileNotFoundError):
                brand.build(pathlib.Path(tmp) / "none.png", pathlib.Path(tmp) / "out")


if __name__ == "__main__":
    sys.exit(unittest.main())
