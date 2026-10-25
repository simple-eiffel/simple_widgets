note
	description: "[
		Assault on GW-13, the rich document: a simple_document DOC_TEXT
		flattened for the shaper (SW_DOC_STYLES), and SW_DOCUMENT_VIEW - layout, pointing, links, selection
		across blocks and cells, spacing from the theme, a long document,
		and the Hebrew and Greek gate in both themes (evidence
		gw13_document_light.png and gw13_document_dark.png). Inherits the
		shaping assault for its scripture fixtures and its kit.
	]"

class
	SW_DOCUMENT_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- The model

	test_gw13_rich_text_flattens_for_the_shaper
			-- Overlapping spans become one setting per stretch: bold, bold
			-- italic, italic link, link.
		local
			r: DOC_TEXT
			s: SHAPING_STYLES
		do
			create r.make ("abcdefghijklmnop")
			r.add_bold (1, 8)
			r.add_italic (5, 8)
			r.add_link (10, 5, "John 3:16")
			s := (create {SW_DOC_STYLES}).styles_of (r)
			assert_integers_equal ("bold at 1", 700, s.weight_at (1))
			assert_false ("not italic at 1", s.is_italic_at (1))
			assert_true ("bold italic at 6", s.weight_at (6) = 700 and s.is_italic_at (6))
			assert_true ("italic link at 11", s.weight_at (11) = 0 and s.is_italic_at (11) and s.ink_at (11) = {DOC_TEXT}.Flag_link)
			assert_true ("link alone at 14", s.ink_at (14) = {DOC_TEXT}.Flag_link and not s.is_italic_at (14))
			assert_integers_equal ("plain after", 0, s.ink_at (15) + s.weight_at (15))
			assert_integers_equal ("the link is found", 3, r.link_at (12))
			assert_true ("its target kept", r.span_target (3).same_string ("John 3:16"))
			r.set_text ("abcdefghij")
			assert_integers_equal ("the link past the end was cut to it", 1, r.span_length (3))
			r.set_text ("abc")
			assert_integers_equal ("spans past the end went", 1, r.span_count)
			create r.make ("plain")
			assert_true ("no spans, no styles", (create {SW_DOC_STYLES}).styles_of (r).is_empty)
		end

