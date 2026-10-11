"""Resize newly sourced photographs for mobile delivery, without retouching.

Requires Pillow. Source and credit information is retained in
THIRD_PARTY_NOTICES.md rather than in photo metadata. Run from any directory.
"""

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1] / "assets/images"
PHOTOS = (
    "contexts/dog_scratching.jpg",
    "contexts/handwashing.jpg",
    "guides/paper_wasp.jpg",
    "guides/asian_tiger_mosquito.jpg",
    "bites/bed_bug_bites.jpg",
)


def main() -> None:
    for relative in PHOTOS:
        path = ROOT / relative
        with Image.open(path) as source:
            if max(source.size) <= 1600:
                continue
            photo = ImageOps.exif_transpose(source).convert("RGB")
            photo.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
            photo.save(path, quality=88, optimize=True)
            print(f"{relative}: {photo.width} x {photo.height}")


if __name__ == "__main__":
    main()
