#!/usr/bin/env python3
"""مولّد أصول الهوية (المرحلة ٥.٣) — أيقونات Android/iOS وشاشة البداية برمجياً.

مونوغرام «L» هندسي أبيض على لون العلامة (#0F5E59، بذرة سمة التطبيق) مع نقطة
«المحور» الكهرمانية. لا تنزيل أصولٍ خارجية ولا خطوط: أشكالٌ هندسية فقط، فالمخرج
حتميٌّ قابلٌ للإعادة. يُشغَّل من جذر المستودع:

    python3 tool/generate_brand_assets.py        (يتطلب Pillow)

لاستبدال الهوية بتصميم المصمم النهائي: ضع الـPNG في المسارات نفسها (راجع
docs/OWNER_SETUP.md §٧) ولا حاجة لهذا السكربت.
"""
import json
import os

from PIL import Image, ImageDraw

BRAND = (15, 94, 89)        # #0F5E59
BRAND_DARK = (10, 70, 66)   # تدرّجٌ خفيف للعمق
WHITE = (255, 255, 255)
ACCENT = (242, 181, 68)     # #F2B544
SS = 4                      # إفراط العيّنة ثم تصغير LANCZOS لحوافٍ ناعمة

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
IOS = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets')


def draw_mark(d, size, glyph, color=WHITE, accent=ACCENT):
    """المونوغرام داخل مربع طوله glyph متمركزاً في لوحةٍ طولها size."""
    # إحداثيات الوحدة: عمود (0..0.24 × 0..1)، قدم (0..0.78 × 0.76..1)، نقطة (0.72, 0.16)
    bw, bh = 0.84, 1.0
    ox = (size - glyph * bw) / 2
    oy = (size - glyph * bh) / 2

    def px(x, y):
        return ox + x * glyph, oy + y * glyph

    r = glyph * 0.06
    d.rounded_rectangle([*px(0, 0), *px(0.24, 1.0)], radius=r, fill=color)
    d.rounded_rectangle([*px(0, 0.76), *px(0.78, 1.0)], radius=r, fill=color)
    cx, cy = px(0.70, 0.17)
    rr = glyph * 0.13
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=accent)


def gradient(size):
    img = Image.new('RGB', (size, size), BRAND)
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        c = tuple(round(BRAND[i] * (1 - t) + BRAND_DARK[i] * t) for i in range(3))
        for x in range(size):
            px[x, y] = c
    return img


def full_icon(size, round_mask=False):
    big = size * SS
    base = gradient(big).convert('RGBA')
    d = ImageDraw.Draw(base)
    draw_mark(d, big, big * (0.46 if round_mask else 0.50))
    if round_mask:
        mask = Image.new('L', (big, big), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, big - 1, big - 1], fill=255)
        out = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        out.paste(base, (0, 0), mask)
        base = out
    return base.resize((size, size), Image.LANCZOS)


def mark_only(size, glyph_ratio):
    big = size * SS
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(img), big, big * glyph_ratio)
    return img.resize((size, size), Image.LANCZOS)


def save(img, path, opaque=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if opaque:
        img = img.convert('RGB')  # App Store يرفض أيقونةً بقناة ألفا
    img.save(path, optimize=True)
    print('✓', os.path.relpath(path, ROOT), img.size)


def android():
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, f in densities.items():
        d = os.path.join(RES, f'mipmap-{name}')
        save(full_icon(round(48 * f)), os.path.join(d, 'ic_launcher.png'))
        save(full_icon(round(48 * f), True), os.path.join(d, 'ic_launcher_round.png'))
        # الأيقونة التكيّفية: 108dp، والمنطقة الآمنة 66dp ⇒ المونوغرام ≈ 40%.
        save(mark_only(round(108 * f), 0.40), os.path.join(d, 'ic_launcher_foreground.png'))
        # شعار شاشة البداية (Android ≤ 11): 96dp في المنتصف.
        save(mark_only(round(96 * f), 0.80),
             os.path.join(RES, f'drawable-{name}', 'splash_logo.png'))


def ios():
    iconset = os.path.join(IOS, 'AppIcon.appiconset')
    with open(os.path.join(iconset, 'Contents.json')) as fh:
        contents = json.load(fh)
    done = set()
    for img in contents['images']:
        fn = img.get('filename')
        if not fn or fn in done:
            continue
        pt = float(img['size'].split('x')[0])
        scale = int(img['scale'].rstrip('x'))
        save(full_icon(round(pt * scale)), os.path.join(iconset, fn), opaque=True)
        done.add(fn)
    launch = os.path.join(IOS, 'LaunchImage.imageset')
    for suffix, s in (('', 1), ('@2x', 2), ('@3x', 3)):
        save(mark_only(120 * s, 0.80), os.path.join(launch, f'LaunchImage{suffix}.png'))


if __name__ == '__main__':
    android()
    ios()