feature -- The view

	test_gw13_view_points_links_and_selects
			-- A laid-out view answers which unit and character are under a
			-- point, follows a link on press and release, shows a hand over
			-- it, and copies a selection across blocks and table cells.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			b: TUPLE [x, y, width, height: REAL_64]
			mx, my: REAL_64
			l_expected: STRING_32
		do
			create w.make ("doc", 0, 0, 700, 500, create {SW_THEME}.make_light)
			attach_kit (w)
			v := sample_view
			v.set_on_link_click (agent note_link)
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_integers_equal ("units: four texts and four cells", 8, v.unit_count)
			assert_integers_equal ("unit 5 is a cell", 5, v.unit_block (5))
			assert_true ("in row 1, column 1", v.unit_row (5) = 1 and v.unit_column (5) = 1)
			b := v.text_boxes (2, 0, 1).first
			assert_integers_equal ("unit 2 under its first letter", 2, v.pointed_item (b.x + 1.0, b.y + 1.0))
			assert_integers_equal ("its first character", 1, v.character_at (b.x + b.width / 2.0, b.y + b.height / 2.0))
				-- The link: "John 3:16" at 33 .. 41 of unit 2.
			b := v.text_boxes (2, 32, 41).first
			mx := b.x + b.width / 2.0
			my := b.y + b.height / 2.0
			v.set_hover_point (mx, my)
			assert_true ("the hovered link", v.hovered_link.same_string ("John 3:16"))
			assert_integers_equal ("a hand over it", 2, v.cursor_kind)
			last_link := Void
			assert_true ("the press is taken", v.handle_click (mx, my))
			v.handle_release (mx.truncated_to_integer, my.truncated_to_integer)
			assert_true ("the release followed the link",
				attached last_link as al_l and then al_l.same_string ("John 3:16"))
				-- Selection: from the heading's 3rd character into the
				-- paragraph, and a table row.
			v.select_range (1, 2, 2, 3)
			create l_expected.make_from_string ("mmentary%NFor")
			assert_strings_equal ("across blocks", l_expected, v.selected_text)
			v.select_range (7, 0, 8, 6)
			assert_strings_equal ("a row's cells joined by a tab", {STRING_32} "bara%Tcreate", v.selected_text)
			v.handle_char (27)
			assert_false ("Escape clears", v.has_selection)
			v.handle_char (1)
			assert_true ("Ctrl+A selects all", v.has_selection and v.anchor_item = 1 and v.caret_item = 8)
		end

	test_gw13_bold_and_links_reach_the_shaper
			-- The paragraph's bold word is laid out in a bold face; a press
			-- and drag selects; the drag never follows a link.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			b1: TUPLE [x, y, width, height: REAL_64]
		do
			create w.make ("doc", 0, 0, 700, 500, create {SW_THEME}.make_light)
			attach_kit (w)
			v := sample_view
			v.set_on_link_click (agent note_link)
			w.set_root (v)
			w.request_render
			assert_integers_equal ("God is set bold", 700, run_weight (v.unit_geometry (2), 5))
			assert_integers_equal ("For is not", 400, run_weight (v.unit_geometry (2), 1))
			last_link := Void
			b1 := v.text_boxes (2, 32, 33).first
			assert_true ("press on the link", v.handle_click (b1.x + 1.0, b1.y + 2.0))
			v.handle_drag (b1.x + 60.0, b1.y + 2.0)
			v.handle_release ((b1.x + 60.0).truncated_to_integer, (b1.y + 2.0).truncated_to_integer)
			assert_true ("a drag selects", v.has_selection)
			assert_true ("and does not follow the link", last_link = Void)
		end

	test_gw13_spacing_follows_the_theme
			-- The page inset is border_width, a level-1 list item is indented
			-- twice that, a heading after the first block takes border_width
			-- above it; at 2x text all of it doubles.
		local
			w1, w2: SW_WINDOW
			v1, v2: SW_DOCUMENT_VIEW
			t2: SW_THEME
		do
			create w1.make ("doc", 0, 0, 700, 500, create {SW_THEME}.make_light)
			attach_kit (w1)
			v1 := sample_view
			w1.set_root (v1)
			w1.request_render
			create t2.make_light
			t2.set_text_scale (2.0)
			create w2.make ("doc", 0, 0, 1400, 1000, t2)
			attach_kit (w2)
			v2 := sample_view
			w2.set_root (v2)
			w2.request_render
			assert_reals_equal ("the page inset is the border", w1.theme.border_width, v1.content_pad, 0.000_1)
			assert_reals_equal ("and doubles", 2.0 * v1.content_pad, v2.content_pad, 0.000_1)
			assert_reals_equal ("a level-1 item is indented two borders",
				2.0 * w1.theme.border_width, v1.unit_origin_x (3) - v1.x - v1.content_pad, 0.000_1)
			assert_reals_equal ("the indent doubles",
				2.0 * (v1.unit_origin_x (3) - v1.x - v1.content_pad), v2.unit_origin_x (3) - v2.x - v2.content_pad, 0.000_1)
			assert_true ("blocks a padding apart",
				(v1.block_top (2) - (v1.block_top (1) + v1.block_height (1)) - w1.theme.padding).abs < 0.000_1)
		end

	test_gw13_long_document_scrolls
			-- Three hundred paragraphs: only a band is drawn, the end can be
			-- reached, and the block under a point is found there.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
			i: INTEGER
		do
			create w.make ("doc", 0, 0, 500, 400, create {SW_THEME}.make_light)
			attach_kit (w)
			create d.make
			from i := 1 until i > 300 loop
				d.add_paragraph ("Paragraph " + i.out + " of a long commentary.").do_nothing
				i := i + 1
			end
			create v.make (400.0)
			v.set_document (d)
			w.set_root (v)
			w.request_render
			assert_true ("overflows", v.max_scroll > 0.0)
			assert_integers_equal ("starts at the top", 1, v.first_visible)
			assert_true ("only a band is visible", v.last_visible < 40)
			v.scroll_to (v.max_scroll)
			w.request_render
			assert_integers_equal ("the end reached", 300, v.last_visible)
			assert_integers_equal ("the last paragraph under the last text line", 300,
				v.unit_block (v.pointed_item (v.unit_origin_x (300) + 2.0, v.unit_origin_y (300) + 2.0)))
			assert_true ("a wheel notch up moves", v.handle_wheel (120) and v.scroll_y < v.max_scroll)
		end

	test_empty_paragraph_stands_a_line_tall
			-- On the shaped path an empty paragraph is as tall as one holding
			-- a single letter, so typing the first character never makes it
			-- jump (SW_TEXT_GEOMETRY.lay_out floors at one line).
		local
			w: SW_WINDOW
			l: SW_PARAGRAPH_LIST
		do
			create w.make ("empty", 0, 0, 500, 300, create {SW_THEME}.make_light)
			attach_kit (w)
			create l.make (280.0)
			l.add ("")
			l.add ("x")
			w.set_root (l)
			w.request_render
			assert_true ("shaped", l.is_shaped_layout)
			assert_reals_equal ("empty is as tall as one letter", l.item_height (2), l.item_height (1), 0.000_1)
		end

	test_paragraph_spacing_scales
			-- The paragraph list's gap, padding and gutter scale with the
			-- text, as the theme's tokens do: at 2x the gap between two
			-- paragraphs and the text's inset double.
		local
			w1, w2: SW_WINDOW
			l1, l2: SW_PARAGRAPH_LIST
			t2: SW_THEME
		do
			create w1.make ("s1", 0, 0, 600, 400, create {SW_THEME}.make_light)
			attach_kit (w1)
			create t2.make_light
			t2.set_text_scale (2.0)
			create w2.make ("s2", 0, 0, 1200, 800, t2)
			attach_kit (w2)
			create l1.make (380.0)
			create l2.make (780.0)
			l1.add ("one")
			l1.add ("two")
			l2.add ("one")
			l2.add ("two")
			w1.set_root (l1)
			w2.set_root (l2)
			w1.request_render
			w2.request_render
			assert_reals_equal ("the gap at 1x is the item gap", l1.item_gap,
				l1.item_top (2) - l1.item_top (1) - l1.item_height (1), 0.000_1)
			assert_reals_equal ("and doubles at 2x", 2.0 * l1.item_gap,
				l2.item_top (2) - l2.item_top (1) - l2.item_height (1), 0.000_1)
			assert_reals_equal ("the text inset doubles", 2.0 * (l1.item_text_x (1) - l1.x), l2.item_text_x (1) - l2.x, 0.000_1)
		end

