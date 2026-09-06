note
	description: "[
		Assault on the highlight model: a mark's code round-trips
		every aspect; the palette's twelve hues keep text readable on
		BOTH shipped themes (the WCAG postconditions fire under -keep);
		a legend re-themes a reason; marked text remembers, restyles,
		removes, and FOLLOWS the text as it is edited; the geometry
		merges a range into per-line segments; and the painter paints
		every aspect headless on both engines without raising.
	]"

class
	SW_MARK_ASSAULT

inherit
	TEST_SET_BASE

feature -- Mark

	test_mark_code_round_trip
		local
			m, back: SW_MARK
			plain: SW_MARK
		do
			create m.make ({SW_MARK}.Hue_teal)
			assert ("plain at birth", m.is_plain)
			m := m.with_wash.with_box (2).with_outline (1).colorized.bold.italic
			assert ("code names every aspect", m.code.same_string ("7:FB2O1Cbi"))
			create back.make_from_code (m.code)
			assert ("round trip", back.same_mark (m))
			assert ("changes glyphs", m.changes_glyphs)
			create plain.make (1)
			assert_false ("plain changes nothing", plain.changes_glyphs)
			assert ("plain code", plain.code.same_string ("1:"))
			assert_false ("hue 13 refused", plain.is_valid_code ("13:F"))
			assert_false ("no hue refused", plain.is_valid_code ("F"))
			assert_false ("four box lines refused", plain.is_valid_code ("7:B4"))
			assert_false ("three outlines refused", plain.is_valid_code ("7:O3"))
			assert ("twin is equal and distinct", m.twin_mark.same_mark (m) and m.twin_mark /= m)
		end

	test_palette_readable_on_both_themes
			-- Every ink at 3:1 on the surface, every wash at 4.5:1
			-- under the ink - the postconditions run under -keep, so
			-- calling each pair on each theme IS the proof.
		local
			pal: SW_MARK_PALETTE
			light, dark: SW_THEME
			h: INTEGER
			c: NATURAL_32
		do
			create pal
			create light.make_light
			create dark.make_dark
			assert_false ("light is light", pal.is_dark (light))
			assert ("dark is dark", pal.is_dark (dark))
			from h := 1 until h > pal.Hue_count loop
				c := pal.ink (h, light)
				c := pal.wash (h, light)
				c := pal.ink (h, dark)
				c := pal.wash (h, dark)
				assert ("named " + h.out, not pal.name (h).is_empty)
				h := h + 1
			end
			assert ("light and dark differ", pal.ink (1, light) /= pal.ink (1, dark))
		end

	test_legend_defines_and_rethemes
		local
			lg: SW_MARK_LEGEND
			a, b: SW_MARK
		do
			create lg.make
			create a.make ({SW_MARK}.Hue_red)
			a := a.with_outline (1)
			create b.make ({SW_MARK}.Hue_amber)
			b := b.with_wash
			lg.define ("spelling", a, "Possible misspelling")
			lg.define ("stale", b, "Audio older than the text")
			assert_integers_equal ("two reasons", 2, lg.count)
			assert ("known", lg.has ("spelling"))
			assert ("looks red", attached lg.mark_of ("spelling") as m and then m = a)
			assert ("labelled", lg.label_of ("stale").same_string ("Audio older than the text"))
			assert ("unknown answers its key", lg.label_of ("other").same_string ("other"))
			assert ("unknown has no look", lg.mark_of ("other") = Void)
			lg.set_mark ("stale", a)
			assert ("re-themed", attached lg.mark_of ("stale") as m2 and then m2 = a)
			assert ("no badge yet", lg.badge_of ("stale").is_empty)
			lg.set_badge ("stale", "S")
			assert ("badge worn", lg.badge_of ("stale").same_string ("S"))
			lg.define ("stale", b, "Stale audio")
			assert ("redefining keeps the badge", lg.badge_of ("stale").same_string ("S"))
			assert ("unknown has no badge", lg.badge_of ("other").is_empty)
			assert ("order kept", lg.keys.first.same_string ("spelling") and lg.keys.last.same_string ("stale"))
			lg.remove ("spelling")
			assert_integers_equal ("one left", 1, lg.count)
		end

