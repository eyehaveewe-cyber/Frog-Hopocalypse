#!/usr/bin/env python3
"""Place actual #6/#4 preview pixels; never redraw, recolor or resample them."""
from pathlib import Path
import hashlib
import io
import json
import zipfile
from xml.etree import ElementTree as ET
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/previews/hat-variations/Hopan-hat-six-previews.png"
ART = ROOT / "art-source/splash"
OUT = ROOT / "game/art/splash"
PANELS = {"wrapped": (1032, 512, 1524, 968), "layered": (12, 512, 504, 968)}
NUMBERS = {"wrapped": 6, "layered": 4}
# Hat comparison bounds, including ornament and #4 tails. Only opaque
# cutout samples are compared; removed surrounding scenery is excluded.
HAT = {"wrapped": (50, 30, 425, 282), "layered": (50, 40, 425, 303)}
OUTLINES = {
    "wrapped": [(231,40),(263,40),(263,58),(259,58),(259,75),(276,77),(288,80),(300,85),(312,92),(323,99),(334,109),(344,119),(353,132),(362,149),(370,168),(378,188),(389,211),(400,233),(411,250),(413,257),(405,263),(389,268),(372,273),(363,269),(368,279),(363,287),(353,299),(363,308),(376,324),(384,341),(390,359),(389,374),(382,389),(375,396),(379,407),(369,416),(349,416),(338,410),(327,414),(308,419),(293,424),(271,429),(227,430),(201,427),(180,423),(166,418),(153,415),(144,414),(132,417),(114,415),(103,411),(104,399),(112,389),(100,382),(92,370),(87,354),(88,337),(97,319),(115,305),(120,301),(109,291),(100,278),(95,272),(88,273),(74,269),(62,263),(56,256),(60,246),(68,229),(75,209),(83,189),(91,168),(100,149),(108,134),(114,121),(127,108),(141,97),(158,87),(175,81),(195,77),(216,75),(230,76)],
    "layered": [(232,51),(263,51),(263,63),(259,67),(257,96),(283,96),(304,102),(328,114),(346,127),(355,145),(363,158),(374,187),(385,215),(398,237),(407,249),(410,258),(413,264),(411,277),(401,288),(389,298),(377,307),(366,310),(364,296),(356,307),(368,321),(380,340),(388,358),(388,376),(381,392),(373,397),(378,409),(368,417),(349,417),(334,412),(324,418),(302,424),(276,429),(226,430),(195,427),(177,421),(158,415),(145,413),(137,418),(116,415),(105,409),(105,398),(111,390),(101,385),(91,372),(86,355),(89,336),(97,319),(114,306),(118,303),(106,302),(94,294),(82,283),(74,269),(69,254),(68,244),(77,221),(86,199),(94,175),(103,154),(112,139),(120,128),(136,119),(151,107),(170,99),(193,97),(217,97),(231,97)],
}
SOURCE_SHA256 = "2ae5269526c16b606ae0c79e5c31f18b89793133d60c04ca8320e5777ed99d80"
HAT_EDGES = {
    "wrapped": (
        [(230,40),(230,57),(230,75),(203,76),(190,80),(178,85),(169,90),(163,95),(158,100),(146,110),(137,120),(128,130),(122,140),(115,150),(109,160),(105,165),(93,190),(91,195),(89,200),(88,205),(75,230),(71,240),(66,250),(68,255),(79,260),(101,270),(110,274)],
        [(263,40),(263,57),(263,75),(282,76),(299,80),(307,85),(316,90),(324,95),(332,100),(343,110),(354,120),(359,130),(370,140),(376,150),(381,160),(383,165),(392,190),(397,195),(397,200),(400,205),(401,210),(412,230),(413,235),(416,240),(417,245),(420,250),(417,255),(410,260),(393,270),(380,274)]),
    "layered": (
        [(229,51),(229,63),(225,76),(225,90),(219,96),(190,100),(169,110),(155,120),(143,125),(134,130),(132,140),(117,150),(114,160),(110,170),(106,180),(100,185),(94,195),(86,210),(83,215),(81,225),(76,230),(72,240),(68,245),(70,255),(73,260),(81,270),(88,280),(99,290),(106,295),(116,300)],
        [(263,51),(261,63),(263,76),(263,90),(281,96),(300,100),(318,110),(339,120),(354,125),(364,130),(366,140),(374,150),(378,160),(382,170),(388,180),(394,195),(398,210),(400,215),(407,225),(411,230),(414,240),(417,245),(417,255),(413,260),(406,270),(399,280),(386,290),(381,295),(376,300)])}


def png_bytes(image):
    result = io.BytesIO()
    image.save(result, format="PNG")
    return result.getvalue()