feature -- Hebrew and Greek, both themes

	test_gw13_document_light
		do
			document_gate (create {SW_THEME}.make_light, "gw13_document_light.png")
		end

	test_gw13_document_dark
		do
			document_gate (create {SW_THEME}.make_dark, "gw13_document_dark.png")
		end

feature -- Live preview (editing)

	test_gw13_edit_shows_the_source_and_keeps_it
			-- A click opens a block's Markdown in the box over it; typing and
			-- a click on another block keep the edit, read back with its
			-- spans; Escape drops an edit.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			l_heading: STRING_32
		do
			create w.make ("edit", 0, 0, 700, 500, create {SW_THEME}.make_light)
			attach_kit (w)
			v := notes_view
			w.set_root (v)
			w.request_render
			assert_true ("editable", v.is_editable)
			assert_true ("the press is taken", v.handle_click (v.x + 40.0, v.block_top (2) + 4.0))
			assert_true ("editing block 2", v.is_editing and v.editing_index = 2)
			if attached v.editor as al_ed then
				assert_strings_equal ("its Markdown", {STRING_32} "In the **beginning** God created; see [John 1:1](John 1:1).", al_ed.text)
				w.request_render
				assert_true ("the box sits on the block", (al_ed.y + al_ed.Pad_y - v.block_top (2)).abs < 1.0)
			end
			type_into_view (v, " **Amen**")
			l_heading := v.document.block (1).content.text.twin
			assert_true ("the next block's press is taken", v.handle_click (v.x + 40.0, v.block_top (1) + 4.0))
			assert_strings_equal ("the edit kept and read back", {STRING_32} "In the beginning God created; see John 1:1. Amen",
				v.document.block (2).content.text)
			assert_true ("Amen is bold", v.document.block (2).content.has_kind_at ({DOC_TEXT}.Kind_bold,
				v.document.block (2).content.count))
			assert_true ("the link still a link", v.document.block (2).content.link_count = 1)
			assert_integers_equal ("one document change", 1, changes)
			assert_true ("now editing the heading", v.editing_index = 1)
			type_into_view (v, " changed")
			v.handle_char (27)
			assert_false ("Escape ends the edit", v.is_editing)
			assert_strings_equal ("and drops it", l_heading, v.document.block (1).content.text)
			assert_integers_equal ("no further change", 1, changes)
		end

	test_gw13_edit_splits_removes_and_adds
			-- The source may read as two blocks, or none; Ctrl+Enter keeps the
			-- edit and opens a paragraph after it; a click below the last
			-- block opens a new one at the end.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			k: SW_KEYS
			n: INTEGER
		do
			create w.make ("edit", 0, 0, 700, 500, create {SW_THEME}.make_light)
			attach_kit (w)
			v := notes_view
			w.set_root (v)
			w.request_render
			n := v.document.count
			v.begin_edit (2)
			if attached v.editor as al_ed then
				al_ed.set_text ("## Head%N%NPara one")
			end
			v.end_edit (True)
			assert_integers_equal ("one block became two", n + 1, v.document.count)
			assert_true ("a level-2 heading", v.document.block (2).kind = {DOC_BLOCK}.Kind_heading and v.document.block (2).level = 2)
			assert_strings_equal ("then the paragraph", {STRING_32} "Para one", v.document.block (3).content.text)
			v.begin_edit (3)
			if attached v.editor as al_ed2 then
				al_ed2.set_text ("")
			end
			v.end_edit (True)
			assert_integers_equal ("emptied, the block went", n, v.document.count)
			w.request_render
			v.begin_edit (2)
			create k
			k.simulate (False, True, False)
			v.handle_key (13, False)
			k.simulate (False, False, False)
			assert_integers_equal ("Ctrl+Enter added a paragraph", n + 1, v.document.count)
			assert_true ("after the edited block, and open", v.is_editing and v.editing_index = 3
				and v.document.block (3).content.count = 0)
			v.handle_char (27)
			w.request_render
			assert_true ("below the last block", v.handle_click (v.x + 40.0,
				v.block_top (v.document.count) + v.block_height (v.document.count) + 20.0))
			assert_integers_equal ("a new paragraph at the end", n + 2, v.document.count)
			assert_true ("open for editing", v.is_editing and v.editing_index = v.document.count)
		end

	test_gw13_ctrl_click_follows_while_editable
			-- While editable a plain click on a link edits its block, and a
			-- Ctrl+click follows the link.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			b: TUPLE [x, y, width, height: REAL_64]
			k: SW_KEYS
		do
			create w.make ("edit", 0, 0, 700, 500, create {SW_THEME}.make_light)
			attach_kit (w)
			v := notes_view
			v.set_on_link_click (agent note_link)
			w.set_root (v)
			w.request_render
			b := v.text_boxes (2, 38, 39).first
			last_link := Void
			create k
			k.simulate (False, True, False)
			assert_true ("Ctrl+click taken", v.handle_click (b.x + 1.0, b.y + 2.0))
			k.simulate (False, False, False)
			assert_true ("the link followed", attached last_link as al_l and then al_l.same_string ("John 1:1"))
			assert_false ("no edit opened", v.is_editing)
			assert_true ("a plain click", v.handle_click (b.x + 1.0, b.y + 2.0))
			assert_true ("edits the block", v.is_editing and v.editing_index = 2)
		end

	test_gw13_hebrew_and_greek_are_not_misspelled
			-- The checker reads in a Latin-script language: Hebrew and Greek
			-- words are never findings, whatever it says of them.
		local
			sp: SW_SPELLER
			t: STRING_32
		do
			create sp
			t := {STRING_32} "teh " + genesis_first_word + {STRING_32} " and " + john_first_words + {STRING_32} " recieve"
			assert_true ("Hebrew is another script", sp.has_other_script (t, 5, 4 + genesis_first_word.count))
			assert_false ("English is not", sp.has_other_script (t, 1, 3))
			assert_false ("nor Latin with marks", sp.has_other_script ({STRING_32} "caf%/233/ na%/239/ve", 1, 10))
			across sp.misspellings (t) as r loop
				assert_false ("no finding inside the Hebrew or the Greek", sp.has_other_script (t, r.lo + 1, r.hi))
			end
		end

	test_gw13_editing_light
		do
			editing_gate (create {SW_THEME}.make_light, "gw13_editing_light.png")
		end

	test_gw13_editing_dark
		do
			editing_gate (create {SW_THEME}.make_dark, "gw13_editing_dark.png")
		end

