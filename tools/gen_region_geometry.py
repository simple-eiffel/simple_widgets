#!/usr/bin/env python3
"""Generate src/sw_region_geometry.e: Natural Earth 10m land, lakes and rivers
for the Mediterranean, the Levant and Mesopotamia (GW-19), clipped to the
region box and simplified.

Data (Natural Earth is public domain - no attribution required, though deserved):
  https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_land.geojson
  https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_lakes.geojson
  https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_rivers_lake_centerlines.geojson

Usage: python3 tools/gen_region_geometry.py DIR [--dry]
  DIR holds the three .geojson files; --dry prints counts and writes nothing.
Writes: src/sw_region_geometry.e (data-only class; DO NOT EDIT the output)
"""
import json, sys, pathlib

WEST, EAST, SOUTH, NORTH = 8.0, 50.0, 22.0, 46.0
TOLERANCE = 0.012          # degrees, Douglas-Peucker
MIN_RIVER_LENGTH = 0.6     # degrees of polyline length kept

src = pathlib.Path(sys.argv[1])
dry = "--dry" in sys.argv
out = pathlib.Path(__file__).resolve().parent.parent / "src" / "sw_region_geometry.e"


def rings_of(geometry):
    if geometry["type"] == "Polygon":
        return [geometry["coordinates"][0]]
    if geometry["type"] == "MultiPolygon":
        return [p[0] for p in geometry["coordinates"]]
    return []


def holes_of(geometry):
    """Interior rings: seas inside land (the Caspian)."""
    if geometry["type"] == "Polygon":
        return geometry["coordinates"][1:]
    if geometry["type"] == "MultiPolygon":
        return [h for p in geometry["coordinates"] for h in p[1:]]
    return []


def lines_of(geometry):
    if geometry["type"] == "LineString":
        return [geometry["coordinates"]]
    if geometry["type"] == "MultiLineString":
        return geometry["coordinates"]
    return []


def clip_ring(ring):
    """Sutherland-Hodgman against the region box."""
    def clip(points, inside, cross):
        result = []
        for i in range(len(points)):
            cur, prev = points[i], points[i - 1]
            if inside(cur):
                if not inside(prev):
                    result.append(cross(prev, cur))
                result.append(cur)
            elif inside(prev):
                result.append(cross(prev, cur))
        return result

    def at_x(x):
        return lambda a, b: (x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]))

    def at_y(y):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]), y)

    pts = [(p[0], p[1]) for p in ring]
    for inside, cross in ((lambda p: p[0] >= WEST, at_x(WEST)), (lambda p: p[0] <= EAST, at_x(EAST)),
                          (lambda p: p[1] >= SOUTH, at_y(SOUTH)), (lambda p: p[1] <= NORTH, at_y(NORTH))):
        if not pts:
            break
        pts = clip(pts, inside, cross)
    return pts


def inside_box(p):
    return WEST <= p[0] <= EAST and SOUTH <= p[1] <= NORTH


def clip_line(line):
    """Pieces of the polyline inside the box (vertices outside dropped)."""
    pieces, cur = [], []
    for p in line:
        if inside_box(p):
            cur.append((p[0], p[1]))
        elif cur:
            pieces.append(cur)
            cur = []
    if cur:
        pieces.append(cur)
    return [c for c in pieces if len(c) >= 2]


def simplify(points, tol, closed):
    if len(points) < 4:
        return points
    def dp(pts):
        if len(pts) < 3:
            return pts
        a, b = pts[0], pts[-1]
        dx, dy = b[0] - a[0], b[1] - a[1]
        norm = (dx * dx + dy * dy) ** 0.5
        best, idx = -1.0, 0
        for i in range(1, len(pts) - 1):
            p = pts[i]
            if norm == 0:
                d = ((p[0] - a[0]) ** 2 + (p[1] - a[1]) ** 2) ** 0.5
            else:
                d = abs(dy * p[0] - dx * p[1] + b[0] * a[1] - b[1] * a[0]) / norm
            if d > best:
                best, idx = d, i
        if best > tol:
            return dp(pts[:idx + 1])[:-1] + dp(pts[idx:])
        return [a, b]
    sys.setrecursionlimit(100000)
    if closed:
        half = len(points) // 2
        return dp(points[:half + 1])[:-1] + dp(points[half:] + [points[0]])[:-1]
    return dp(points)


def length(line):
    return sum(((line[i][0] - line[i - 1][0]) ** 2 + (line[i][1] - line[i - 1][1]) ** 2) ** 0.5 for i in range(1, len(line)))


def polygons(name, take=rings_of):
    d = json.load(open(src / name, encoding="utf-8"))
    result = []
    for f in d["features"]:
        for r in take(f["geometry"]):
            c = clip_ring(r)
            c = simplify(c, TOLERANCE, True)
            if len(c) >= 3:
                result.append(c)
    return result


def rivers():
    d = json.load(open(src / "ne_10m_rivers_lake_centerlines.geojson", encoding="utf-8"))
    result = []
    for f in d["features"]:
        for line in lines_of(f["geometry"]):
            for piece in clip_line(line):
                s = simplify(piece, TOLERANCE, False)
                if len(s) >= 2 and length(s) >= MIN_RIVER_LENGTH:
                    result.append(s)
    return result


land = polygons("ne_10m_land.geojson")
holes = polygons("ne_10m_land.geojson", holes_of)
lakes = polygons("ne_10m_lakes.geojson")
river_lines = rivers()