feature -- Marked text

	test_marked_text_mark_remove_restyle
		local
			mt, dup: SW_MARKED_TEXT
			a, b: INTEGER
			m: SW_MARK
		do
			create mt.make (11)
			a := mt.mark_range (0, 5, "word")
			b := mt.mark_range (2, 9, "phrase")
			assert_integers_equal ("two", 2, mt.count)
			assert ("ids climb", b > a)
			assert_integers_equal ("both cover char 3, bottom first", a, mt.spans_at (3).first.id)
			assert_integers_equal ("phrase on top", b, mt.spans_at (3).last.id)
			assert ("char 11 bare", not mt.is_marked (11))
			create m.make (3)
			m := m.with_wash
			mt.restyle (a, m)
			assert ("restyled", mt.span (a).mark = m)
			mt.rereason (b, "emphasis")
			assert ("rereasoned", mt.span (b).reason.same_string ("emphasis"))
			mt.set_range (b, 6, 11)
			assert ("resized", mt.span (b).lo = 6 and mt.span (b).hi = 11)
			mt.span (a).set_annotation ("checked by ear")
			dup := mt.duplicate
			assert ("duplicate keeps everything", dup.count = 2 and dup.span (a).annotation.same_string ("checked by ear")
				and attached dup.span (a).mark as dm and then dm.same_mark (m))
			assert ("duplicate is independent", dup.span (a) /= mt.span (a))
			assert ("reasons distinct", mt.reasons.count = 2)
			mt.remove_at (1)
			assert_integers_equal ("word gone", 1, mt.count)
			mt.remove_reason ("emphasis")
			assert_integers_equal ("empty", 0, mt.count)
			assert ("codec of nothing", mt.code.is_empty)
		end

	test_marked_text_codec_and_unresolved
		local
			mt, back: SW_MARKED_TEXT
			lg: SW_MARK_LEGEND
			m: SW_MARK
			id: INTEGER
		do
			create mt.make (20)
			id := mt.mark_range (3, 8, "pronounce")
			mt.span (id).set_annotation ("koh-DESH")
			create m.make ({SW_MARK}.Hue_violet)
			id := mt.mark_range_with (10, 15, "slow", m.with_box (1).italic)
			create back.make_from_code (20, mt.code)
			assert_integers_equal ("two back", 2, back.count)
			assert ("note back", back.span (1).annotation.same_string ("koh-DESH"))
			assert ("explicit mark back", attached back.span (2).mark as bm and then bm.code.same_string ("11:B1i"))
			assert ("ids continue past the highest", back.mark_range (0, 1, "x") = 3)
			create lg.make
			lg.define ("pronounce", m, "Say it this way")
			assert ("slow has its own mark, pronounce is known", mt.unresolved (lg).is_empty)
			mt.rereason (1, "mystery")
			assert ("mystery is unresolved", mt.unresolved (lg).count = 1 and mt.unresolved (lg).first.same_string ("mystery"))
			create back.make_from_code (5, "garbage%N1|0|9|ok|x|%N")
			assert ("bad lines skipped, good one clamped", back.count = 1 and back.span (1).hi = 5)
		end

	test_marked_text_follows_edits
		local
			mt: SW_MARKED_TEXT
			w: INTEGER
		do
				-- "hello world": world is 6 .. 11
			create mt.make (11)
			w := mt.mark_range (6, 11, "word")
			mt.text_inserted (0, 3)
			assert ("insert before shifts", mt.span (w).lo = 9 and mt.span (w).hi = 14)
			mt.text_inserted (9, 2)
			assert ("insert AT the start shifts, does not grow", mt.span (w).lo = 11 and mt.span (w).hi = 16)
			mt.text_inserted (13, 4)
			assert ("insert inside grows", mt.span (w).lo = 11 and mt.span (w).hi = 20)
			mt.text_inserted (20, 3)
			assert ("insert at the end does not grow", mt.span (w).hi = 20)
			assert_integers_equal ("text grew", 23, mt.text_count)
			mt.text_removed (0, 2)
			assert ("remove before shifts", mt.span (w).lo = 9 and mt.span (w).hi = 18)
			mt.text_removed (7, 12)
			assert ("remove across the start trims", mt.span (w).lo = 7 and mt.span (w).hi = 13)
			mt.text_removed (10, 15)
			assert ("remove across the end trims", mt.span (w).lo = 7 and mt.span (w).hi = 10)
			mt.text_removed (8, 9)
			assert ("remove inside shrinks", mt.span (w).lo = 7 and mt.span (w).hi = 9)
			mt.text_removed (6, 10)
			assert ("remove the whole span drops it", not mt.has (w))
				-- 23 - 2 - 5 - 5 - 1 - 4
			assert_integers_equal ("size tracked", 6, mt.text_count)
			w := mt.mark_range (2, 6, "tail")
			mt.clamp_to (4)
			assert ("clamp trims", mt.span (w).hi = 4)
			mt.clamp_to (2)
			assert ("clamp drops what is past the end", not mt.has (w))
		end