feature {NONE} -- Fixtures

	last_link: detachable STRING_32
			-- The target the last link click reported.

	note_link (a_target: STRING_32)
		do
			last_link := a_target
		end

	attach_kit (a_window: SW_WINDOW)
			-- A shaping kit on `a_window', its faces the theme's.
		local
			kit: SW_SHAPING
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_window.theme)
			a_window.set_shaping (kit)
		end

	sample_view: SW_DOCUMENT_VIEW
			-- A heading, a paragraph with a bold word and a link, two
			-- bullets, and a two-by-two table.
		local
			d: SIMPLE_DOCUMENT
			r: DOC_TEXT
			t: DOC_BLOCK
		do
			create d.make
			d.add_heading (1, "Commentary").do_nothing
			r := d.add_paragraph ("For God so loved the world; see John 3:16 and read on.")
			r.add_bold (5, 3)
			r.add_link (33, 9, "John 3:16")
			d.add_bullet (1, "In the beginning").do_nothing
			d.add_bullet (1, "the Word").do_nothing
			t := d.add_table (<<"Word", "Gloss">>)
			t.add_row (<<"bara", "create">>)
			create Result.make (480.0)
			Result.set_document (d)
		end

	document_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- A lexicon-style document: a heading, pointed Genesis 1:1 with
			-- cantillation, polytonic John 1:1, a mixed English and Hebrew
			-- line with a link, a Hebrew bullet, a quote, a rule and a
			-- table with Hebrew and Greek cells. The Hebrew reads right to
			-- left flush right, nothing is skipped, and the evidence PNG is
			-- written for a person to look at.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
			r: DOC_TEXT
			t: DOC_BLOCK
			b: TUPLE [x, y, width, height: REAL_64]
			path: STRING_32
		do
			create w.make ("gw13", 0, 0, 760, 640, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			create d.make
			d.add_heading (1, "Genesis 1:1 and John 1:1").do_nothing
			d.add_paragraph (genesis_1_1_wlc).do_nothing
			d.add_paragraph (john_1_1_wh).do_nothing
			r := d.add_paragraph (mixed_english_hebrew)
			r.add_link (1, 11, "Gen 1:1")
			r := d.add_paragraph ("In the beginning God created; compare John 1:1 and Proverbs 8:22.")
			r.add_bold (1, 16)
			r.add_italic (18, 3)
			r.add_link (39, 8, "John 1:1")
			r.add_link (52, 13, "Prov 8:22")
			d.add_heading (2, "Senses").do_nothing
			d.add_bullet (1, genesis_first_word).do_nothing
			d.add_numbered (1, "to create, of God alone").do_nothing
			d.add_numbered (1, "to shape, to form").do_nothing
			d.add_quote (1, "The verb is used only of divine activity.").do_nothing
			d.add_rule
			t := d.add_table (<<"Hebrew", "Greek", "Gloss">>)
			t.add_row (<<genesis_first_word, john_first_words, "in the beginning">>)
			create v.make (640.0)
			v.set_document (d)
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_true ("the Hebrew paragraph reads right to left", v.text_boxes (2, 0, 1).count = 1)
			b := v.text_boxes (2, 0, 1).first
			assert_true ("its first letter stands at the right of the page",
				b.x + b.width > v.x + v.width - v.content_pad - v.bar.bar_width - 40.0)
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_true ("runs painted", kit.bridge.painted_runs > 20)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

	run_weight (a_geometry: SW_TEXT_GEOMETRY; a_character: INTEGER): INTEGER
			-- The weight of the glyph run over `a_character' of the first
			-- layout; 0 when none covers it.
		do
			if not a_geometry.layouts.is_empty then
				across a_geometry.layouts.first.lines as ln loop
					across ln.runs as rn loop
						if attached {GLYPH_RUN} rn as al_g and then a_character >= al_g.source_start
							and then a_character < al_g.source_start + al_g.source_count
						then
							Result := al_g.font.weight
						end
					end
				end
			end
		end

	changes: INTEGER
			-- Document changes heard.

	note_change
		do
			changes := changes + 1
		end

	notes_view: SW_DOCUMENT_VIEW
			-- An editable view of a short Markdown note.
		do
			changes := 0
			create Result.make (480.0)
			Result.set_document ((create {SIMPLE_MARKDOWN}.make).to_document (
				{STRING_32} "# Notes%N%NIn the **beginning** God created; see [John 1:1](John 1:1).%N%N- one%N- two"))
			Result.set_codec (create {SW_MARKDOWN_CODEC}.make)
			Result.set_on_document_change (agent note_change)
		end

	type_into_view (a_v: SW_DOCUMENT_VIEW; a_text: READABLE_STRING_GENERAL)
			-- Every character through the view's key door.
		local
			i: INTEGER
		do
			from i := 1 until i > a_text.count loop
				a_v.handle_char (a_text.code (i).to_integer_32)
				i := i + 1
			end
		end

	editing_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- A note with pointed Hebrew and polytonic Greek, its Hebrew
			-- paragraph open in the box (its Markdown shown, Hebrew and all)
			-- while the rest stays formatted. Nothing skipped; evidence
			-- written.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
			r: DOC_TEXT
			path: STRING_32
		do
			create w.make ("gw13 edit", 0, 0, 760, 520, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			create d.make
			d.add_heading (1, "Notes on Genesis 1:1").do_nothing
			r := d.add_paragraph (genesis_1_1_wlc)
			r.add_bold (1, 6)
			r := d.add_paragraph ({STRING_32} "The first word is " + genesis_first_word + {STRING_32} "; John answers it: " + john_first_words + {STRING_32} ".")
			r.add_italic (19, genesis_first_word.count)
			r.add_link (r.count - john_first_words.count, john_first_words.count, "John 1:1")
			d.add_bullet (1, "created, of God alone").do_nothing
			d.add_quote (1, "In the beginning was the Word.").do_nothing
			create v.make (520.0)
			v.set_document (d)
			v.set_codec (create {SW_MARKDOWN_CODEC}.make)
			w.set_root (v)
			w.request_render
			v.begin_edit (3)
			w.request_render
			assert_true ("editing", v.is_editing)
			if attached v.editor as al_ed then
				assert_true ("the source shows the italic Hebrew", al_ed.text.has_substring ({STRING_32} "_" + genesis_first_word + {STRING_32} "_"))
				assert_true ("and the link", al_ed.text.has_substring ("](John 1:1)"))
			end
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

	john_first_words: STRING_32
			-- The first two words of John 1:1 (WH), up to the second space.
		local
			i, spaces: INTEGER
		do
			create Result.make (16)
			from
				i := 1
			until
				i > john_1_1_wh.count or spaces = 2
			loop
				if john_1_1_wh.item (i) = ' ' then
					spaces := spaces + 1
				end
				if spaces < 2 then
					Result.extend (john_1_1_wh.item (i))
				end
				i := i + 1
			end
		end

end
