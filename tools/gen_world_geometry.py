#!/usr/bin/env python3
"""Generate src/sw_world_geometry.e from Natural Earth 110m land polygons.

Data: https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson
(Natural Earth is public domain - no attribution required, though deserved.)

Usage: python3 tools/gen_world_geometry.py path/to/ne_110m_land.geojson
Writes: src/sw_world_geometry.e (data-only class; DO NOT EDIT the output)
"""
import json, sys, pathlib

src = pathlib.Path(sys.argv[1])
out = pathlib.Path(__file__).resolve().parent.parent / "src" / "sw_world_geometry.e"

d = json.load(open(src, encoding="utf-8"))
rings = []
for f in d["features"]:
    g = f["geometry"]
    outers = [g["coordinates"][0]] if g["type"] == "Polygon" else [p[0] for p in g["coordinates"]]
    for r in outers:
        if len(r) >= 2 and r[0] == r[-1]:
            r = r[:-1]                      # close_path closes; drop the echo
        if len(r) >= 3:
            rings.append(r)

def num(v):
    s = f"{round(v, 2):.2f}".rstrip("0").rstrip(".")
    return s if s not in ("-0", "") else "0"

parts = []
for r in rings:
    parts.append(" ".join(num(lon) + " " + num(lat) for lon, lat in r))
blob = ";".join(parts)

# wrap into verbatim-string chunks (~14KB each), breaking only at spaces
CHUNK = 14000
chunks = []
i = 0
while i < len(blob):
    j = min(i + CHUNK, len(blob))
    if j < len(blob):
        k = blob.rfind(" ", i, j)
        if k > i:
            j = k
    chunks.append(blob[i:j])
    i = j

total_pts = sum(len(r) for r in rings)
biggest = max(len(r) for r in rings)

decls = []
for n, c in enumerate(chunks, 1):
    lines = []
    k = 0
    while k < len(c):
        j = min(k + 96, len(c))
        if j < len(c):
            sp = c.rfind(" ", k + 1, j)
            if sp > k:
                j = sp
        lines.append(c[k:j])
        k = j
    body = "\n".join("\t\t" + ln for ln in lines)
    decls.append(f'\tdata_{n}: STRING = "[\n{body}\n\t]"\n')

feature_calls = "\n".join(f"\t\t\tparse_block (data_{n}, Result)" for n in range(1, len(chunks) + 1))

eiffel = f'''note
\tdescription: "[
\t\tThe planet, generated: Natural Earth 110m land polygons
\t\t(public domain) as data-only Eiffel source, produced by
\t\ttools/gen_world_geometry.py - DO NOT EDIT BY HAND.
\t\t{len(rings)} exterior rings, {total_pts} points (biggest ring
\t\t{biggest}), coordinates rounded to 0.01 degrees, parsed once
\t\tinto flat lon/lat arrays shared by every map.
\t]"

class
\tSW_WORLD_GEOMETRY

inherit
\tSW_GEOMETRY_DATA

feature -- Access

\tpolygons: ARRAYED_LIST [ARRAY [REAL_64]]
\t\t\t-- Every landmass ring as a flat [lon1, lat1, lon2, ...]
\t\t\t-- array. Parsed once; shared (once class-level).
\t\tonce
\t\t\tcreate Result.make ({len(rings)})
{feature_calls}
\t\t\tflush (Result)
\t\tensure
\t\t\tmany_rings: Result.count >= 100
\t\tend

feature {{NONE}} -- Generated data (Natural Earth 110m, public domain)

{chr(10).join(decls)}
end
'''
eiffel = eiffel.replace("%\\N", "%N").replace("%\\T", "%T").replace("%\\R", "%R")
out.write_text(eiffel, newline="\n")
print(f"wrote {out} - {len(rings)} rings, {total_pts} pts, {len(chunks)} data blocks, {out.stat().st_size} bytes")