feature -- Geometry

	test_geometry_segments_merge_per_line
		local
			g: SW_TEXT_GEOMETRY
			segs: ARRAYED_LIST [TUPLE [line: INTEGER; left, width: REAL_64]]
		do
			create g.make
			plain_painter.font ({SW_PAINTER}.Role_body, plain_painter.theme.size_body, False)
			g.build_toy (plain_painter, {STRING_32} "abc def%Nghi", 1000.0, False, False)
			assert_integers_equal ("eleven slots", 11, g.count)
			assert_integers_equal ("two lines", 2, g.line_count)
			assert ("break slot", g.is_break (8))
			segs := g.segments (1, 10)
			assert_integers_equal ("one segment per line", 2, segs.count)
			assert_integers_equal ("first on line 0", 0, segs.first.line)
			assert_integers_equal ("second on line 1", 1, segs.last.line)
			assert ("first starts at b", segs.first.left = g.x_of (2))
			assert ("first ends at f", (segs.first.left + segs.first.width - (g.x_of (7) + g.width_of (7))).abs < 1.0e-9)
			assert ("second starts at line start", segs.last.left = 0.0)
			assert ("caret after the break is on line 1 at 0", g.line_at_offset (8) = 1 and g.x_at_offset (8) = 0.0)
			assert ("round trip", g.offset_at (g.x_at_offset (5), g.top_of_line (0) + 1.0) = 5)
		end

feature -- Painter

	test_painter_paints_every_aspect_headless
		local
			g: SW_TEXT_GEOMETRY
			mt: SW_MARKED_TEXT
			lg: SW_MARK_LEGEND
			mp: SW_MARK_PAINTER
			m: SW_MARK
			s: STRING_32
			h: INTEGER
		do
			s := {STRING_32} "the quick brown fox jumps over the lazy dog and keeps going"
			create mt.make (s.count)
			create lg.make
			from h := 1 until h > 12 loop
				create m.make (h)
				inspect h \\ 6
				when 0 then
					m := m.with_wash
				when 1 then
					m := m.with_box (h \\ 3 + 1)
				when 2 then
					m := m.with_outline (h \\ 2 + 1)
				when 3 then
					m := m.colorized.bold
				when 4 then
					m := m.italic.with_wash
				else
					m := m.with_wash.with_box (3).with_outline (2).colorized.bold.italic
				end
				lg.define ("r" + h.out, m, "reason " + h.out)
				if mt.mark_range ((h - 1) * 4, (h - 1) * 4 + 6, "r" + h.out) > 0 then end
				h := h + 1
			end
			create mp.make
				-- toy
			create g.make
			plain_painter.font ({SW_PAINTER}.Role_body, plain_painter.theme.size_body, False)
			g.build_toy (plain_painter, s, 220.0, False, False)
			assert ("wrapped", g.line_count > 1)
			mp.paint_under (plain_painter, g, mt, lg, 10.0, 10.0)
			lg.set_badge ("r1", "P")
			lg.set_badge ("r5", "sl")
			mp.paint_over (plain_painter, g, mt, lg, 10.0, 10.0, 14.0, agent draw_toy (s, g, ?, ?, ?))
				-- the size policy: small type gets less
			assert ("effects at 14", mp.effects_allowed (14.0))
			assert_false ("no effects at 9", mp.effects_allowed (9.0))
			assert ("marks at 9", mp.marks_allowed (9.0))
			assert_false ("nothing at 5", mp.marks_allowed (5.0))
			assert_false ("no badges at 11", mp.badges_allowed (11.0))
			mp.paint_over (plain_painter, g, mt, lg, 10.0, 10.0, 9.0, agent draw_toy (s, g, ?, ?, ?))
			mp.paint_over (plain_painter, g, mt, lg, 10.0, 10.0, 5.0, agent draw_toy (s, g, ?, ?, ?))
			mp.set_floors (4.0, 8.0, 10.0)
			assert ("floors moved", mp.effects_allowed (9.0) and mp.marks_allowed (5.0))
				-- shaped
			create g.make
			if attached shaped_painter.shaping as kit then
				g.build_shaped (kit, s, 220, 14, False)
				assert ("shaped", g.is_shaped)
				mp.paint_under (shaped_painter, g, mt, lg, 10.0, 10.0)
				mp.paint_over (shaped_painter, g, mt, lg, 10.0, 10.0, 14.0, agent draw_shaped (g, ?, ?, ?))
			end
			assert ("painted every aspect on both engines", True)
		end

