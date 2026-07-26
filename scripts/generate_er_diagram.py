#!/usr/bin/env python3
"""Render the portfolio database ER diagram as a high-resolution PNG."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "docs" / "er_diagram.png"

WIDTH, HEIGHT = 2200, 1500
CARD_WIDTH = 500
ROW_HEIGHT = 40
TITLE_HEIGHT = 64

COLORS = {
    "background": "#F8FAFC",
    "card": "#FFFFFF",
    "navy": "#172B4D",
    "blue": "#2563EB",
    "line": "#64748B",
    "text": "#172033",
    "muted": "#64748B",
    "border": "#CBD5E1",
    "pk": "#DBEAFE",
    "pk_text": "#1D4ED8",
    "fk": "#FEF3C7",
    "fk_text": "#92400E",
}


def font(size: int, bold: bool = False):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            try:
                return ImageFont.truetype(candidate, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


TITLE_FONT = font(38, bold=True)
SUBTITLE_FONT = font(22)
CARD_TITLE_FONT = font(25, bold=True)
FIELD_FONT = font(19)
BADGE_FONT = font(15, bold=True)
RELATION_FONT = font(17, bold=True)


TABLES = {
    "hashtags": {
        "position": (70, 180),
        "fields": [
            ("hashtag_id", "INT", "PK"),
            ("hashtag_text", "VARCHAR(50)", ""),
            ("created_date", "DATE", ""),
            ("usage_count", "INT UNSIGNED", ""),
            ("trending_score", "DECIMAL(5,2)", ""),
            ("category", "VARCHAR(50)", ""),
        ],
    },
    "users": {
        "position": (850, 150),
        "fields": [
            ("user_id", "INT", "PK"),
            ("username", "VARCHAR(50)", ""),
            ("email", "VARCHAR(100)", ""),
            ("registration_date", "DATE", ""),
            ("account_type", "ENUM", ""),
            ("follower_count", "INT UNSIGNED", ""),
            ("following_count", "INT UNSIGNED", ""),
        ],
    },
    "sessions": {
        "position": (1630, 180),
        "fields": [
            ("session_id", "INT", "PK"),
            ("start_time", "DATETIME", ""),
            ("end_time", "DATETIME", ""),
            ("device_os", "ENUM", ""),
            ("device_type", "ENUM", ""),
            ("session_duration", "INT UNSIGNED", ""),
            ("user_id", "INT", "FK"),
        ],
    },
    "content_hashtags": {
        "position": (70, 650),
        "fields": [
            ("content_id", "INT", "PK, FK"),
            ("hashtag_id", "INT", "PK, FK"),
        ],
    },
    "content": {
        "position": (850, 600),
        "fields": [
            ("content_id", "INT", "PK"),
            ("content_type", "ENUM", ""),
            ("upload_timestamp", "DATETIME", ""),
            ("duration_seconds", "SMALLINT", ""),
            ("caption", "VARCHAR(255)", ""),
            ("visibility", "ENUM", ""),
            ("user_id", "INT", "FK"),
        ],
    },
    "view_logs": {
        "position": (1630, 650),
        "fields": [
            ("log_id", "INT", "PK"),
            ("content_id", "INT", "FK"),
            ("session_id", "INT", "FK"),
            ("interaction_timestamp", "DATETIME", ""),
            ("interaction_type", "ENUM", ""),
            ("time_spent_seconds", "SMALLINT", ""),
            ("completion_rate", "DECIMAL(5,2)", ""),
        ],
    },
    "likes": {
        "position": (470, 1060),
        "fields": [
            ("like_id", "INT", "PK"),
            ("user_id", "INT", "FK"),
            ("content_id", "INT", "FK"),
            ("like_timestamp", "DATETIME", ""),
            ("reaction_type", "ENUM", ""),
            ("device_source", "ENUM", ""),
        ],
    },
    "comments": {
        "position": (1240, 1060),
        "fields": [
            ("comment_id", "INT", "PK"),
            ("user_id", "INT", "FK"),
            ("content_id", "INT", "FK"),
            ("comment_text", "VARCHAR(500)", ""),
            ("comment_timestamp", "DATETIME", ""),
            ("comment_length", "SMALLINT", ""),
            ("sentiment_score", "DECIMAL(4,3)", ""),
        ],
    },
}


def card_height(table: dict) -> int:
    return TITLE_HEIGHT + len(table["fields"]) * ROW_HEIGHT + 18


def center_top(name: str):
    x, y = TABLES[name]["position"]
    return (x + CARD_WIDTH // 2, y)


def center_bottom(name: str):
    x, y = TABLES[name]["position"]
    return (x + CARD_WIDTH // 2, y + card_height(TABLES[name]))


def center_left(name: str):
    x, y = TABLES[name]["position"]
    return (x, y + card_height(TABLES[name]) // 2)


def center_right(name: str):
    x, y = TABLES[name]["position"]
    return (x + CARD_WIDTH, y + card_height(TABLES[name]) // 2)


def draw_relation(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[int, int]],
    label: str,
    label_xy: tuple[int, int],
):
    draw.line(points, fill=COLORS["line"], width=5, joint="curve")
    start = points[0]
    end = points[-1]
    draw.ellipse((start[0] - 6, start[1] - 6, start[0] + 6, start[1] + 6), fill=COLORS["blue"])
    draw.ellipse((end[0] - 6, end[1] - 6, end[0] + 6, end[1] + 6), fill=COLORS["blue"])
    bbox = draw.textbbox((0, 0), label, font=RELATION_FONT)
    padding = 8
    box = (
        label_xy[0] - padding,
        label_xy[1] - padding,
        label_xy[0] + (bbox[2] - bbox[0]) + padding,
        label_xy[1] + (bbox[3] - bbox[1]) + padding,
    )
    draw.rounded_rectangle(box, radius=8, fill=COLORS["background"])
    draw.text(label_xy, label, font=RELATION_FONT, fill=COLORS["muted"])


def draw_card(draw: ImageDraw.ImageDraw, name: str, table: dict):
    x, y = table["position"]
    height = card_height(table)
    draw.rounded_rectangle(
        (x, y, x + CARD_WIDTH, y + height),
        radius=18,
        fill=COLORS["card"],
        outline=COLORS["border"],
        width=3,
    )
    draw.rounded_rectangle(
        (x, y, x + CARD_WIDTH, y + TITLE_HEIGHT),
        radius=18,
        fill=COLORS["navy"],
    )
    draw.rectangle(
        (x, y + TITLE_HEIGHT - 18, x + CARD_WIDTH, y + TITLE_HEIGHT),
        fill=COLORS["navy"],
    )
    draw.text(
        (x + 24, y + 15),
        name,
        font=CARD_TITLE_FONT,
        fill="#FFFFFF",
    )

    for index, (field_name, field_type, key_type) in enumerate(table["fields"]):
        row_y = y + TITLE_HEIGHT + index * ROW_HEIGHT
        if index % 2:
            draw.rectangle(
                (x + 2, row_y, x + CARD_WIDTH - 2, row_y + ROW_HEIGHT),
                fill="#F8FAFC",
            )
        draw.text(
            (x + 22, row_y + 9),
            field_name,
            font=FIELD_FONT,
            fill=COLORS["text"],
        )
        draw.text(
            (x + 270, row_y + 9),
            field_type,
            font=FIELD_FONT,
            fill=COLORS["muted"],
        )
        if key_type:
            badge_color = COLORS["pk"] if "PK" in key_type else COLORS["fk"]
            badge_text = COLORS["pk_text"] if "PK" in key_type else COLORS["fk_text"]
            badge_width = 74 if "," in key_type else 50
            bx = x + CARD_WIDTH - badge_width - 18
            draw.rounded_rectangle(
                (bx, row_y + 7, bx + badge_width, row_y + 33),
                radius=8,
                fill=badge_color,
            )
            draw.text(
                (bx + 9, row_y + 11),
                key_type,
                font=BADGE_FONT,
                fill=badge_text,
            )


def main():
    image = Image.new("RGB", (WIDTH, HEIGHT), COLORS["background"])
    draw = ImageDraw.Draw(image)
    draw.text(
        (70, 52),
        "Instagram Engagement Analytics - ER Diagram",
        font=TITLE_FONT,
        fill=COLORS["navy"],
    )
    draw.text(
        (70, 104),
        "Eight normalized MySQL tables | PK = primary key | FK = foreign key",
        font=SUBTITLE_FONT,
        fill=COLORS["muted"],
    )

    draw_relation(
        draw,
        [center_bottom("hashtags"), center_top("content_hashtags")],
        "1 : M",
        (292, 575),
    )
    draw_relation(
        draw,
        [center_right("content_hashtags"), center_left("content")],
        "M : 1",
        (670, 705),
    )
    draw_relation(
        draw,
        [center_bottom("users"), center_top("content")],
        "1 : M",
        (1110, 545),
    )
    draw_relation(
        draw,
        [center_bottom("sessions"), center_top("view_logs")],
        "1 : M",
        (1888, 590),
    )
    draw_relation(
        draw,
        [center_right("content"), center_left("view_logs")],
        "1 : M",
        (1450, 770),
    )
    draw_relation(
        draw,
        [
            (950, center_bottom("users")[1] - 25),
            (770, 520),
            (770, 1030),
            center_top("likes"),
        ],
        "1 : M",
        (590, 970),
    )
    draw_relation(
        draw,
        [
            (970, center_bottom("content")[1] - 20),
            (970, 1005),
            (720, 1005),
            center_top("likes"),
        ],
        "1 : M",
        (755, 915),
    )
    draw_relation(
        draw,
        [
            (1250, center_bottom("users")[1] - 25),
            (1430, 520),
            (1430, 1030),
            center_top("comments"),
        ],
        "1 : M",
        (1500, 970),
    )
    draw_relation(
        draw,
        [
            (1230, center_bottom("content")[1] - 20),
            (1230, 1005),
            (1490, 1005),
            center_top("comments"),
        ],
        "1 : M",
        (1370, 915),
    )

    for table_name, table in TABLES.items():
        draw_card(draw, table_name, table)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, optimize=True)
    print(f"Saved {OUTPUT}")


if __name__ == "__main__":
    main()
