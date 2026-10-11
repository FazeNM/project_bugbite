# Additional bite-reference photographs

Reviewed and imported on 2026-09-13. These eight photographs are additions to the existing bite-image collection. None is AI-generated. They are source-reported educational examples, not a way to confirm a person's diagnosis. Do not imply that all bites look like these examples or that a visual match establishes the cause.

The three CDC files individually state that copyright restrictions are **None** and that the image is in the public domain. CDC federal-work public-domain status applies in the United States; no worldwide legal guarantee is made. The five Commons photographs have a specific author public-domain dedication applying worldwide, with an unrestricted fallback grant where such a dedication is not possible. The Commons site's general CC0 metadata footer is **not** the basis for any image license.

## Provenance and license evidence

All assets below are in `assets/images/bites/`. Use the linked file-specific record for the full license statement and context; keep these credits as a courtesy.

| Asset | Guide ID | Source and creator | License evidence | What the source reports |
| --- | --- | --- | --- | --- |
| `source_a_mosquito_forearm.jpg` | `mosquito` | [CDC PHIL 28621](https://wwwn.cdc.gov/phil/Details.aspx?pid=28621), CDC / Division of Vector-Borne Diseases, Rickettsial Zoonoses Branch; photograph by Lauren Bishop, 2024 | The individual PHIL record's Copyright Restrictions field states None / public domain. | A mosquito-bite reaction on the left lateral forearm. The supplied photograph already includes a black circle marking the reaction. |
| `source_a_mosquito_three_bites.jpg` | `mosquito` | [CDC PHIL 28632](https://wwwn.cdc.gov/phil/Details.aspx?pid=28632), CDC / Division of Vector-Borne Diseases, Rickettsial Zoonoses Branch; photograph by Lauren Bishop, 2024 | The individual PHIL record's Copyright Restrictions field states None / public domain. | Three swollen areas caused by three separate mosquito bites on the right ventral forearm. |
| `source_a_mosquito_redness.jpg` | `mosquito` | [CDC PHIL 28634](https://wwwn.cdc.gov/phil/Details.aspx?pid=28634), CDC / Division of Vector-Borne Diseases, Rickettsial Zoonoses Branch; photograph by Lauren Bishop, 2024 | The individual PHIL record's Copyright Restrictions field states None / public domain. | Reddened skin around a mosquito-bite reaction on the right ventral forearm. |
| `source_a_chigger_foot.jpg` | `chigger` | [Chigger bites.jpg](https://commons.wikimedia.org/wiki/File:Chigger_bites.jpg), TimVickers, uploaded 2008 | Licensing section: author's own-work public-domain dedication (PD-self), worldwide and unrestricted fallback grant. | The photographer describes harvest-mite bites on a foot and names *Trombicula alfreddugesi*. This is a source-reported identification, not independently confirmed by this app. |
| `source_a_chigger_ankle.jpg` | `chigger` | [TrombiculosisSores.jpg](https://commons.wikimedia.org/wiki/File:TrombiculosisSores.jpg), Mark A. Wilson / Wilson44691, 2010 | Licensing section: author's own-work public-domain dedication (PD-self), worldwide and unrestricted fallback grant. | Chigger-related skin reactions on an ankle in Alabama. It is a magnified view with a 3.0 mm scale label already present in the original. Treat as source-reported, not app-confirmed. |
| `source_a_bedbug_reaction.jpg` | `bedbug` | [Bedbug bites.jpg](https://commons.wikimedia.org/wiki/File:Bedbug_bites.jpg), Andy Brookes / Andybrookestar, uploaded 2007 | Licensing section records the author's public-domain release (PD-user), worldwide and unrestricted fallback grant. | The photographer reports photographing, with permission, a woman affected by bed bugs in an infested home. The image shows reactions along the cheek, jaw, and neck. This is source-reported, not app-confirmed. |
| `source_a_bedbug_leg.jpg` | `bedbug` | [Bedbug bites on human leg 1.jpg](https://commons.wikimedia.org/wiki/File:Bedbug_bites_on_human_leg_1.jpg), KEBman / Krister Brandser, 2009 | Licensing section: author's own-work public-domain dedication (PD-self), worldwide and unrestricted fallback grant. Older camera copyright metadata does not change the author's explicit release on the source page. | Reported bed-bug bites on a leg, including several pink-red raised marks. This is source-reported, not app-confirmed. |
| `source_a_bedbug_thigh.jpg` | `bedbug` | [Bedbug bites on human thight 1.jpg](https://commons.wikimedia.org/wiki/File:Bedbug_bites_on_human_thight_1.jpg), KEBman / Krister Brandser, 2009 | Licensing section: author's own-work public-domain dedication (PD-self), worldwide and unrestricted fallback grant. Older camera copyright metadata does not change the author's explicit release on the source page. | Reported bed-bug bites on a thigh, with a small cluster of red marks. Source filename retains its original spelling. This is source-reported, not app-confirmed. |

## Display text

| Asset | Neutral caption | Accessible description |
| --- | --- | --- |
| `source_a_mosquito_forearm.jpg` | Mosquito reaction on a forearm · CDC | A small pink bump on a forearm, circled in the original CDC photograph. |
| `source_a_mosquito_three_bites.jpg` | Three mosquito reactions · CDC | Three adjacent raised pink mosquito-bite reactions on a forearm. |
| `source_a_mosquito_redness.jpg` | Redness around a mosquito bite · CDC | Close view of reddened skin around a mosquito-bite reaction on a forearm. |
| `source_a_chigger_foot.jpg` | Reported chigger bites on a foot | Scattered reddish marks on the side of a foot and around the ankle. |
| `source_a_chigger_ankle.jpg` | Reported chigger reactions · Magnified | Magnified reddish ankle reactions with the original 3.0 millimeter scale label. |
| `source_a_bedbug_reaction.jpg` | Reported bed bug reactions on the jaw | Pink-red raised reactions along the cheek, jaw, and side of the neck. |
| `source_a_bedbug_leg.jpg` | Reported bed bug bites on a leg | Several pink-red raised marks clustered on a lower leg. |
| `source_a_bedbug_thigh.jpg` | Reported bed bug bites on a thigh | A small cluster of red marks on a thigh. |

## Import and visual inspection

`tools/import_bite_photos_a.py` records the exact downloaded image URLs. The complete source frame is preserved: no crops, montages, retouching, color changes, or generative edits. Processing consists only of EXIF orientation normalization, proportional downscaling to a maximum 1400-pixel edge, and JPEG encoding at quality 90. Two bed-bug images use Commons' published 1280-pixel thumbnail URLs, as requested by the server after original-image downloads were rate-limited. These thumbnails preserve the full original frame.

All eight imported images were opened and inspected individually. The mosquito circle and chigger scale label come from their respective sources and were retained. Photographs on different body areas are distinct images; they are not presented as independent clinical case counts.

No additional flea image was imported: available newly located candidates either required an attribution/share-alike license or depicted a disease-specific complication rather than an ordinary bite reaction. Existing verified flea photography remains available in the app.
