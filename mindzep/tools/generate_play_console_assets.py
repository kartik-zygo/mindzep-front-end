from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parents[1] / "play_console_assets"

PALETTE = {
    "deep_navy": (12, 28, 52),
    "teal": (18, 152, 170),
    "mint": (112, 214, 170),
    "sun": (243, 177, 76),
    "coral": (238, 92, 101),
    "cream": (248, 244, 235),
    "white": (255, 255, 255),
    "slate": (88, 100, 125),
}


def ensure_dirs() -> None:
    for folder in [
        BASE_DIR / "feature_graphic",
        BASE_DIR / "phone",
        BASE_DIR / "tablet_7inch",
        BASE_DIR / "tablet_10inch",
    ]:
        folder.mkdir(parents=True, exist_ok=True)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gradient_bg(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    img = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(1, height - 1)
        color = (
            lerp(top[0], bottom[0], t),
            lerp(top[1], bottom[1], t),
            lerp(top[2], bottom[2], t),
        )
        draw.line([(0, y), (width, y)], fill=color)
    return img


def try_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    font_names = [
        "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf",
        "arialbd.ttf" if bold else "arial.ttf",
    ]
    for name in font_names:
        try:
            return ImageFont.truetype(name, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def add_blobs(canvas: Image.Image, seed_shift: int = 0) -> None:
    width, height = canvas.size
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    shapes = [
        (-0.2, -0.3, 0.6, 0.5, (255, 255, 255, 34)),
        (0.5, -0.1, 1.2, 0.6, (255, 255, 255, 28)),
        (-0.3, 0.5, 0.5, 1.3, (255, 255, 255, 22)),
        (0.6, 0.55, 1.3, 1.4, (255, 255, 255, 20)),
    ]

    for i, (x1, y1, x2, y2, color) in enumerate(shapes):
        offset = (seed_shift + i * 17) % 60
        d.ellipse(
            [
                int((x1 * width) + offset),
                int((y1 * height) - offset),
                int((x2 * width) + offset),
                int((y2 * height) + offset),
            ],
            fill=color,
        )

    canvas.paste(overlay, (0, 0), overlay)


def rounded_panel(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def write_multiline(draw: ImageDraw.ImageDraw, text: str, box: tuple[int, int, int, int], font, fill, spacing: int = 8) -> None:
    x1, y1, x2, y2 = box
    max_width = x2 - x1
    words = text.split()
    lines: list[str] = []
    current = ""

    for word in words:
        trial = word if not current else f"{current} {word}"
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    y = y1
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        line_h = bbox[3] - bbox[1]
        if y + line_h > y2:
            break
        draw.text((x1, y), line, font=font, fill=fill)
        y += line_h + spacing


def _wrap_lines(draw: ImageDraw.ImageDraw, text: str, font, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""

    for word in words:
        trial = word if not current else f"{current} {word}"
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word

    if current:
        lines.append(current)

    return lines


def draw_wrapped_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    x: int,
    y: int,
    max_width: int,
    font,
    fill,
    line_spacing: int = 6,
    max_lines: int | None = None,
) -> int:
    lines = _wrap_lines(draw, text, font, max_width)
    if max_lines is not None:
        lines = lines[:max_lines]

    current_y = y
    for line in lines:
        draw.text((x, current_y), line, font=font, fill=fill)
        bbox = draw.textbbox((0, 0), line, font=font)
        current_y += (bbox[3] - bbox[1]) + line_spacing

    return current_y


def draw_feature_graphic(path: Path) -> None:
    img = gradient_bg((1024, 500), PALETTE["deep_navy"], (17, 59, 95))
    add_blobs(img, seed_shift=5)
    d = ImageDraw.Draw(img)

    title_font = try_font(58, bold=True)
    body_font = try_font(27, bold=False)
    chip_font = try_font(22, bold=True)

    d.text((72, 78), "MindZep", font=title_font, fill=PALETTE["white"])
    write_multiline(
        d,
        "Talk to licensed psychologists. Book fast. Heal at your pace.",
        (72, 160, 560, 330),
        body_font,
        PALETTE["cream"],
        spacing=10,
    )

    rounded_panel(d, (72, 360, 330, 420), radius=28, fill=PALETTE["sun"])
    d.text((98, 377), "First 2 minutes free", font=chip_font, fill=PALETTE["deep_navy"])

    phone_x, phone_y = 650, 52
    rounded_panel(d, (phone_x, phone_y, phone_x + 260, phone_y + 396), radius=42, fill=(11, 19, 34), outline=(255, 255, 255), width=3)
    rounded_panel(d, (phone_x + 18, phone_y + 20, phone_x + 242, phone_y + 376), radius=30, fill=(245, 248, 252))

    rounded_panel(d, (phone_x + 34, phone_y + 44, phone_x + 226, phone_y + 132), radius=20, fill=(225, 241, 255))
    d.text((phone_x + 48, phone_y + 74), "Find your therapist", font=try_font(20, True), fill=PALETTE["deep_navy"])

    card_y = phone_y + 152
    for i, name in enumerate(["Dr Anaya", "Dr Rohan", "Dr Neha"]):
        y = card_y + i * 72
        rounded_panel(d, (phone_x + 34, y, phone_x + 226, y + 58), radius=16, fill=PALETTE["white"], outline=(216, 227, 238))
        d.ellipse((phone_x + 44, y + 14, phone_x + 66, y + 36), fill=(120, 170, 220))
        d.text((phone_x + 74, y + 17), name, font=try_font(16, True), fill=(31, 56, 84))

    rounded_panel(d, (phone_x + 34, phone_y + 340, phone_x + 226, phone_y + 368), radius=14, fill=(31, 170, 150))
    d.text((phone_x + 94, phone_y + 347), "Book Now", font=try_font(14, True), fill=PALETTE["white"])

    img.save(path, format="PNG", optimize=True)


def draw_screenshot(path: Path, size: tuple[int, int], heading: str, subheading: str, highlight: str, variant: int) -> None:
    img = gradient_bg(size, (19, 39, 72), (20, 88, 128))
    add_blobs(img, seed_shift=variant * 9)
    d = ImageDraw.Draw(img)
    w, h = size

    margin = int(w * 0.06)
    panel_x1, panel_y1 = margin, int(h * 0.06)
    panel_x2, panel_y2 = w - margin, h - int(h * 0.05)

    rounded_panel(d, (panel_x1, panel_y1, panel_x2, panel_y2), radius=int(min(w, h) * 0.03), fill=(248, 251, 255), outline=(214, 226, 238), width=2)

    min_side = min(w, h)
    title_font = try_font(max(28, int(min_side * 0.045)), bold=True)
    sub_font = try_font(max(20, int(min_side * 0.028)), bold=False)
    card_title_font = try_font(max(16, int(min_side * 0.022)), bold=True)
    body_font = try_font(max(14, int(min_side * 0.017)), bold=False)

    text_x = panel_x1 + 34
    text_w = panel_x2 - panel_x1 - 68
    title_bottom = draw_wrapped_text(
        d,
        heading,
        text_x,
        panel_y1 + 28,
        text_w,
        title_font,
        PALETTE["deep_navy"],
        line_spacing=8,
        max_lines=2,
    )
    sub_bottom = draw_wrapped_text(
        d,
        subheading,
        text_x,
        title_bottom + 4,
        text_w,
        sub_font,
        PALETTE["slate"],
        line_spacing=6,
        max_lines=2,
    )

    hero_top = sub_bottom + 18
    hero_h = int((panel_y2 - panel_y1) * 0.22)
    rounded_panel(
        d,
        (panel_x1 + 30, hero_top, panel_x2 - 30, hero_top + hero_h),
        radius=28,
        fill=(223, 241, 252),
    )

    d.text((panel_x1 + 54, hero_top + 32), highlight, font=card_title_font, fill=(20, 65, 97))
    rounded_panel(
        d,
        (panel_x2 - 280, hero_top + 24, panel_x2 - 64, hero_top + 76),
        radius=22,
        fill=PALETTE["sun"],
    )
    d.text((panel_x2 - 248, hero_top + 40), "2 min free", font=try_font(max(20, int(min_side * 0.017)), bold=True), fill=(41, 50, 66))

    start_y = hero_top + hero_h + 24
    card_h = int((panel_y2 - start_y - 44) / 3)

    items = [
        ("Discover therapists", "Verified professionals with ratings"),
        ("Book your slot", "Simple schedule with quick confirmation"),
        ("Talk securely", "Video or audio sessions from anywhere"),
    ]

    if variant % 2 == 0:
        items = [
            ("Today\'s progress", "Track upcoming and past sessions"),
            ("Calm experience", "Clean layout built for comfort"),
            ("Private support", "Safe and secure conversations"),
        ]

    for i, (title, desc) in enumerate(items):
        y1 = start_y + i * (card_h + 14)
        y2 = y1 + card_h
        rounded_panel(d, (panel_x1 + 30, y1, panel_x2 - 30, y2), radius=20, fill=PALETTE["white"], outline=(220, 230, 240))
        d.ellipse((panel_x1 + 52, y1 + 20, panel_x1 + 86, y1 + 54), fill=(112, 176, 219))
        d.text((panel_x1 + 100, y1 + 18), title, font=card_title_font, fill=(26, 57, 91))
        write_multiline(d, desc, (panel_x1 + 100, y1 + 56, panel_x2 - 54, y2 - 12), body_font, (88, 102, 121), spacing=4)

    img.save(path, format="PNG", optimize=True)


def kb(size_bytes: int) -> float:
    return size_bytes / 1024.0


def validate(paths: Iterable[Path]) -> None:
    print("Generated assets:")
    for p in paths:
        with Image.open(p) as im:
            w, h = im.size
        size_kb = kb(p.stat().st_size)
        print(f"- {p.relative_to(BASE_DIR)} | {w}x{h} | {size_kb:.1f} KB")


def main() -> None:
    ensure_dirs()

    output_paths: list[Path] = []

    feature = BASE_DIR / "feature_graphic" / "mindzep_feature_graphic_1024x500.png"
    draw_feature_graphic(feature)
    output_paths.append(feature)

    phone_specs = [
        (BASE_DIR / "phone" / "phone_01_1080x1920.png", (1080, 1920), "Find the right psychologist", "Explore trusted profiles by specialization, ratings, language, and experience.", "Support made simple", 1),
        (BASE_DIR / "phone" / "phone_02_1080x1920.png", (1080, 1920), "Book and connect instantly", "Choose your slot, pay securely, and start a calm conversation from your phone.", "Care on your schedule", 2),
    ]

    tab7_specs = [
        (BASE_DIR / "tablet_7inch" / "tablet7_01_1920x1080.png", (1920, 1080), "MindZep on tablet", "View appointments, therapist insights, and wellness progress in one clean workspace.", "Bigger view, better focus", 3),
        (BASE_DIR / "tablet_7inch" / "tablet7_02_1920x1080.png", (1920, 1080), "Smooth booking experience", "Compare experts and reserve sessions faster with an optimized large-screen flow.", "Plan sessions with ease", 4),
    ]

    tab10_specs = [
        (BASE_DIR / "tablet_10inch" / "tablet10_01_2560x1440.png", (2560, 1440), "Comfort-first counseling app", "Immersive layouts make it easier to browse experts and manage your care routine.", "Designed for clarity", 5),
        (BASE_DIR / "tablet_10inch" / "tablet10_02_2560x1440.png", (2560, 1440), "Private sessions, anywhere", "Join secure audio or video conversations and continue your healing journey confidently.", "Trusted support, every day", 6),
    ]

    for spec in phone_specs + tab7_specs + tab10_specs:
        path, size, heading, subheading, highlight, variant = spec
        draw_screenshot(path, size, heading, subheading, highlight, variant)
        output_paths.append(path)

    validate(output_paths)
    print(f"\nAll assets saved under: {BASE_DIR}")


if __name__ == "__main__":
    main()
