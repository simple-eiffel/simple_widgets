# Design Scan (diff mode): GW-20 printing, three repositories
# Date: 2026-10-25. READ-ONLY. Nothing compiled or run; findings come from reading the diffs and sources.
# simple_cairo 5a165f1..aaa7ca9 (1.6.0); simple_shell d1d823e..e9dd229 (1.24.0); simple_widgets 1260e13..73fca14 (0.40.0)
# Line numbers: SW_PRINT_JOB = src/sw_print_job.e; SW_PRINT_PREVIEW = src/sw_print_preview.e; others as named.

## Summary
| Priority | Count |
|----------|-------|
| HIGH | 5 |
| MEDIUM | 10 |
| LOW | 7 |

## HIGH

### H1. The preview draws the widget in the SCREEN theme on white paper (D1: preview vs print drift)
Files: sw_print_job.e:137-174, sw_print_preview.e:145
Evidence: draw_page paints header text with the job's paper theme (line 158, theme.ink_muted) but the content is widget.draw (a_p) (line 169), which reads a_p.theme. The print paths build their painter with new_painter (lines 380-384: painter theme = job theme), so print and PDF are light. The preview calls job.draw_page (a_p, ...) with the SCREEN painter (preview line 145), so under a dark or high-contrast screen theme the document is drawn in light inks over 0xFFFFFF: unreadable, and not what prints. Tests cover only the light theme (test_gw20_preview_light).
Fix: draw_page must not trust the caller's painter theme. Add SW_PAINTER.with_theme (swap and restore around the widget draw), or a job feature returning a painter on the same context with the job theme. Add a dark-theme preview test that samples a text pixel.

### H2. The job rewrites the widget's bounds and layout; print_height is a query with side effects; the guard is only parent = Void
Files: sw_print_job.e:28,102-104; sw_doc_units.e:286-292; sw_widget.e:758-768
Evidence: paginate calls print_height, then set_bounds (0,0,width,printed_height) and arrange. SW_DOC_UNITS.print_height itself does set_bounds + arrange to measure (CQS violation: a query that lays the widget out at paper width). A widget with parent = Void can still be a live window root, or one held by another job or preview. The job never restores bounds. A setup change makes a NEW job on the same widget, leaving earlier jobs' page_tops stale against the re-laid-out content, and the preview that still holds the old job draws garbage.
Fix: rename the measuring routine (command, e.g. prepare_for_print) and keep print_height pure or document it as a command; SW_PRINT_JOB records x/y/width/height and restores plus re-arranges on release; strengthen the precondition (not shown, not held by another job).

### H3. Cairo and Windows resources and the open document leak on any exception in print_to
Files: sw_print_job.e:221-267
Evidence: between begin_document and end_document the loop creates l_surface, l_ctx, l_p per page and runs draw_page / widget.draw. Any exception (a widget contract violation, push_transform precondition, shaping failure) skips l_ctx.destroy, l_surface.destroy, end_page and abort_document. The process-wide DC (s_shell_print_dc, simple_shell_print.h:29) then stays open for the life of the process, so every later print_to is silently refused by not l_printer.is_printing (line 236) and the spooler holds a half document. Also make_for_printer_dc has no validity check (CAIRO_SURFACE, handle may be NULL when the DC is bad), yet the job builds a context on it and still calls end_page, possibly reporting success. write_pdf's cairo route (written_through_cairo, 271-320) has a rescue; print_to does not.
Fix: wrap the page loop in a rescue that destroys the current ctx and surface and calls abort_document when is_printing, sets last_error; check l_surface.is_valid and l_ctx.is_valid before drawing.

### H4. print_to failures never set last_error; the only working PDF route is the least diagnosable
Files: sw_print_job.e:198-209,221-267; simple_shell_print.h:77-118
Evidence: print_to returns False for (a) a document already open (line 236), (b) begin_document failing (bad name, DocumentPropertiesW, CreateDCW or StartDocW failure; shell_print_begin returns 0 and discards GetLastError), (c) begin_page, end_page or end_document failure. None writes last_error. write_pdf only fills the "file did not arrive" case (202-204), so for (a)-(c) the user reads "cairo: <reason>; " with an empty tail. On the shipped DLL (CHANGELOG known defect) this fallback is the route that runs.
Fix: add a C static for the failing stage plus GetLastError, expose SHELL_PRINTER.last_failure, copy it into last_error in print_to with the stage name; give "already printing" its own message.

