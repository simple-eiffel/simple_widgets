#!/usr/bin/env python3
"""Generate src/sw_world_cities.e from Natural Earth 110m populated places.

Data: https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_populated_places_simple.geojson
(Natural Earth is public domain.)

Record format: name~country~lat~lon~pop;  - fields '~', records ';'.
Lines wrap ONLY at record boundaries (the coastline generator's
mid-number lesson, applied): a newline can never fall inside a field.

Usage: python3 tools/gen_world_cities.py path/to/ne_110m_populated_places_simple.geojson
"""
import json, sys, pathlib, unicodedata

src = pathlib.Path(sys.argv[1])
out = pathlib.Path(__file__).resolve().parent.parent / "src" / "sw_world_cities.e"

def ascii_fold(s):
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii")

d = json.load(open(src, encoding="utf-8"))
recs = []
for f in d["features"]:
    pr = f["properties"]
    lon, lat = f["geometry"]["coordinates"][:2]
    name = ascii_fold(pr.get("nameascii") or pr.get("name") or "?").replace("~", "-").replace(";", ",")
    country = ascii_fold(pr.get("adm0name") or "?").replace("~", "-").replace(";", ",")
    pop = int(pr.get("pop_max") or 0)
    recs.append(f"{name}~{country}~{round(lat, 2)}~{round(lon, 2)}~{pop}")

recs.sort(key=lambda r: -int(r.rsplit("~", 1)[1]))          # biggest first
blob = ";".join(recs) + ";"

# chunk into verbatim blocks, wrapping lines at ';' only
CHUNK = 14000
chunks = []
i = 0
while i < len(blob):
    j = min(i + CHUNK, len(blob))
    if j < len(blob):
        k = blob.rfind(";", i, j)
        if k > i:
            j = k + 1
    chunks.append(blob[i:j])
    i = j

decls = []
for n, c in enumerate(chunks, 1):
    lines = []
    k = 0
    while k < len(c):
        j = min(k + 96, len(c))
        if j < len(c):
            sp = c.rfind(";", k, j)
            if sp > k:
                j = sp + 1
        lines.append(c[k:j])
        k = j
    body = "\n".join("\t\t" + ln for ln in lines)
    decls.append(f'\tdata_{n}: STRING = "[\n{body}\n\t]"\n')

calls = "\n".join(f"\t\t\tparse_block (data_{n}, Result)" for n in range(1, len(chunks) + 1))

eiffel = f'''note
\tdescription: "[
\t\tEvery city Natural Earth 110m knows ({len(recs)} populated
\t\tplaces, public domain), generated into data-only source by
\t\ttools/gen_world_cities.py - DO NOT EDIT BY HAND. Name,
\t\tcountry, lat/lon and peak population per city, biggest
\t\tfirst, parsed once and shared.
\t]"

class
\tSW_WORLD_CITIES

feature -- Access

\tcities: ARRAYED_LIST [TUPLE [name, country: STRING_32; lat, lon: REAL_64; population: INTEGER]]
\t\t\t-- All places, biggest population first. Parsed once.
\t\tonce
\t\t\tcreate Result.make ({len(recs)})
{calls}
\t\tensure
\t\t\tmany: Result.count >= 200
\t\tend

feature {{NONE}} -- Parsing

\tparse_block (a_data: STRING; a_acc: ARRAYED_LIST [TUPLE [name, country: STRING_32; lat, lon: REAL_64; population: INTEGER]])
\t\t\t-- Records end at ';', fields split on '~'; line breaks
\t\t\t-- fall only BETWEEN records by generator law, so stray
\t\t\t-- whitespace is trimmed at field edges only.
\t\tlocal
\t\t\ti, n, f: INTEGER
\t\t\tc: CHARACTER
\t\t\tfields: ARRAY [STRING]
\t\t\ttok: STRING
\t\tdo
\t\t\tcreate fields.make_filled (create {{STRING}}.make_empty, 1, 5)
\t\t\tcreate tok.make (24)
\t\t\tf := 1
\t\t\tn := a_data.count
\t\t\tfrom
\t\t\t\ti := 1
\t\t\tuntil
\t\t\t\ti > n
\t\t\tloop
\t\t\t\tc := a_data.item (i)
\t\t\t\tif c = ';' then
\t\t\t\t\tfields [f] := tok.twin
\t\t\t\t\tif f = 5 then
\t\t\t\t\t\ta_acc.extend ([
\t\t\t\t\t\t\tfields [1].to_string_32,
\t\t\t\t\t\t\tfields [2].to_string_32,
\t\t\t\t\t\t\tfields [3].to_double,
\t\t\t\t\t\t\tfields [4].to_double,
\t\t\t\t\t\t\tfields [5].to_integer])
\t\t\t\t\tend
\t\t\t\t\ttok.wipe_out
\t\t\t\t\tf := 1
\t\t\t\telseif c = '~' then
\t\t\t\t\tfields [f] := tok.twin
\t\t\t\t\ttok.wipe_out
\t\t\t\t\tif f < 5 then
\t\t\t\t\t\tf := f + 1
\t\t\t\t\tend
\t\t\t\telseif c = '%N' or c = '%T' or c = '%R' then
\t\t\t\t\t-- between-records air only, by generator law
\t\t\t\telse
\t\t\t\t\ttok.extend (c)
\t\t\t\tend
\t\t\t\ti := i + 1
\t\t\tend
\t\tend

feature {{NONE}} -- Generated data (Natural Earth 110m, public domain)

{chr(10).join(decls)}
end
'''
out.write_text(eiffel, newline="\n")
big = sum(1 for r in recs if int(r.rsplit("~", 1)[1]) >= 5_000_000)
two = sum(1 for r in recs if int(r.rsplit("~", 1)[1]) >= 2_000_000)
print(f"wrote {out} - {len(recs)} cities, {len(chunks)} blocks, {out.stat().st_size} bytes | >=5M: {big} | >=2M: {two}")
