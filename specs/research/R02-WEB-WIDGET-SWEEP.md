# R02 — Web Widget-Library Sweep (2025/26)

*Compiled 2026-08-22 from 19 sources: native HTML/MDN, W3Schools
(elements, input types, How-To patterns, Bootstrap track), Bootstrap
5.3, MUI (+X), Ant Design 5, Fluent UI 2, shadcn/ui, Radix, React
Aria, Headless UI, Blueprint, Mantine, Chakra v3, PrimeReact,
KendoReact, Syncfusion React, DevExtreme, Vuetify, daisyUI. Bootstrap
and the React ecosystem covered at extra depth per the charter.
Full provider-by-provider tables live in the research transcript;
this file preserves the union, the tiers and the counts.*

## Headline

**232 distinct widget concepts** across 15 domains.
Tier 1 (nearly every library): **45**. Tier 2 (most): **59**.
Tier 3 (specialized/enterprise): **~128**.

## Tier 1 — the must-haves (45)

Text field · Textarea · Password field · Autocomplete · Label · Form
container · Checkbox · Radio group · Switch · Select · Multi-select ·
Combobox · Button · Link · Navbar/app bar · Side navigation ·
Breadcrumbs · Tabs · Pagination · Grid system · Card · Accordion ·
Collapse/disclosure · Divider · Static table · Data grid · List ·
Avatar · Badge · Chip/tag · Typography · Icon · Alert · Toast ·
Progress bar · Spinner · Skeleton · Modal dialog · Drawer · Popover ·
Tooltip · Menu (dropdown) · Date picker · Number input · Slider ·
File upload.

## Tier 2 — in most libraries (59, abridged to clusters)

Input refinements (auto-resize, search, mask, OTP, tags, field
wrapper, fieldset, adornments, floating label, validation display);
choice refinements (checkbox group, tri-state, toggle button,
segmented control, listbox, rating); command refinements (icon
button, button group, split button, menu button, FAB, speed dial,
toolbar, loading button); navigation (menu bar, navigation menu,
nav link, bottom nav, stepper/wizard); layout (box, container,
stack/flex, paper, panel, splitter, aspect ratio, scroll area, app
shell); display (tree view, enhanced image, timeline, empty state,
progress circle, loading overlay); overlays (confirm dialog, context
menu); date/time (calendar, range picker, time picker, date-time);
inputs (range slider, color picker); media (carousel); charts
(cartesian suite, pie); behavior utilities (portal, focus trap,
click-away, transitions, visually-hidden, DnD, providers, responsive
observers).

## Tier 3 — the long tail (~128, by family)

Hierarchical selects (cascader, tree select, multi-column combobox,
lookup, transfer, order list) · niche inputs (knob, angle slider,
color primitives, signature, dropzone, captcha) · display extras
(stat, QR, barcode, kbd, spoiler, marquee, persona, watermark, diff,
mockups, description list, virtualizer, infinite scroll) · overlay
extras (popconfirm, hover card, toggle tip, floating window,
lightbox, action sheet, guided tour) · nav extras (mega menu, dock,
ribbon, scrollspy, affix, back-to-top, skip nav) · layout extras
(masonry, dashboard tiles, multi-view, hero, footer) · the whole
charts family beyond basics (gauges, sparkline, heatmap, treemap,
funnel, sankey, stock, maps, diagram) · enterprise composites
(scheduler, gantt, kanban, pivot, spreadsheet, file manager, query
builder, form generator, org chart, document editors, export) · the
2025/26 conversational cluster (chat thread, AI prompt view, smart
textarea, smart-paste, speech-to-text buttons).

## Counts by domain

| Domain | Concepts | T1 | T2 | T3 |
|---|---|---|---|---|
| Text input and editing | 21 | 6 | 10 | 5 |
| Selection and choice | 22 | 6 | 5 | 11 |
| Buttons and commands | 17 | 1 | 7 | 9 |
| Navigation | 20 | 6 | 4 | 10 |
| Layout and containers | 22 | 4 | 9 | 9 |
| Data display | 32 | 8 | 3 | 21 |
| Feedback and status | 12 | 5 | 2 | 5 |
| Overlays | 16 | 5 | 2 | 9 |
| Date and time | 7 | 1 | 4 | 2 |
| Numbers and special inputs | 15 | 3 | 2 | 10 |
| Media | 8 | 0 | 1 | 7 |
| Charts and visualization | 15 | 0 | 2 | 13 |
| Enterprise composites | 11 | 0 | 0 | 11 |
| Conversational and AI | 3 | 0 | 0 | 3 |
| Utilities and behaviors | 11 | 0 | 8 | 3 |
| **Total** | **232** | **45** | **59** | **128** |

## Desktop-idiom override

Web tiers understate desktop needs. Promote regardless of tier:
tree view, tree table, virtualized list, splitter, toolbar, context
menu, status indicator/status bar, file dialogs and dropzone,
description list (property grid). These are Windows-application
bread and butter.

## Per-source sizes (as surveyed)

HTML: 16 elements + 22 input types · W3Schools How-To ~200 patterns ·
Bootstrap 5.3: 50 modules · MUI ~60 + X · AntD 73 · Fluent 47 ·
shadcn 63 · Radix 35 · React Aria 64 · Headless UI 16 · Blueprint
~55 · Mantine ~110 · Chakra ~120 · PrimeReact ~100 · KendoReact ~120
· Syncfusion ~90 · DevExtreme ~80 · Vuetify 137 · daisyUI 65.