### H5. SHELL_PRINTER: one process-wide document, modelled as per-instance state, unguarded
Files: simple_shell_print.h:29-30,84,115; shell_printer.e:71-105; sw_print_job.e:235-236
Evidence: s_shell_print_dc is one static. is_printing (shell_printer.e:71) reads it for ANY instance, print_to makes a fresh SW_PRINTER per call, so instance A can end or abort instance B's document and dc hands out the global DC. The check-then-set at header 84/115 is not atomic: two SCOOP processors or threads can both pass s_shell_print_dc == 0 and the second CreateDC/StartDoc DC is overwritten and leaked. Preconditions (not_printing) test global state and so can fail between check and call.
Fix: make the document an object (C returns an opaque struct with dc and in_page, SHELL_PRINTER owns it, preconditions per instance) so two jobs can coexist, or at minimum make the begin/end/abort transitions interlocked and document SHELL_PRINTER as a once-per-process service.

## MEDIUM

### M1. Preview cost: every visible sheet draws the WHOLE widget each frame
Files: sw_print_preview.e:128-151, sw_print_job.e:166-171
Evidence: draw_page clips to the slice but calls widget.draw unconditionally. SW_DOC_UNITS culls against its own bounds, and those are printed_height tall, so nothing is culled: one to three visible sheets per frame each redraw and re-shape the entire document. Frame cost scales with document size.
Fix: give the widget a slice to draw (draw_slice (a_p, a_top, a_bottom) or temporary viewport), or cache each sheet to a bitmap at preview resolution and redraw on job or size change (print stays vector).

### M2. Unit conversions: dots_per_inch_x for both axes; printable area ignored
Files: sw_print_job.e:240,251; shell_printer.e:160-217
Evidence: l_dots := dots_per_inch_x / 72.0 is the single uniform scale. Printers with unequal resolution (600x1200, label printers) print squashed or stretched. The translate -unprintable_left/_top is correct in sign and unit (device dots, applied before the scale in push_transform). But printable_width/height are never compared with the content rectangle, and set_margin_points allows 0, so content outside the printable area is silently clipped by the device.
Fix: separate x and y scales (push_transform with sx, sy), and report in last_error or a warning when the margins fall outside the printable area.

### M3. paginate: progress and bounds are not asserted
Files: sw_print_job.e:107-123
Evidence: zero-height pages cannot occur today (the fallback gives l_top + l_page > l_top, and content_height_pixels > 0 by the setup invariant, sw_page_setup.e:166). But clean_break is now a public redefinable feature: an override returning a value above l_end makes a slice taller than a page (clip at line 167 uses the slice, so content bleeds into the bottom margin); one returning below l_top still falls to the foot. No check or ensure states either. The loop end l_top >= printed_height - 0.5 silently drops a final sliver under half a pixel (acceptable); the equality page_bottom = printed_height in the tests holds only because l_end is copied, not computed.
Fix: clamp l_end := l_end.min (l_top + l_page).max (l_top + 1.0); ensure every page height <= content_height_pixels + epsilon; use a tolerance in tests.

### M4. Base clean_break edge cases
Files: sw_widget.e:770-796
Evidence: (1) a leaf returns its top when a_y is inside it; a leaf taller than three quarters of a page falls to the foot cut and is cut through (image, chart) with no signal. (2) side-by-side children: Result.min over every child containing a_y breaks at the highest top, wasting page space (three columns break at the earliest). (3) a_y inside the container but in no child returns a_y, which cuts through text the container draws itself. (4) all child coordinates are absolute and valid only after arrange (documented in the comment, not in a precondition). Tests exercise a label stack and one document only.
Fix: precondition on laid-out state; a deferred hook for unbreakable wholes; a test with side-by-side children.

### M5. SW_DOC_UNITS.clean_break cost and origin assumption
Files: sw_doc_units.e:295-330
Evidence: walks every unit and every line per page (O(units x lines x pages)); line 300 runs Precursor and the result is overwritten on the next line when inside bounds (dead computation). unit_origin_y (line 101-108) is relative to the stack while a_y and y are widget coordinates; correct only because paginate places the widget at y = 0.
Fix: binary search on the ordered stacked tops; subtract y explicitly.

### M6. Screen-only state is printed (selection, hover, focus, link hover)
Files: sw_print_job.e:169; sw_doc_units.e:726 (paint_unit_selection)
Evidence: widget.draw is the screen draw. A selected range or hover card prints. SW_WIDGET_EXPORTING already treats this ("with no hover", its header line 43).
Fix: reuse the exporting path's interaction-free draw switch in draw_page.

### M7. Duplication: paper theme vs export_theme; file helpers
Files: sw_print_job.e:33-35, sw_widget_exporting.e:126-139, sw_print_job.e:342-374
Evidence: both build make_light + adopt_metrics_from (theme); the job adds set_surfaces to white. Same decision coded twice, so the next change (semantics, locale, text_scale reset) will drift. file_size, delete_file, file_title are generic helpers sitting in a print job.
Fix: SW_THEME.make_paper (a_screen) or a shared side-by-side mixin used by both; move the file helpers to a shared helper. Also reset text_scale to 1.0 in the paper theme: adopt_metrics_from carries a 200 percent screen scale into print while points_per_pixel assumes nominal.