feature -- Legend view

	test_legend_view_draws_and_picks
		local
			lg: SW_MARK_LEGEND
			v: SW_MARK_LEGEND_VIEW
			m: SW_MARK
		do
			create lg.make
			create m.make ({SW_MARK}.Hue_red)
			lg.define ("pronounce", m.with_outline (1), "Say it this way")
			lg.set_badge ("pronounce", "P")
			create m.make ({SW_MARK}.Hue_teal)
			lg.define ("slow", m.with_wash.italic, "Slow down")
			create m.make ({SW_MARK}.Hue_amber)
			lg.define ("pause", m.with_box (2).bold, "Hold after")
			create v.make (lg)
			v.set_on_pick (agent record_pick)
			v.set_bounds (0.0, 0.0, 260.0, v.preferred_height (plain_painter, 260.0))
			assert ("three rows tall", v.height >= 3.0 * v.row_h)
			v.draw (plain_painter)
			v.draw (shaped_painter)
			assert_integers_equal ("row 2 under its own y", 2, v.row_at (v.Pad + v.row_h * 1.5))
			assert_integers_equal ("nothing below the rows", 0, v.row_at (v.Pad + v.row_h * 3.5))
			assert ("click taken", v.handle_click (30.0, v.Pad + v.row_h * 2.5))
			assert ("picked the third reason", picked.same_string ("pause"))
		end

feature {NONE} -- Capture

	picked: STRING_32
		attribute
			create Result.make_empty
		end

	record_pick (a_reason: STRING_32)
		do
			picked := a_reason.twin
		end

feature {NONE} -- Text drawers

	draw_toy (a_s: STRING_32; a_g: SW_TEXT_GEOMETRY; a_p: SW_PAINTER; a_dx, a_dy: REAL_64)
		local
			i: INTEGER
		do
			a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
			from i := 1 until i > a_g.count loop
				if not a_g.is_break (i) then
					a_p.text (10.0 + a_dx + a_g.x_of (i),
						10.0 + a_dy + a_g.top_of_line (a_g.line_of (i)) + a_g.ascent_of_line (a_g.line_of (i)),
						a_s.substring (i, i))
				end
				i := i + 1
			end
		end

	draw_shaped (a_g: SW_TEXT_GEOMETRY; a_p: SW_PAINTER; a_dx, a_dy: REAL_64)
		local
			i: INTEGER
		do
			from i := 1 until i > a_g.layouts.count loop
				a_p.draw_shaped_layout (a_g.layouts.i_th (i), 10.0 + a_dx, 10.0 + a_dy + a_g.para_tops.i_th (i))
				i := i + 1
			end
		end

feature {NONE} -- Fixture

	plain_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (400, 300)
			create ctx.make (surf)
			create th.make_light
			create Result.make (ctx, th)
		end

	shaped_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			kit: SW_SHAPING
		once
			create surf.make (400, 300)
			create ctx.make (surf)
			create th.make_dark
			create kit.make
			kit.set_theme_faces (th)
			create Result.make (ctx, th)
			Result.set_shaping (kit)
		end

end
