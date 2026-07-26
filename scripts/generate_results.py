#!/usr/bin/env python3
"""Run every portfolio query and export reproducible CSV and PNG results."""

from __future__ import annotations

import argparse
import csv
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont


REPO_ROOT = Path(__file__).resolve().parents[1]
QUERY_DIR = REPO_ROOT / "sql" / "queries"
CSV_DIR = REPO_ROOT / "results" / "csv"
SCREENSHOT_DIR = REPO_ROOT / "results" / "screenshots"


def find_mysql_client(explicit_path: str | None) -> str:
    candidates = [
        explicit_path,
        os.environ.get("MYSQL_CLIENT"),
        shutil.which("mysql"),
        "/Applications/MySQLWorkbench.app/Contents/MacOS/mysql",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return candidate
    raise FileNotFoundError(
        "MySQL client not found. Install mysql-client or set MYSQL_CLIENT."
    )


def run_mysql(
    mysql_client: str,
    query: str,
    *,
    host: str,
    port: int,
    user: str,
    password: str,
    database: str,
    table_output: bool,
) -> str:
    command = [
        mysql_client,
        "--host",
        host,
        "--port",
        str(port),
        "--user",
        user,
        "--default-character-set=utf8mb4",
        "--raw",
    ]
    command.append("--table" if table_output else "--batch")
    command.append(database)

    environment = os.environ.copy()
    environment["MYSQL_PWD"] = password
    completed = subprocess.run(
        command,
        input=query,
        text=True,
        capture_output=True,
        check=False,
        env=environment,
    )
    if completed.returncode:
        raise RuntimeError(completed.stderr.strip() or "MySQL query failed.")
    return completed.stdout.rstrip()


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNSMono.ttf",
        "/System/Library/Fonts/Menlo.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def render_terminal_screenshot(
    query_path: Path, table_text: str, output_path: Path
) -> None:
    title_font = load_font(24, bold=True)
    body_font = load_font(20)
    small_font = load_font(17)
    lines = table_text.splitlines()
    prompt = f"mysql> SOURCE sql/queries/{query_path.name};"

    probe = Image.new("RGB", (10, 10))
    probe_draw = ImageDraw.Draw(probe)
    candidate_lines = [prompt, *lines, "Query executed successfully on MySQL 8.0"]
    max_width = max(
        probe_draw.textlength(line, font=body_font) for line in candidate_lines
    )
    line_height = 30
    width = max(1280, min(3600, int(max_width) + 112))
    height = 150 + (len(lines) + 1) * line_height + 90

    image = Image.new("RGB", (width, height), "#0B1220")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        (18, 18, width - 18, height - 18),
        radius=20,
        fill="#111827",
        outline="#334155",
        width=2,
    )
    draw.rounded_rectangle(
        (18, 18, width - 18, 76),
        radius=20,
        fill="#172033",
    )
    draw.rectangle((18, 56, width - 18, 76), fill="#172033")
    for x, color in [(46, "#FB7185"), (76, "#FBBF24"), (106, "#34D399")]:
        draw.ellipse((x - 8, 39 - 8, x + 8, 39 + 8), fill=color)

    draw.text(
        (142, 27),
        "MySQL 8.0 | instagram_engagement_analytics",
        font=title_font,
        fill="#E5E7EB",
    )
    y = 98
    draw.text((48, y), prompt, font=body_font, fill="#60A5FA")
    y += 46
    for line in lines:
        draw.text((48, y), line, font=body_font, fill="#E2E8F0")
        y += line_height
    draw.text(
        (48, height - 64),
        "Query executed successfully on MySQL 8.0",
        font=small_font,
        fill="#94A3B8",
    )
    image.save(output_path, optimize=True)


def export_csv(batch_text: str, output_path: Path) -> None:
    rows = list(csv.reader(io.StringIO(batch_text), delimiter="\t"))
    with output_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerows(rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=os.environ.get("MYSQL_HOST", "127.0.0.1"))
    parser.add_argument(
        "--port", type=int, default=int(os.environ.get("MYSQL_PORT", "3307"))
    )
    parser.add_argument("--user", default=os.environ.get("MYSQL_USER", "root"))
    parser.add_argument(
        "--password",
        default=os.environ.get("MYSQL_PASSWORD", "portfolio_dev"),
    )
    parser.add_argument(
        "--database",
        default=os.environ.get(
            "MYSQL_DATABASE", "instagram_engagement_analytics"
        ),
    )
    parser.add_argument("--mysql-client")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    mysql_client = find_mysql_client(args.mysql_client)
    CSV_DIR.mkdir(parents=True, exist_ok=True)
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)

    query_paths = sorted(QUERY_DIR.glob("*.sql"))
    if len(query_paths) != 10:
        raise RuntimeError(f"Expected 10 query files, found {len(query_paths)}.")

    for query_path in query_paths:
        query = query_path.read_text(encoding="utf-8")
        batch_text = run_mysql(
            mysql_client,
            query,
            host=args.host,
            port=args.port,
            user=args.user,
            password=args.password,
            database=args.database,
            table_output=False,
        )
        table_text = run_mysql(
            mysql_client,
            query,
            host=args.host,
            port=args.port,
            user=args.user,
            password=args.password,
            database=args.database,
            table_output=True,
        )
        stem = query_path.stem
        export_csv(batch_text, CSV_DIR / f"{stem}.csv")
        render_terminal_screenshot(
            query_path,
            table_text,
            SCREENSHOT_DIR / f"{stem}.png",
        )
        print(f"Generated results for {query_path.name}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