### M8. Printing features added to every SW_WIDGET
Files: sw_widget.e:756-796; sw_doc_units.e:36-48; sw_document_view.e:72
Evidence: two features that few classes override sit on the root class and ripple through undefine lists (SW_DOCUMENT_VIEW undefines both from one parent; verify it then uses the container logic and not the line logic, not covered by a test). Base print_height ensures only >= 0.
Fix: a deferred SW_PRINTABLE parent inherited side by side, with effective defaults, so the capability is declared.

### M9. SW_PRINT_PREVIEW contract gaps
Files: sw_print_preview.e:38-86,110-119
Evidence: sheet_scale is 0 until arrange, so sheet_height and scroll_extent are 0 and draw_page violates its a_scale > 0 precondition (via push_transform) if drawn before arrange; no invariant or precondition. set_job keeps the old sheet_scale (a landscape setup keeps the wrong aspect until the next arrange). handle_click is press_bar or else True and swallows every click.
Fix: set_job recomputes the scale; guard draw with is_arranged; state the click policy.

### M10. SW_PRINT_JOB reaches CAIRO_CONTEXT directly (breaks "SW_PAINTER is the only toucher")
Files: sw_print_job.e:98,248,252-254,284-286,294,302-310
Evidence: the job creates contexts and calls show_page, destroy, is_valid, status_message on them. SW_PRINT_PREVIEW does not touch the context (it only receives a painter). The job, not the painter, now owns this protocol in three places (paginate scratch, print_to, written_through_cairo) with copied create/destroy sequences.
Fix: SW_PAINTER (or a small SW_PAGE_SINK) gets next_page, release, failure_text, and a creation procedure on a surface; the job no longer names CAIRO_CONTEXT. The three create-draw-destroy blocks collapse into one.

## LOW

### L1. simple_cairo: make_for_printer_dc leaves a NULL handle on failure
cairo_surface.e (hunk +62): ensure says only owned. Add an is_valid or documented-null postcondition; callers check (see H3).

### L2. simple_cairo: known PDF defect lives only in prose
CHANGELOG.md (top section) and the comment at sw_print_job.e:178-185 duplicate it. CAIRO_PDF_SURFACE has no test. Add a tagged expected-failure test so a rebuilt DLL turns it green and the comments can be deleted.

### L3. CAIRO_CONTEXT.show_page returns nothing
cairo_context.e (+1365): callers poll is_valid afterwards (sw_print_job.e:302-307). Return BOOLEAN or ensure status is observable.

### L4. file_arrives is a weak completeness test and blocks the caller
sw_print_job.e:322-340: two equal sizes 100 ms apart accept a bursty or locked write as done; INTEGER sizes cap at 2 GB; a printer that never writes costs the full 30 s (Pdf_wait_seconds) sleeping on the calling (GUI) thread.
Fix: also try an exclusive open; make the wait a parameter; run it on a worker.

### L5. write_pdf leaves a broken file when cairo fails and no PDF printer exists
sw_print_job.e:194-209: delete_file runs before the fallback test only inside not Result, but when has_printer is False the 507-byte broken file from the failing backend is left at a_path. Delete on every failure path.

### L6. SHELL_PRINTER buffers and DEVMODE
shell_printer.e:221-241, simple_shell_print.h:44-72,89-96: the printer list is cut at 16384 UTF-16 units with no truncation flag (has_printer then says no for a printer that exists); Name_capacity 512 truncates long names; surrogate pairs are kept as two code points (documented). The merge DocumentPropertiesW result (line 96) is ignored, and dmPaperSize is set even if the driver lacks that paper (A4 on Letter-only printers prints Letter while the content is laid out for A4): compare paper_width to the setup after begin_document.

### L7. Test and evidence gaps
test_gw20_prints_through_the_file_printer depends on the Windows PDF printer (should skip when absent); evidence PNGs are committed; there is no test for dark or high-contrast preview (H1), side-by-side children (M4), print_to failure paths (H3, H4), or two documents in one process (H5).

## Checked and fine
- Zero-height or looping pagination: not reachable with the shipped overrides (M3 explains the residual risk).
- Theme invariants: make_light + set_surfaces(white, white, light variant, light outline, light ink, light muted) keeps ink_readable_on_surface (dark ink on white). The screen high-contrast or dark theme does not leak into the paper theme except through adopt_metrics_from (sizes, faces, text_scale; see M7).
- Unprintable offset sign: the DC origin is the printable corner, so the sheet origin is at -unprintable (sw_print_job.e:251): correct.
- EnumPrinters sizing call plus malloc and free paths, DEVMODE freed after CreateDC (header 104-105), AbortDoc/DeleteDC reset the statics: correct.

## Recommended order
1. H1 (visible wrong output), 2. H3 and H4 (leak plus silent failure on the only PDF route), 3. H2, 4. H5, 5. M10 and M7 and M8 (push up into SW_PAINTER, a paper theme, SW_PRINTABLE), 6. M1.
