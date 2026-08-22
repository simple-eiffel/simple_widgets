# R01 — WEL + Vision2 Widget Inventory (EiffelStudio 25.02)

*Compiled 2026-08-22 by direct crawl of the installed library trees.
Feeds S02-WIDGET-CATALOG. Summary form; the numbers are exact, the
groupings verbatim from the crawl.*

## Headline counts

- Vision2: 41 primitives, 21 container widgets, 17 dialogs, 29 item
  classes, 21 kernel classes, 15 contrib widgets.
- WEL: 41 controls, 14 window classes, 9 standard dialogs; 589 .e
  files in the whole library.
- **Deduped union: 80 distinct widget concepts.**

## The 80 concepts, by group (WEL / Vision2 providers noted in crawl)

Buttons and toggles (8): push button; image button; owner-drawn
button; toggle button; check box; 3-state check box; radio button;
menu button.
Static/display (5): label; image display; hyperlink label; group
box/titled border; separator line.
Text entry (4): single-line field; password field; multi-line text;
rich text.
Lists and selection (12): single-select list; multi-select list;
checkable list; editable combo; list-only combo; image combo
(ComboBoxEx); multi-column report list; tree view; checkable tree;
lazy tree node; tree+grid hybrid (EV_GRID family); column header bar.
Navigation/command (9): notebook/tabs; toolbar (+5 item kinds);
rebar; status bar; menu bar; popup menu; menu item variants;
tooltip; keyboard accelerators.
Value/range (4): progress bar; slider; scroll bar; spinner.
Drawing (4): drawing surface; pixel buffer; image list; vector
figure/model scene graph.
Layout containers (9, Vision2-only): cell; h/v box; table layout;
fixed layout; 2-pane splitter; N-pane splitter (contrib);
scrollable area; viewport; widget list.
Windows (5): framed top-level; borderless popup; MDI trio; tray
notify window; resource-template dialog.
Dialogs (10): modal; modeless; untitled; message-box family (info/
warning/error/question/confirmation); color; font; file open; file
save; folder; print.
Non-visual services (10): application/event loop; timer; cursor;
icon; clipboard; font object; color object; screen/DPI; drag-and-
drop (pick-and-drop, dockable); printing.

## Absent from BOTH WEL and Vision2 (never wrapped)

Month calendar; date-time picker; hot-key control; animation
control; IP-address control; pager; SysLink; task dialog; property
sheet/wizard; split button; command-link button; breadcrumb.
(Separate ISE libraries exist for: ribbon (~40 EV_RIBBON_*), web
browser (EV_WEB_BROWSER), docking (228 SD_* classes).)

## Reading for simple_widgets

The Vision2 layout-container family (boxes, table, splitters,
scrollable, viewport) is the part WEL never had and applications
lean on hardest; simple_widgets' SW_ROW/SW_COLUMN are the first two
of that family. The EV_GRID cluster (virtual rows, in-place editor
items) is Vision2's crown jewel and maps to the future SW_LIST/
SW_GRID. The property mixins (EV_TOOLTIPABLE, EV_SENSITIVE,
EV_PICK_AND_DROPABLE...) suggest capability-by-inheritance the SW_
tree can echo with contracts.
