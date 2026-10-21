#!/usr/bin/env python3
"""Code-authored indexed-scale splash illustration.

The wrapped/layered hat shapes adapt the user-selected generated preview concepts
#6 and #4; flattened concept art is not used as a game texture.

Edit the palette, polygons and positions below; Pillow is only the drawing/export
tool. Each named pass is also exported as a transparent editable PNG layer.
Artwork is composed at 384x216 / 216x384 and enlarged with nearest-neighbor.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random
import io
import zipfile
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/art/splash"
LAYERS = ROOT / "art-source/splash/layers"
PAL = dict(ink="#102c32", night="#143b43", teal="#205b60", haze="#548581",
           pale="#e1d6a0", gold="#dba955", glint="#f8d98a", stone="#806b50",
           shadow="#455745", green="#72a750", leaf="#376b4e", light="#aed16c")


def paint(portrait=False, compact=False, hat="wrapped"):
    w, h = (216, 384) if portrait else (384, 216)
    canvas = Image.new("RGBA", (w, h))
    passes = []
    rng = random.Random(1729)

    def layer(name, draw):
        im = Image.new("RGBA", (w, h))
        draw(ImageDraw.Draw(im))
        canvas.alpha_composite(im)
        passes.append((name, im))

    def sky(d):
        colors = ["#102b35", "#123540", "#194953", "#285d64", "#497777", "#7d9990"]
        for y in range(h):
            d.line((0, y, w, y), fill=colors[min(5, y * 6 // (175 if portrait else 150))])
        for _ in range(65):
            x, y = rng.randrange(w), rng.randrange(90)
            d.point((x, y), fill="#6e9693")
        mx, my = (169, 34) if portrait else (191, 32)
        d.ellipse((mx-19, my-19, mx+19, my+19), fill="#4b7276")
        d.ellipse((mx-14, my-14, mx+14, my+14), fill=PAL["pale"])
        d.ellipse((mx-5, my-16, mx+17, my+7), fill="#16404b")
        for y, x, length in [(45, 3, 65), (63, 126, 47), (20, 232, 75), (76, 217, 112)]:
            d.rectangle((x, y, x+length, y+1), fill="#35616a")
            d.rectangle((x+8, y+2, x+length-14, y+2), fill="#2b565f")
    layer("01-sky-moon", sky)

    horizon = 125 if portrait else 119

    def ruins(d):
        # Fictional Egyptian-inspired sandstone sanctuary; no invented script.
        d.polygon([(0,horizon),(0,91),(19,86),(33,61),(57,91),(83,91),(98,75),(125,105),(w,111),(w,horizon)], fill="#396768")
        d.polygon([(5,109),(45,54),(84,109)], fill="#697e71")
        d.polygon([(45,54),(84,109),(57,109)], fill="#4e6965")
        for y in range(75,109,7):
            x = 45-(y-54)*40//55
            d.line((x,y,45+(y-54)*39//55,y), fill="#7c8c79")
        # Broken pylon gate and fluted, uninscribed columns.
        for x in [14,70]:
            d.polygon([(x,114),(x+4,80),(x+19,80),(x+23,114)], fill="#998b6b")
            d.rectangle((x+4,80,x+18,83), fill="#b5a17b")
            d.line((x+7,85,x+4,111), fill="#baaa7c")
            d.line((x+18,85,x+20,111), fill="#657265")
        d.rectangle((29,87,73,92), fill="#b0a080")
        d.rectangle((29,92,73,95), fill="#66786b")
        for x in [107,122]:
            d.rectangle((x,101,x+6,119), fill="#6c8576")
            d.rectangle((x-2,99,x+8,102), fill="#a2a083")
        d.rectangle((0,116,w,125), fill="#2d6160")
    layer("02-distant-sanctuary", ruins)

    def water(d):
        d.rectangle((0,horizon,w,h), fill="#174a51")
        for i in range(130):
            y=rng.randrange(horizon,h)
            x=rng.randrange(w)
            color=rng.choice(["#24616a", "#37767a", "#1c555e", "#4a8585"])
            d.rectangle((x,y,x+rng.randrange(3,17),y+1),fill=color)
        mx=169 if portrait else 191
        for i in range(16):
            y=horizon+3+i*3
            d.line((mx-3-i//2,y,mx+6+i//2,y),fill="#91a993" if i%3 else "#b7b890")
        for x,y in [(25,146),(164,152),(66,180),(190,167),(14,202)]:
            d.ellipse((x,y,x+17,y+5),fill="#366951")
            d.line((x+9,y+1,x+16,y+2),fill="#699160")
            d.polygon([(x+8,y+1),(x+11,y+3),(x+17,y+3)],fill="#174a51")
    layer("03-water-lily-pads", water)

    base_y = 166 if portrait else 193
    fx = 99 if portrait else (62 if compact else 109)
    fy = base_y-31

    def foreground(d):
        # Stepping stones lead away into the adventure, without mimicking a map.
        for x,y,s in [(168,130,8),(154,142,12),(166,160,15)]:
            d.polygon([(x-s,y),(x+s,y-3),(x+s+5,y+3),(x-s+2,y+7)],fill="#7e8973")
            d.line((x-s,y,x+s,y-3,x+s+5,y+3),fill="#b9b38a",width=2)
        d.polygon([(18,base_y+6),(48,base_y-8),(139,base_y-10),(168,base_y+2),(156,base_y+23),(40,base_y+26)],fill="#203f3e")
        d.polygon([(18,base_y),(48,base_y-15),(139,base_y-17),(168,base_y-5),(151,base_y+10),(39,base_y+14)],fill="#7b8062")
        d.line((18,base_y,48,base_y-15,139,base_y-17,168,base_y-5),fill="#d4bd81",width=2)
        d.polygon([(39,base_y+14),(151,base_y+10),(148,base_y+16),(43,base_y+20)],fill="#576b53")
        for _ in range(90):
            x=rng.randrange(40,147);y=rng.randrange(base_y-10,base_y+8)
            d.line((x,y,x+3,y),fill=rng.choice(["#8b9569","#566c4b","#a3a876"]))
        d.line((76,base_y+9,81,base_y+2,72,base_y-3),fill="#485d4d")
        # Reeds and palm silhouettes frame the illustration on the left.
        d.polygon([(0,h),(0,136),(15,157),(27,171),(31,h)],fill="#102f35")
        for x,y,s in [(6,142,37),(31,177,30),(181,189,22)]:
            d.line((x,y+25,x+3,y-s),fill="#2d624e",width=2)
            d.polygon([(x+3,y-s),(x-8,y-18),(x-13,y-7),(x+1,y-23)],fill="#467951")
            d.polygon([(x+3,y-s),(x+17,y-20),(x+19,y-12),(x+7,y-23)],fill="#5f8957")
        d.polygon([(0,0),(10,0),(12,45),(22,76),(16,79),(8,48)],fill="#173f3f")
        for poly in [[(11,25),(29,14),(49,20),(27,20)],[(12,30),(30,33),(39,47),(24,37)],[(10,22),(0,9),(0,32)]]:
            d.polygon(poly,fill="#285849")
    layer("04-stones-reeds", foreground)

    def hat_cloth(d):
        # Cloth sits BEHIND the eye lobes, not painted across their surface.
        # Closed stripe polygons stay inside each drape's silhouette.
        x, y = fx, fy
        for side in [-1, 1]:
            def points(coords):
                return [(x + side * xx, y + yy) for xx, yy in coords]
            if hat == "layered":
                outline = [(30,-42),(38,-41),(45,-9),(42,-7),(36,-13),(29,-34)]
                cloth = [(31,-41),(37,-40),(43,-11),(39,-12),(30,-34)]
                bands = [[(32,-34),(38,-33),(39,-28),(33,-29)],
                         [(34,-23),(40,-22),(41,-17),(35,-18)]]
            else:
                outline = [(29,-42),(38,-41),(43,-11),(40,-8),(34,-10),(28,-34)]
                cloth = [(30,-41),(37,-40),(41,-12),(39,-10),(35,-11),(29,-34)]
                bands = [[(31,-34),(38,-33),(39,-28),(32,-29)],
                         [(33,-23),(40,-22),(40,-17),(34,-18)]]
            d.polygon(points(outline), fill="#7b6339")
            d.polygon(points(cloth), fill="#dfb95f")
            for band in bands:
                d.polygon(points(band), fill="#245c65")
            d.line(points([(37,-39),(40,-25),(41,-12)]), fill="#f4d37e")
            if hat == "layered":
                d.polygon(points([(39,-13),(42,-10),(43,-11),(40,-17)]), fill="#ffe29a")
                d.line(points([(42,-7),(38,-8),(35,-11)]), fill="#245c65")
    layer("05-hat-cloth-behind-eyes", hat_cloth)

    def frog(d):
        # Wide squashy head, raised gold eyes, pale belly, three-toed hands.
        # This is an illustrated version of art.gd's existing procedural hero.
        x,y=fx,fy
        d.ellipse((x-42,y+17,x+42,y+37),fill="#3b5440")
        d.ellipse((x-41,y+1,x-10,y+31),fill="#537f45")
        d.ellipse((x+12,y+1,x+42,y+31),fill="#406d43")
        d.ellipse((x-31,y-13,x+31,y+32),fill=PAL["green"])
        d.ellipse((x-23,y+4,x+22,y+30),fill="#b6c87a")
        d.ellipse((x-24,y+5,x+22,y+23),fill="#d2d79b")
        d.ellipse((x-38,y-24,x+37,y+10),fill="#57883f")
        d.ellipse((x-37,y-26,x+35,y+6),fill="#98bf57")
        d.ellipse((x-32,y-25,x+24,y-6),fill="#b7d477")
        d.ellipse((x-27,y-42,x-1,y-12),fill="#77a84b")
        d.ellipse((x+7,y-40,x+31,y-12),fill="#6d9947")
        for ex,ey in [(x-14,y-26),(x+20,y-25)]:
            d.ellipse((ex-8,ey-9,ex+8,ey+8),fill="#e5bb5d")
            d.ellipse((ex-6,ey-7,ex+7,ey+5),fill="#f6d889")
            d.ellipse((ex-1,ey-7,ex+3,ey+6),fill="#193c32")
            d.rectangle((ex-3,ey-6,ex-1,ey-4),fill="#fff3c5")
        d.line((x-21,y-3,x-10,y+1,x+10,y+2,x+26,y-4),fill="#3a6438",width=2)
        d.point((x-6,y-10),fill="#5b7e3f");d.point((x+10,y-10),fill="#5b7e3f")
        for side in [-1,1]:
            hx=x+side*30
            d.polygon([(hx-4,y+7),(hx+4,y+5),(hx+side*5,y+25),(hx-3,y+28)],fill="#7eae4e")
            for j in range(3):
                tx=hx-7+j*5
                d.line((hx,y+22,tx,y+30+(j==1)*2),fill="#c0c46b",width=3)
                d.rectangle((tx-1,y+29+(j==1)*2,tx+2,y+31+(j==1)*2),fill="#d5cf80")
        for px,py in [(-31,-9),(-29,-6),(28,-8),(-23,18),(25,19)]:
            d.rectangle((x+px,y+py,x+px+2,y+py+1),fill="#638f40")
    layer("06-frog-hero", frog)

    def crown(d):
        x, y = fx, fy
        def points(coords):
            return [(x+xx,y+yy) for xx,yy in coords]
        if hat == "layered":
            shape = [(-34,-43),(-31,-49),(-20,-55),(13,-54),(28,-49),(34,-43)]
            top = [(-28,-48),(-19,-53),(12,-52),(25,-48),(27,-45),(-28,-45)]
        else:
            # #6: a continuous domed crown, with a lit left plane and shaded rim.
            shape = [(-35,-43),(-32,-50),(-25,-56),(-15,-59),(11,-59),
                     (23,-55),(30,-49),(34,-43)]
            top = [(-29,-48),(-24,-54),(-14,-57),(10,-57),(21,-53),(27,-48)]
        d.polygon(points(shape), fill="#b68a40")
        d.polygon(points(top), fill="#e8be62")
        d.polygon(points([(-30,-49),(-24,-55),(-15,-57),(-10,-57),(-18,-52),(-21,-47)]), fill="#f7d985")
        if hat == "wrapped":
            d.line(points([(9,-57),(14,-53),(16,-47)]), fill="#cd9f4e")
            d.line(points([(-16,-56),(-20,-51),(-21,-47)]), fill="#ffe59b")
        # One fitted band. Its underside stops above the eye highlights.
        d.polygon(points([(-34,-44),(-30,-47),(28,-47),(33,-43),(31,-39),(-31,-39)]), fill="#896635")
        d.polygon(points([(-33,-44),(-29,-46),(27,-46),(32,-43),(30,-41),(-30,-41)]), fill="#dfb55c")
        d.line(points([(-28,-45),(0,-45),(25,-44)]), fill="#ffe29a")
        d.line(points([(-28,-39),(27,-39)]), fill="#344c36")
        # Small upright ornament is attached to the crown, with one inset.
        d.polygon(points([(-4,-49),(-5,-64),(-3,-68),(3,-68),(5,-64),(3,-49)]), fill="#bc9347")
        d.polygon(points([(-3,-50),(-4,-63),(-2,-66),(2,-66),(3,-63),(2,-50)]), fill="#f3d079")
        d.rectangle((x-1,y-62,x+1,y-59), fill="#285f63")
        d.line((x-2,y-65,x+1,y-65), fill="#ffe8a5")
    layer("07-fitted-" + hat + "-crown", crown)

    def frame(d):
        # Calm dark menu field is deliberately authored, rather than baked UI.
        if not portrait:
            for x in range(207,w):
                alpha=min(225,(x-207)*4)
                d.line((x,0,x,h),fill=(9,30,34,alpha))
        else:
            for y in range(189,h):
                d.line((0,y,w,y),fill=(9,30,34,min(220,(y-189)*5)))
        for x,y in [(47,113),(151,109),(31,154),(171,87),(14,121)]:
            d.rectangle((x,y,x+1,y+1),fill="#d5c77b")
            d.point((x-2,y),fill="#7b9a78")
        d.rectangle((0,h-2,w,h),fill="#102d33")
    layer("08-menu-quiet-field", frame)
    variant="portrait" if portrait else ("compact" if compact else "wide")
    if hat == "layered":
        variant = "layered-" + variant
    OUT.mkdir(parents=True,exist_ok=True)
    (LAYERS/variant).mkdir(parents=True,exist_ok=True)
    canvas.convert("RGB").resize((w*4,h*4),Image.Resampling.NEAREST).save(OUT/f"hopan-{variant}.png")
    stack = ET.Element("image", {"w":str(w), "h":str(h), "name":"Hopán " + variant})
    group = ET.SubElement(stack,"stack")
    with zipfile.ZipFile(LAYERS.parent/f"hopan-{variant}.ora","w") as archive:
        archive.writestr("mimetype","image/openraster",compress_type=zipfile.ZIP_STORED)
        for index,(name,im) in enumerate(reversed(passes)):
            src=f"data/layer{index}.png"
            ET.SubElement(group,"layer",{"name":name,"src":src,"opacity":"1.0","visibility":"visible","composite-op":"svg:src-over","x":"0","y":"0"})
            buf=io.BytesIO();im.save(buf,format="PNG")
            archive.writestr(src,buf.getvalue())
        archive.writestr("stack.xml",ET.tostring(stack))
        buf=io.BytesIO();canvas.save(buf,format="PNG")
        archive.writestr("mergedimage.png",buf.getvalue())
    for name,im in passes:
        im.save(LAYERS/variant/f"{name}.png")


if __name__ == "__main__":
    for hat in ["wrapped", "layered"]:
        paint(hat=hat)
        paint(True, hat=hat)
        paint(compact=True, hat=hat)
    print("Drew #6 Wrapped Gold and #4 Layered Cloth in all three layouts, with editable layers.")
