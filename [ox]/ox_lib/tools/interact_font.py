"""
Adds the missing Chinese to ox_lib's interaction alphabet.

The [E] prompt in the world is not drawn with the game's fonts. It is
drawn from a picture of the alphabet, one character at a time, and a
character that is not in that picture comes out as a question mark.

The picture was built from GB2312, which is **simplified Chinese only**.
So a server running traditional Chinese loses about half its everyday
characters -- a customer reported 解鎖 coming out as 解?, because 鎖 is
traditional and only the simplified 锁 was ever drawn.

The first page is also full: it ran out of room part way through
GB2312's rarer half, so 2,512 simplified characters never made it in
either.

This adds a second page with everything missing from everyday Chinese
in both scripts, and writes it beside the first. The first page is
never touched -- not re-rendered, not repacked, not even reopened for
writing -- so nothing already on screen can move by a pixel.

    python tools/interact_font.py <path to ox_lib>

What it is deliberately not doing:

  * Big5 level 2, the rare traditional characters. 7,380 more glyphs
    for names and classical text that no interaction label uses, and
    every glyph costs video memory on every player's machine.
  * touching the Latin letters, which are Barlow and must stay exact.
"""
import io
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

OX = sys.argv[1] if len(sys.argv) > 1 else '.'
SRC = os.path.join(OX, 'assets/interact')

PAGE_WIDTH = 4096
SLANT = 6.48                              # measured off the stems of I, l, H, E
CJK_FONT = 'C:/Windows/Fonts/msyhbd.ttc'  # YaHei Bold, against Barlow SemiBold Italic
PAD = 2

#: What the second page is called, both as a file and as a texture.
SECOND = 'font2'

old = json.load(io.open(os.path.join(SRC, 'font.json'), encoding='utf-8'))
LINE, ASCENT, CAP = old['lineHeight'], old['ascent'], old['capHeight']
have = set(old['glyphs'])


# ── which characters ─────────────────────────────────────────────────
def charset(encoding, lo, hi):
    """Every character in a run of lead bytes of an encoding."""
    out = []
    for lead in range(lo, hi + 1):
        for trail in range(0x40, 0x100):
            try:
                char = bytes([lead, trail]).decode(encoding)
            except UnicodeDecodeError:
                continue
            if len(char) == 1:
                out.append(char)
    return out


#: Everyday traditional Chinese comes first: that is the reported fault,
#: and if anything ever has to be dropped it should not be that.
traditional = charset('big5', 0xA4, 0xC6)
simplified = charset('gb2312', 0xD8, 0xF7)
symbols = charset('gb2312', 0xA1, 0xA3)

wanted = [c for c in (traditional + simplified + symbols) if c not in have]
wanted = list(dict.fromkeys(wanted))
print(f'missing: {len(wanted)} characters of everyday Chinese')

if not wanted:
    print('nothing to add; the alphabet already has all of it')
    raise SystemExit(0)


# ── size it against the Latin cap height ─────────────────────────────
def ideograph(size):
    box = ImageFont.truetype(CJK_FONT, size).getbbox('国')
    return box[3] - box[1]


size = 52
while ideograph(size) > CAP:
    size -= 1
while ideograph(size + 1) <= CAP:
    size += 1
font = ImageFont.truetype(CJK_FONT, size)
print(f'cjk size {size}px -> ideograph {ideograph(size)}px, against cap height {CAP}px')


# ── render one character, leaned over, cropped tight ─────────────────
PEN, BASE = 60, 120
shear = math.tan(math.radians(SLANT))


def render(char):
    img = Image.new('L', (220, 200), 0)
    ImageDraw.Draw(img).text((PEN, BASE), char, font=font, fill=255, anchor='ls')
    # Each row slides by its distance above the baseline, so the baseline
    # itself stays put -- which is what a real italic does.
    img = img.transform(img.size, Image.AFFINE,
                        (1, shear, -shear * BASE, 0, 1, 0), resample=Image.BICUBIC)
    box = img.getbbox()
    if not box:
        return None
    return img.crop(box), box[0] - PEN, box[1], round(font.getlength(char), 2)


drawn = []
for char in wanted:
    made = render(char)
    if made:
        drawn.append((char,) + made)

missed = len(wanted) - len(drawn)
if missed:
    print(f'{missed} had nothing to draw and were skipped')

cellW = max(d[1].width for d in drawn) + PAD
cellH = max(d[1].height for d in drawn) + PAD
cols = PAGE_WIDTH // cellW
rows = math.ceil(len(drawn) / cols)

#[[
#    Rounded up to a power of two, and not to the rows actually used.
#
#    The first page is 4096 square, and a graphics card is entitled to
#    refuse anything else. A page the game will not load is worse than a
#    page with empty rows in it -- it is every Chinese character missing
#    rather than the rare ones -- and that cannot be tried out from
#    outside the game. So the safe size is the one that ships.
#]]
needed = rows * cellH
pageHeight = 1 << (needed - 1).bit_length()
print(f'cell {cellW}x{cellH} -> {cols} across, {rows} down, {needed}px of rows')
print(f'page {PAGE_WIDTH}x{pageHeight} (rounded up to a power of two)')

sheet = Image.new('LA', (PAGE_WIDTH, pageHeight), (255, 0))
glyphs = dict(old['glyphs'])   # copied, never recomputed

for index, (char, crop, xoff, top, adv) in enumerate(drawn):
    x = (index % cols) * cellW
    y = (index // cols) * cellH
    sheet.paste(Image.merge('LA', (Image.new('L', crop.size, 255), crop)), (x, y))
    glyphs[char] = {
        'x': x, 'y': y, 'w': crop.width, 'xoff': xoff, 'adv': adv,
        # This cell is shorter than a Latin one and sits lower down the
        # line. A normal line puts the baseline ASCENT below its top; in
        # this crop the baseline is (BASE - top) below the top, so the
        # cell has to start that much further down.
        'h': crop.height, 'yoff': ASCENT - (BASE - top),
        # Which picture to read it out of. Anything without this is on
        # the first one, so every glyph already there stays as it was.
        'page': SECOND,
    }

out = dict(old, glyphs=glyphs)
#: How big each picture is, so the reader can work out where in it a
#: glyph sits. The first one keeps width/height as well, untouched.
out['pages'] = {
    'font': {'width': old['width'], 'height': old['height']},
    SECOND: {'width': PAGE_WIDTH, 'height': pageHeight},
}

sheet.save(os.path.join(SRC, f'{SECOND}.png'), optimize=True)
io.open(os.path.join(SRC, 'font.json'), 'w', encoding='utf-8').write(
    json.dumps(out, ensure_ascii=False, separators=(',', ':')))

print(f'added {len(drawn)}, now {len(glyphs)} characters in all')
print(f'{SECOND}.png {os.path.getsize(os.path.join(SRC, SECOND + ".png")) // 1024} KB')
print(f'font.json {os.path.getsize(os.path.join(SRC, "font.json")) // 1024} KB')
