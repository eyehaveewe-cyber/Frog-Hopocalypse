"""Draw an original sharp, dripping display alphabet as an editable TTF.

Hand-authored 5x7 glyphs; no downloaded font or raster generation. Use only for
short rule headings. Body text keeps the normal game font for readability.
Requires fontTools (4.61.1 used). Glyph geometry is deterministic.
"""
from pathlib import Path
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROWS = {
'A':'01110/11011/11011/11111/11011/11011/11011',
'B':'11110/11011/11011/11110/11011/11011/11110',
'C':'01111/11000/11000/11000/11000/11000/01111',
'D':'11110/11011/11011/11011/11011/11011/11110',
'E':'11111/11000/11000/11110/11000/11000/11111',
'F':'11111/11000/11000/11110/11000/11000/11000',
'G':'01111/11000/11000/11011/11011/11011/01110',
'H':'11011/11011/11011/11111/11011/11011/11011',
'I':'11111/00100/00100/00100/00100/00100/11111',
'J':'00111/00011/00011/00011/11011/11011/01110',
'K':'11011/11010/11100/11100/11110/11011/11011',
'L':'11000/11000/11000/11000/11000/11000/11111',
'M':'11011/11111/11111/11011/11011/11011/11011',
'N':'11011/11111/11111/11111/11011/11011/11011',
'O':'01110/11011/11011/11011/11011/11011/01110',
'P':'11110/11011/11011/11110/11000/11000/11000',
'Q':'01110/11011/11011/11011/11111/01110/00011',
'R':'11110/11011/11011/11110/11100/11011/11011',
'S':'01111/11000/11000/01110/00011/00011/11110',
'T':'11111/00100/00100/00100/00100/00100/00100',
'U':'11011/11011/11011/11011/11011/11011/01110',
'V':'11011/11011/11011/11011/11011/01110/00100',
'W':'11011/11011/11011/11011/11111/11111/01010',
'X':'11011/11011/01110/00100/01110/11011/11011',
'Y':'11011/11011/01110/00100/00100/00100/00100',
'Z':'11111/00011/00110/01100/11000/11000/11111',
'0':'01110/11011/11111/11111/11011/11011/01110',
'1':'00100/01100/00100/00100/00100/00100/01110',
'2':'01110/11011/00011/00110/01100/11000/11111',
'3':'11110/00011/00011/01110/00011/00011/11110',
'4':'11011/11011/11011/11111/00011/00011/00011',
'5':'11111/11000/11000/11110/00011/00011/11110',
'6':'01111/11000/11000/11110/11011/11011/01110',
'7':'11111/00011/00110/00100/01100/01100/01100',
'8':'01110/11011/11011/01110/11011/11011/01110',
'9':'01110/11011/11011/01111/00011/00011/11110',
'!':'00100/00100/00100/00100/00100/00000/00100',
}

def polygon(pen, points):
    pen.moveTo(points[0])
    for point in points[1:]: pen.lineTo(point)
    pen.closePath()

def build():
    fb=FontBuilder(1000,isTTF=True)
    names={c:'uni%04X'%ord(c) for c in ROWS}
    order=['.notdef','space']+list(names.values())
    fb.setupGlyphOrder(order)
    glyphs={};metrics={}
    for name in ['.notdef','space']:
        glyphs[name]=TTGlyphPen(None).glyph();metrics[name]=(340,0)
    for char,grid in ROWS.items():
        pen=TTGlyphPen(None);rows=grid.split('/')
        for y,row in enumerate(rows):
            for x,on in enumerate(row):
                if on!='1':continue
                left=30+x*102;bottom=115+(6-y)*105
                lean=(ord(char)+x*7+y*3)%13-6
                polygon(pen,[(left,bottom),(left+99,bottom+3),(left+105+lean,bottom+107),(left+lean,bottom+100)])
                if y==6 and (ord(char)+x)%3==0:
                    polygon(pen,[(left+8,bottom+4),(left+63,bottom+4),(left+34,-35-(ord(char)%4)*20)])
        name=names[char];glyphs[name]=pen.glyph();metrics[name]=(610,20)
    fb.setupCharacterMap({32:'space',**{ord(k):v for k,v in names.items()}})
    fb.setupGlyf(glyphs);fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=900,descent=-150)
    fb.setupNameTable({'familyName':'Hopan Rule Ink','styleName':'Regular','uniqueFontIdentifier':'HopanRuleInk-v1','fullName':'Hopan Rule Ink','psName':'HopanRuleInk-Regular','version':'Version 1.0'})
    fb.setupOS2(sTypoAscender=900,sTypoDescender=-150,usWinAscent=950,usWinDescent=150)
    fb.setupPost();fb.setupMaxp()
    out=Path(__file__).resolve().parents[1]/'game/art/rules/hopan-rule-ink.ttf'
    out.parent.mkdir(parents=True,exist_ok=True);fb.save(out)
    print(out)

if __name__=='__main__': build()