def count(rs):
    return sum(len(r) for r in rs)


print(f"land {len(land)} rings {count(land)} points; holes {len(holes)} rings {count(holes)} points; lakes {len(lakes)} rings {count(lakes)} points; "
      f"rivers {len(river_lines)} lines {count(river_lines)} points")
if dry:
    sys.exit(0)


def num(v):
    s = f"{round(v, 3):.3f}".rstrip("0").rstrip(".")
    return s if s not in ("-0", "") else "0"


def blob(rs):
    return ";".join(" ".join(num(x) + " " + num(y) for x, y in r) for r in rs)


def chunks(text, size=14000):
    result, i = [], 0
    while i < len(text):
        j = min(i + size, len(text))
        if j < len(text):
            k = text.rfind(" ", i, j)
            if k > i:
                j = k
        result.append(text[i:j])
        i = j
    return result or [""]


def verbatim(name, text):
    lines, k = [], 0
    while k < len(text):
        j = min(k + 96, len(text))
        if j < len(text):
            sp = text.rfind(" ", k + 1, j)
            if sp > k:
                j = sp
        lines.append("\t\t\t" + text[k:j].strip())
        k = j
    return f'\t{name}: STRING = "[\n' + "\n".join(lines) + '\n\t\t]"\n'


sections = []
decls = []
for kind, rs in (("land", land), ("holes", holes), ("lakes", lakes), ("rivers", river_lines)):
    parts = chunks(blob(rs))
    calls = "\n".join(f"\t\t\tparse_block ({kind}_{n}, Result)" for n in range(1, len(parts) + 1))
    sections.append((kind, len(rs), calls))
    for n, part in enumerate(parts, 1):
        decls.append(verbatim(f"{kind}_{n}", part))

header = f'''note
	description: "[
		The Mediterranean, the Levant and Mesopotamia at 1:10m (GW-19):
		Natural Earth 10m land, lakes and river centerlines (public domain),
		clipped to lon {WEST:g}..{EAST:g}, lat {SOUTH:g}..{NORTH:g} and simplified to
		{TOLERANCE:g} degrees, as data-only Eiffel source produced by
		tools/gen_region_geometry.py - DO NOT EDIT BY HAND.
		{len(land)} land rings ({count(land)} points), {len(holes)} seas inside the land
		({count(holes)} points: the Caspian), {len(lakes)} lakes ({count(lakes)} points),
		{len(river_lines)} river lines ({count(river_lines)} points).
	]"

class
	SW_REGION_GEOMETRY

feature -- Region

	West: REAL_64 = {WEST:.1f}
	East: REAL_64 = {EAST:.1f}
	South: REAL_64 = {SOUTH:.1f}
	North: REAL_64 = {NORTH:.1f}

	contains (a_lat, a_lon: REAL_64): BOOLEAN
			-- Is the point inside the region box?
		do
			Result := a_lon >= West and a_lon <= East and a_lat >= South and a_lat <= North
		end

feature -- Access
'''
body = ""
for kind, n, calls in sections:
    what = {"land": "Every land ring", "holes": "Every sea inside the land (an interior ring of the land: the Caspian)",
            "lakes": "Every lake ring", "rivers": "Every river line"}[kind]
    body += f'''
	{kind}: ARRAYED_LIST [ARRAY [REAL_64]]
			-- {what} as a flat [lon1, lat1, lon2, ...] array. Parsed once;
			-- shared.
		once
			create Result.make ({n})
{calls}
			flush (Result)
		end
'''
parser = '''
feature {NONE} -- Parsing

	parse_block (a_data: STRING; a_acc: ARRAYED_LIST [ARRAY [REAL_64]])
			-- Rings or lines separated by ';', numbers by white space; a block
			-- boundary can fall mid-ring, so an unfinished tail waits in
			-- `pending' for the next block (and `flush').
		local
			i: INTEGER
			c: CHARACTER
			tok: STRING
		do
			create tok.make (12)
			from
				i := 1
			until
				i > a_data.count
			loop
				c := a_data.item (i)
				if c = ';' then
					if not tok.is_empty then
						pending.extend (tok.to_double)
						tok.wipe_out
					end
					flush (a_acc)
				elseif c = ' ' or c = '%N' or c = '%T' or c = '%R' then
					if not tok.is_empty then
						pending.extend (tok.to_double)
						tok.wipe_out
					end
				else
					tok.extend (c)
				end
				i := i + 1
			end
			if not tok.is_empty then
				pending.extend (tok.to_double)
			end
		end

	flush (a_acc: ARRAYED_LIST [ARRAY [REAL_64]])
			-- Move the pending numbers out as one ring or line.
		local
			l_ring: ARRAY [REAL_64]
			i: INTEGER
		do
			if pending.count >= 4 then
				create l_ring.make_filled (0.0, 1, pending.count)
				from
					i := 1
				until
					i > pending.count
				loop
					l_ring [i] := pending.i_th (i)
					i := i + 1
				end
				a_acc.extend (l_ring)
			end
			pending.wipe_out
		end

	pending: ARRAYED_LIST [REAL_64]
		once
			create Result.make (4096)
		end

feature {NONE} -- Data
'''
text = header + body + parser + "\n".join(decls) + "\nend\n"
out.write_bytes(text.replace("\n", "\r\n").encode("ascii"))
print("wrote", out, len(text), "characters")