def main():
    source_bytes = SOURCE.read_bytes()
    source_hash = hashlib.sha256(source_bytes).hexdigest()
    assert source_hash == SOURCE_SHA256, "Selected source changed; verify before updating crops"
    source = Image.open(io.BytesIO(source_bytes)).convert("RGBA")
    assert source.size == (1536, 1024)
    selected = ART / "selected"
    selected.mkdir(exist_ok=True)
    evidence = {"source": str(SOURCE.relative_to(ROOT)), "sha256": source_hash,
                "method": "Exact crops, native-resolution placement; no RGB edits or resampling",
                "exports": []}
    for style, bounds in PANELS.items():
        crop = source.crop(bounds)
        crop.save(selected / f"{NUMBERS[style]}-source.png")
        # Keep the selected frog and hat together. This mask cuts the original
        # silhouette; it does not paint any new RGB pixels. A one-pixel guard
        # retains edge pixels rather than eroding the source artwork.
        mask = Image.new("L", crop.size)
        draw = ImageDraw.Draw(mask)
        draw.polygon(OUTLINES[style], fill=255)
        # The coarse body trace is replaced above the cheeks by hat edges
        # measured from this source panel, so no crown or side stripe is lost.
        draw.rectangle((0, 0, crop.width, 273), fill=0)
        left, right = HAT_EDGES[style]
        draw.polygon(left + list(reversed(right)), fill=255)
        mask = mask.filter(ImageFilter.MaxFilter(3))
        mask.save(selected / f"{NUMBERS[style]}-seam-mask.png")
        foreground = crop.copy()
        foreground.putalpha(mask)
        foreground.save(selected / f"{NUMBERS[style]}-foreground.png")
        for layout in ["wide", "compact", "portrait"]:
            suffix = ("layered-" if style == "layered" else "") + layout
            base_directory = ART / "layers" / layout
            working = (216, 384) if layout == "portrait" else (384, 216)
            size = tuple(n * 4 for n in working)
            layers = []
            canvas = Image.new("RGBA", size)
            for name in ["01-sky-moon", "02-distant-sanctuary", "03-water-lily-pads", "04-stones-reeds"]:
                image = Image.open(base_directory / f"{name}.png").convert("RGBA")
                assert image.size == working
                image = image.resize(size, Image.Resampling.NEAREST)
                canvas.alpha_composite(image)
                layers.append((name, image))
            x = 99 if layout == "portrait" else (62 if layout == "compact" else 109)
            y = (166 if layout == "portrait" else 193) - 31
            offset = (x * 4 - crop.width // 2, (y + 31) * 4 - 414)
            figure = Image.new("RGBA", size)
            figure.alpha_composite(foreground, offset)
            canvas.alpha_composite(figure)
            layers.append(("05-exact-selected-" + str(NUMBERS[style]), figure))
            quiet = Image.open(base_directory / "08-menu-quiet-field.png").convert("RGBA")
            assert quiet.size == working
            quiet = quiet.resize(size, Image.Resampling.NEAREST)
            # The old quiet-field pass also has decorative glints. Never let
            # one paint over the selected character and change source pixels.
            quiet.putalpha(ImageChops.subtract(quiet.getchannel("A"), figure.getchannel("A")))
            canvas.alpha_composite(quiet)
            layers.append(("06-menu-quiet-field", quiet))
            final = canvas.convert("RGB")
            protected = HAT[style]
            target_bounds = tuple(protected[i] + offset[i % 2] for i in range(4))
            hat_mask = mask.crop(protected)
            # Compare every opaque source-pixel sample in the hat rectangle,
            # excluding the removed surrounding background. Both are RGB bytes.
            actual = bytes(v for px, alpha in zip(final.crop(target_bounds).getdata(), hat_mask.getdata()) if alpha == 255 for v in px)
            expected = bytes(v for px, alpha in zip(crop.convert("RGB").crop(protected).getdata(), hat_mask.getdata()) if alpha == 255 for v in px)
            assert actual == expected, (style, layout, "Selected hat pixels changed")
            final.save(OUT / f"hopan-{suffix}.png")
            edit_directory = selected / suffix
            edit_directory.mkdir(exist_ok=True)
            stack = ET.Element("image", {"w": str(size[0]), "h": str(size[1]), "name": "Exact selected #" + str(NUMBERS[style]) + " " + layout})
            group = ET.SubElement(stack, "stack")
            with zipfile.ZipFile(ART / f"hopan-{suffix}.ora", "w") as archive:
                archive.writestr("mimetype", "image/openraster", compress_type=zipfile.ZIP_STORED)
                for index, (name, image) in enumerate(reversed(layers)):
                    src = f"data/layer{index}.png"
                    ET.SubElement(group, "layer", {"name": name, "src": src, "opacity": "1.0", "visibility": "visible", "composite-op": "svg:src-over", "x": "0", "y": "0"})
                    archive.writestr(src, png_bytes(image))
                    image.save(edit_directory / (name + ".png"))
                archive.writestr("stack.xml", ET.tostring(stack))
                archive.writestr("mergedimage.png", png_bytes(canvas))
            evidence["exports"].append({"selection": NUMBERS[style], "layout": layout,
                "source_panel_bounds": bounds, "source_hat_bounds_in_panel": protected,
                "destination_hat_bounds": target_bounds, "source_offset": offset,
                "hat_rgb_sha256": hashlib.sha256(expected).hexdigest(),
                "exported_hat_rgb_sha256": hashlib.sha256(actual).hexdigest(),
                "opaque_hat_sample_pixels": len(expected) // 3,
                "hat_pixels_identical": True})
    (selected / "source-pixel-proof.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print("Six layouts composed from actual #6/#4 pixels; every protected hat matches source exactly.")


if __name__ == "__main__":
    main()
