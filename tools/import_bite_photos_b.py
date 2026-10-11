"""Download approved PD/CC0 reference photographs and resize without retouching.

Sources and subject limitations are recorded in docs/BITE_PHOTO_SOURCES_B.md.
Only color-space conversion, EXIF orientation, proportionate downscaling, and
JPEG compression occur. No crops, generated content, or clinical alterations.
"""

from io import BytesIO
from pathlib import Path
import argparse
from urllib.request import Request, urlopen

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "source_b_yellow_jacket_hand.jpg": "https://wwwn.cdc.gov/phil/PHIL_Images/15131/15131_lores.jpg",
    "source_b_wasp_sting_thigh.jpg": "https://upload.wikimedia.org/wikipedia/commons/7/72/Wespenstich-2005-07-29.jpg",
    "source_b_bee_sting_two_days.jpg": "https://thumb.wikimedia.org/wikipedia/commons/thumb/2/24/Bee_sting_wound_after_two_days.jpg/960px-Bee_sting_wound_after_two_days.jpg",
    "source_b_tick_attached.jpg": "https://thumb.wikimedia.org/wikipedia/commons/thumb/1/12/Tick_in_my_skin.png/330px-Tick_in_my_skin.png",
    "source_b_tick_on_leg.jpg": "https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e1/Thai_tick.JPG/330px-Thai_tick.JPG",
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--normalize-existing", action="store_true")
    options = parser.parse_args()
    for name, url in SOURCES.items():
        path = ROOT / "assets/images/bites" / name
        if path.exists() and not options.normalize_existing:
            print(f"Already imported: {name}", flush=True)
            continue
        request = Request(url, headers={"User-Agent": "BitewiseReferencePhotoImporter/1.0"})
        try:
            if path.exists():
                data = path.read_bytes()
            else:
                with urlopen(request, timeout=45) as response:
                    data = response.read()
            with Image.open(BytesIO(data)) as source:
                photo = ImageOps.exif_transpose(source).convert("RGB")
                photo.thumbnail((1400, 1400), Image.Resampling.LANCZOS)
                photo.save(path, format="JPEG", quality=90, optimize=True)
                print(f"Imported {name}: {photo.width} x {photo.height}", flush=True)
        except Exception as error:
            print(f"Not imported {name}: {error}", flush=True)


if __name__ == "__main__":
    main()
