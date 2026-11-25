"""Write the Utumno backdrop as an SVG for the active X11 outputs."""

from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def screen_layout():
    query = subprocess.check_output(["xrandr", "--current"], text=True)
    width, height = map(int, re.search(r"current (\d+) x (\d+)", query).groups())
    try:
        monitors = subprocess.check_output(["xrandr", "--listactivemonitors"], text=True)
    except subprocess.CalledProcessError:
        monitors = ""
    offsets = re.findall(r"(\d+)/\d+x(\d+)/\d+([+-]\d+)([+-]\d+)", monitors)
    if not offsets:
        offsets = re.findall(r" connected (?:primary )?(\d+)x(\d+)([+-]\d+)([+-]\d+)", query)
    rectangles = dict.fromkeys(tuple(map(int, geometry)) for geometry in offsets)
    return width, height, rectangles or [(width, height, 0, 0)]


def render():
    width, height, monitors = screen_layout()
    original = ET.parse(Path(__file__).with_name("d77-logo.svg")).getroot()
    logo = original.find("{http://www.w3.org/2000/svg}image")
    source = logo.get("{http://www.w3.org/1999/xlink}href")

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<defs><image id="logo" width="180" height="180" xlink:href="{source}"/></defs>',
        '<rect width="100%" height="100%" fill="#1a1b26"/>',
    ]
    for w, h, x, y in monitors:
        # These are the two rectangles and center rotations in Utumno's Backdrop.qml.
        svg.extend([
            f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="0 0 {w} {h}" overflow="hidden">',
            f'<rect x="{w * 0.68}" y="{-h * 0.3}" width="{w * 0.8}" height="{h * 1.6}" '
            f'fill="#554670" transform="rotate(35 {w * 1.08} {h * 0.5})"/>',
            f'<rect x="{w * 0.84}" y="{-h * 0.2}" width="{w * 0.4}" height="{h * 1.3}" '
            f'fill="#866eb0" transform="rotate(35 {w * 1.04} {h * 0.45})"/>',
            f'<use xlink:href="#logo" x="48" y="{h - 228}" opacity="0.25"/>',
            "</svg>",
        ])
    svg.append("</svg>")
    return "\n".join(svg)


if __name__ == "__main__":
    Path(sys.argv[1]).write_text(render(), encoding="utf-8")
