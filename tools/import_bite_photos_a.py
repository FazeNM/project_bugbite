"""Import individually reviewed public-domain photographs, without generative edits.

Sources and licensing are recorded in docs/BITE_PHOTO_SOURCES_A.md.
The original frame is preserved; only EXIF orientation, size, and JPEG encoding
are normalized for a mobile bundle. No retouching or AI processing is used.
"""

from io import BytesIO
from pathlib import Path
from urllib.request import Request, urlopen

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PHOTOS = {
    "source_a_mosquito_forearm.jpg": "https://wwwn.cdc.gov/phil/PHIL_Images/28621/28621_lores.jpg",
    "source_a_mosquito_three_bites.jpg": "https://wwwn.cdc.gov/phil/PHIL_Images/28632/28632_lores.jpg",
    "source_a_mosquito_redness.jpg": "https://wwwn.cdc.gov/phil/PHIL_Images/28634/28634_lores.jpg",
    "source_a_chigger_foot.jpg": "https://upload.wikimedia.org/wikipedia/commons/2/21/Chigger_bites.jpg",
    "source_a_chigger_ankle.jpg": "https://upload.wikimedia.org/wikipedia/commons/b/b8/TrombiculosisSores.jpg",
    "source_a_bedbug_reaction.jpg": "https://upload.wikimedia.org/wikipedia/commons/f/fe/Bedbug_bites.jpg",
    "source_a_bedbug_leg.jpg": "https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f3/Bedbug_bites_on_human_leg_1.jpg/1280px-Bedbug_bites_on_human_leg_1.jpg",
    "source_a_bedbug_thigh.jpg": "https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f3/Bedbug_bites_on_human_thight_1.jpg/1280px-Bedbug_bites_on_human_thight_1.jpg",
}


def main():
    for filename, url in PHOTOS.items():
        target = ROOT / "assets/images/bites" / filename
        if target.exists():
            print(f"Already imported: {filename}")
            continue
        request = Request(url, headers={"User-Agent": "BitewiseReferencePhotoImporter/1.0 (educational mobile app)"})
        try:
            with urlopen(request, timeout=45) as response:
                data = response.read()
            with Image.open(BytesIO(data)) as original:
                photo = ImageOps.exif_transpose(original).convert("RGB")
                photo.thumbnail((1400, 1400), Image.Resampling.LANCZOS)
                photo.save(target, "JPEG", quality=90, optimize=True)
            print(f"Imported {filename}: {photo.size}, {target.stat().st_size} bytes")
        except Exception as error:
            print(f"FAILED {filename}: {error}")


if __name__ == "__main__":
    main()
