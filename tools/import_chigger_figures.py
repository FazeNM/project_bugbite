"""Extract the two public-domain photographs from the cited Cutis PDF.

Usage: python tools/import_chigger_figures.py tmp/pdfs/chiggers-source.pdf
The original embedded JPEG bytes are preserved; no generated pixels or article
text are included in the app assets.
"""

import sys
from pathlib import Path

from pypdf import PdfReader


def main() -> None:
    reader = PdfReader(sys.argv[1])
    if "All images are in the public domain." not in reader.pages[0].extract_text():
        raise ValueError("The expected public-domain declaration is missing.")
    root = Path(__file__).resolve().parents[1]
    outputs = [
        root / "assets/images/guides/chigger.jpg",
        root / "assets/images/bites/chigger_ankle.jpg",
    ]
    for page, output in zip(reader.pages, outputs):
        if len(page.images) != 1:
            raise ValueError("Expected one photograph per source page.")
        original = page.images[0]
        if not original.data.startswith(b"\xff\xd8"):
            raise ValueError("Expected an embedded JPEG photograph.")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(original.data)
        print(f"Extracted {output.name}: {original.image.size}")


if __name__ == "__main__":
    main()
