note
	description: "[
		Assault on highlights INSIDE the editing widgets: a span laid
		over a word in SW_TEXT_BOX follows it through typing, deleting,
		selecting-and-cutting, pasting, undo and redo; the box paints
		it on both engines under a legend; and SW_PARAGRAPH_LIST keeps
		one marked text per paragraph, shares it with the in-place
		editor, restores it on cancel and carries it through insert,
		remove and move.
	]"

class
	SW_MARKED_EDIT_ASSAULT

inherit
	TEST_SET_BASE

feature -- Text box

	test_textbox_spans_follow_typing_and_undo
		local
			b: SW_TEXT_BOX
			w, before: INTEGER
			saved: STRING_32
		do
			create b.make ("hello world")
			w := b.marks.mark_range (6, 11, "word")
			b.set_caret (0)
			b.handle_char (('X').code)
			assert ("typing before shifts", b.marks.span (w).lo = 7 and b.marks.span (w).hi = 12)
			b.set_caret (9)
			b.handle_char (('Y').code)
			assert ("typing inside grows", b.marks.span (w).lo = 7 and b.marks.span (w).hi = 13)
			b.handle_char (8)
			assert ("backspace inside shrinks", b.marks.span (w).hi = 12)
			b.set_caret (7)
			b.handle_key (46, False)
			assert ("delete at the start trims from the left", b.marks.span (w).lo = 7 and b.marks.span (w).hi = 11)
			saved := b.marks.code
			before := b.marks.span (w).hi
			b.set_caret (0)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			assert ("nine selected", b.has_selection and b.caret = 9)
			b.cut_selection
			assert ("cut across the span trims it", b.marks.span (w).lo = 0 and b.marks.span (w).hi = before - 9)
			b.undo
			assert ("undo restores the span with the text", b.marks.code.same_string (saved))
			b.redo
			assert ("redo takes it away again", b.marks.span (w).lo = 0)
			b.undo
			b.select_all
			b.handle_char (8)
			assert ("deleting everything drops the span", b.marks.count = 0 and b.text.is_empty)
		end

	test_textbox_set_text_and_shared_marks
		local
			b: SW_TEXT_BOX
			shared: SW_MARKED_TEXT
		do
			create b.make ("one two three")
			if b.marks.mark_range (0, 3, "a") > 0 then end
			b.set_text ("four")
			assert ("set_text clears the marks", b.marks.count = 0 and b.marks.text_count = 4)
			create shared.make (4)
			if shared.mark_range (0, 4, "all") > 0 then end
			b.set_marks (shared)
			assert ("shared object", b.marks = shared)
			b.set_caret (4)
			b.handle_char (('!').code)
			assert ("edits reach the shared object", shared.text_count = 5 and shared.span (1).hi = 4)
		end

	test_textbox_paints_marks_both_engines
		local
			b: SW_TEXT_BOX
			lg: SW_MARK_LEGEND
			m: SW_MARK
			s: STRING_32
		do
			create s.make_from_string ("the quick brown ")
			s.append_code (0x05E9)
			s.append_code (0x05DC)
			s.append_code (0x05D5)
			s.append_code (0x05DD)
			s.append (" fox%Njumps over")
			create b.make (s)
			create lg.make
			create m.make ({SW_MARK}.Hue_red)
			lg.define ("pronounce", m.with_outline (1), "Say it this way")
			lg.set_badge ("pronounce", "P")
			create m.make ({SW_MARK}.Hue_teal)
			lg.define ("slow", m.with_wash.italic, "Slow down")
			create m.make ({SW_MARK}.Hue_amber)
			lg.define ("pause", m.with_box (2).bold.colorized, "Hold")
			b.set_legend (lg)
			if b.marks.mark_range (4, 9, "pronounce") > 0 then end
			if b.marks.mark_range (16, 20, "slow") > 0 then end
			if b.marks.mark_range (21, s.count, "pause") > 0 then end
			b.set_bounds (10.0, 10.0, 260.0, 90.0)
			b.set_focused (True)
			b.draw (plain_painter)
			b.draw (shaped_painter)
			assert ("the hebrew span is still there after painting", b.marks.count = 3)
			b.set_read_only (True)
			b.draw (shaped_painter)
			assert ("painted", True)
		end

feature -- Paragraph list

	test_paragraphs_share_marks_with_the_editor
		local
			l: SW_PARAGRAPH_LIST
			w: INTEGER
			lg: SW_MARK_LEGEND
			m: SW_MARK
		do
			create l.make (300.0)
			l.add ("first paragraph")
			l.add ("hello world here")
			l.add ("third")
			create lg.make
			create m.make ({SW_MARK}.Hue_blue)
			lg.define ("word", m.with_wash, "A word")
			l.set_legend (lg)
			w := l.marks_of (2).mark_range (6, 11, "word")
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			l.draw (plain_painter)
			l.draw (shaped_painter)
			l.begin_edit (2)
			assert ("editor shares the marks", attached l.editor as e and then e.marks = l.marks_of (2))
			assert ("editor knows the legend", attached l.editor as e2 and then e2.legend = lg)
			if attached l.editor as e3 then
				e3.set_caret (0)
			end
			l.handle_char (('Z').code)
			assert ("typing through the editor moved the span", l.marks_of (2).span (w).lo = 7)
			l.arrange (shaped_painter)
			l.draw (shaped_painter)
			l.handle_char (27)
			assert ("cancel restored the text", l.text_of (2).same_string ("hello world here"))
			assert ("and the marks", l.marks_of (2).span (w).lo = 6 and l.marks_of (2).span (w).hi = 11)
			l.begin_edit (2)
			if attached l.editor as e4 then
				e4.set_caret (0)
			end
			l.handle_char (('Q').code)
			l.end_edit (True)
			assert ("commit kept the moved span", l.marks_of (2).span (w).lo = 7)
			assert ("the shared object survived the editor", l.marks_of (2).text_count = 17)
		end

	test_paragraphs_marks_travel_with_mutation
		local
			l: SW_PARAGRAPH_LIST
			w: INTEGER
		do
			create l.make (300.0)
			l.add ("aaa")
			l.add ("bbb bbb")
			l.add ("ccc")
			w := l.marks_of (2).mark_range (4, 7, "x")
			l.insert (1, "new")
			assert ("insert shifted the paragraph, marks with it", l.marks_of (3).has (w))
			assert ("new paragraph has none", l.marks_of (1).count = 0)
			l.move (3, 1)
			assert ("move carried the marks", l.marks_of (1).has (w))
			l.remove (1)
			assert ("remove took them", not l.marks_of (1).has (w))
			l.put_text (2, "b")
			assert ("put_text clamps", l.marks_of (2).text_count = 1)
			l.wipe_out
			assert ("wiped", l.count = 0)
		end

feature {NONE} -- Fixture

	plain_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (600, 400)
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
			create surf.make (600, 400)
			create ctx.make (surf)
			create th.make_dark
			create kit.make
			kit.set_theme_faces (th)
			create Result.make (ctx, th)
			Result.set_shaping (kit)
		end

end
