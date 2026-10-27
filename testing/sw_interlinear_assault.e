note
	description: "[
		Assault on GW-07, SW_INTERLINEAR: cells flowing into rows and
		wrapping, right to left mirrored, lines hidden and shown, words hit,
		selected by click and by Left/Right in reading order, a hover card
		anchored on the word, and Genesis 1:1 in both themes (evidence
		gw07_interlinear_light.png and gw07_interlinear_dark.png).
		Inherits the shaping assault for its scripture fixtures and kit.
	]"

class
	SW_INTERLINEAR_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Flow

	test_gw07_cells_flow_and_wrap
			-- Twelve words in a narrow view wrap onto several rows; left to
			-- right, a row's first cell stands at the left; right to left, at
			-- the right.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
		do
			create w.make ("il", 0, 0, 420, 400, create {SW_THEME}.make_light)
			attach_il_kit (w)
			v := twelve_words (False)
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_true ("wrapped onto rows", v.row_count > 1)
			assert_integers_equal ("word 1 in row 1", 1, v.token_row (1))
			assert_true ("word 1 at the left", v.token_box (1).x < v.token_box (2).x)
			v.set_right_to_left (True)
			w.request_render
			assert_true ("right to left: word 1 at the right", v.token_box (1).x > v.token_box (2).x)
		end

	test_interlinear_scrolls_to_a_word_chosen_before_layout
			-- 0.45.0: a word selected before the view is laid out (a chapter just filled, a verse to
			-- show) is scrolled to at the next layout, refilled or not. Before: `scroll_to_token' did
			-- nothing until laid out, so the chapter opened at its top.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			i, k: INTEGER
		do
			create w.make ("il", 0, 0, 420, 240, create {SW_THEME}.make_light)
			attach_il_kit (w)
			create v.make (200.0)
			from i := 1 until i > 200 loop
				k := v.add_token ("word" + i.out)
				v.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_gloss, "gloss")
				i := i + 1
			end
			w.set_root (v)
			v.select_token (190)
			w.request_render
			assert_true ("scrolled to the word", v.scroll_y > 0.0)
			v.wipe_out
			from i := 1 until i > 200 loop
				k := v.add_token ("again" + i.out)
				i := i + 1
			end
			v.select_token (195)
			w.request_render
			assert_true ("refilled, scrolled again", v.scroll_y > 0.0)
		end

	test_interlinear_lays_out_cantillated_hebrew
			-- 0.45.1: Genesis 1:1-2 as MACULA writes it, with its cantillation marks, one cell per
			-- word, right to left. A mark shaped left of its run's origin gave a cluster a negative
			-- x, and SW_CLUSTER_MATH's edge postconditions failed: simple_bible's Interlinear tab
			-- died on its first frame. Before: this test FAILED with that postcondition; after: every
			-- character edge lies within its run.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			k: INTEGER
		do
			create w.make ("il", 0, 0, 900, 500, create {SW_THEME}.make_light)
			attach_il_kit (w)
			create v.make (400.0)
			v.set_right_to_left (True)
			across <<
				{STRING_32} "%/1489/%/1456/%/1468/%/1512/%/1461/%/1488/%/1513/%/1460/%/1473/%/1430/%/1497/%/1514/",
				{STRING_32} "%/1489/%/1464/%/1468/%/1512/%/1464/%/1443/%/1488/",
				{STRING_32} "%/1488/%/1457/%/1500/%/1465/%/1492/%/1460/%/1425/%/1497/%/1501/",
				{STRING_32} "%/1488/%/1461/%/1445/%/1514/",
				{STRING_32} "%/1492/%/1463/%/1513/%/1464/%/1468/%/1473/%/1502/%/1463/%/1430/%/1497/%/1460/%/1501/",
				{STRING_32} "%/1493/%/1456/%/1488/%/1461/%/1445/%/1514/",
				{STRING_32} "%/1492/%/1464/%/1488/%/1464/%/1469/%/1512/%/1462/%/1509/",
				{STRING_32} "%/1493/%/1456/%/1492/%/1464/%/1488/%/1464/%/1431/%/1512/%/1462/%/1509/",
				{STRING_32} "%/1492/%/1464/%/1497/%/1456/%/1514/%/1464/%/1445/%/1492/",
				{STRING_32} "%/1514/%/1465/%/1448/%/1492/%/1493/%/1468/%/1433/",
				{STRING_32} "%/1493/%/1464/%/1489/%/1465/%/1428/%/1492/%/1493/%/1468/",
				{STRING_32} "%/1493/%/1456/%/1495/%/1465/%/1430/%/1513/%/1462/%/1473/%/1498/%/1456/",
				{STRING_32} "%/1506/%/1463/%/1500/",
				{STRING_32} "%/1508/%/1456/%/1468/%/1504/%/1461/%/1443/%/1497/",
				{STRING_32} "%/1514/%/1456/%/1492/%/1425/%/1493/%/1465/%/1501/",
				{STRING_32} "%/1493/%/1456/%/1512/%/1443/%/1493/%/1468/%/1495/%/1463/",
				{STRING_32} "%/1488/%/1457/%/1500/%/1465/%/1492/%/1460/%/1428/%/1497/%/1501/",
				{STRING_32} "%/1502/%/1456/%/1512/%/1463/%/1495/%/1462/%/1430/%/1508/%/1462/%/1514/",
				{STRING_32} "%/1506/%/1463/%/1500/",
				{STRING_32} "%/1508/%/1456/%/1468/%/1504/%/1461/%/1445/%/1497/",
				{STRING_32} "%/1492/%/1463/%/1502/%/1464/%/1468/%/1469/%/1497/%/1460/%/1501/"
				>> as ic loop
				k := v.add_token (ic)
				v.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_gloss, "gloss")
			end
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_integers_equal ("every word a cell", 21, v.token_count)
		end

	test_refilled_interlinear_forgets_an_old_scroll
			-- Scan 37: a word selected in a laid-out view leaves the stack's row request armed until
			-- the next measure; a refill that selects nothing (a whole chapter) then jumped to the
			-- old row. Before: scrolled down; after: the new words open at the top.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			i, k: INTEGER
		do
			create w.make ("il", 0, 0, 420, 240, create {SW_THEME}.make_light)
			attach_il_kit (w)
			create v.make (200.0)
			from i := 1 until i > 200 loop
				k := v.add_token ("word" + i.out)
				i := i + 1
			end
			w.set_root (v)
			w.request_render
			v.select_token (190)
			v.wipe_out
			from i := 1 until i > 200 loop
				k := v.add_token ("again" + i.out)
				i := i + 1
			end
			w.request_render
			assert_true ("opens at the top", v.scroll_y = 0.0)
		end

	test_gw07_lines_hide_and_show
			-- Hiding the morphology line makes every cell shorter; the
			-- surface word cannot be hidden.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			h1: REAL_64
		do
			create w.make ("il", 0, 0, 900, 400, create {SW_THEME}.make_light)
			attach_il_kit (w)
			v := twelve_words (False)
			w.set_root (v)
			w.request_render
			h1 := v.token_box (1).height
			v.set_line_visible ({SW_INTERLINEAR_TOKEN}.Line_morphology, False)
			w.request_render
			assert_true ("shorter without morphology", v.token_box (1).height < h1)
			assert_false ("hidden", v.is_line_visible ({SW_INTERLINEAR_TOKEN}.Line_morphology))
			assert_true ("the surface shows", v.is_line_visible ({SW_INTERLINEAR_TOKEN}.Line_surface))
		end

	test_gw07_select_by_click_and_keys
			-- A click selects the word under it; Right moves on in reading
			-- order (back, right to left); End and Home go to the ends.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			b: TUPLE [x, y, width, height: REAL_64]
		do
			create w.make ("il", 0, 0, 900, 400, create {SW_THEME}.make_light)
			attach_il_kit (w)
			v := twelve_words (False)
			v.set_on_token_select (agent note_token)
			w.set_root (v)
			w.request_render
			b := v.token_box (3)
			assert_true ("click taken", v.handle_click (b.x + b.width / 2.0, b.y + 4.0))
			assert_integers_equal ("word 3 selected", 3, v.selected_token)
			assert_integers_equal ("and heard", 3, last_token)
			assert_integers_equal ("token_at agrees", 3, v.token_at (b.x + b.width / 2.0, b.y + 4.0))
			v.handle_key (39, False)
			assert_integers_equal ("Right: word 4", 4, v.selected_token)
			v.handle_key (35, False)
			assert_integers_equal ("End: the last", 12, v.selected_token)
			v.handle_key (36, False)
			assert_integers_equal ("Home: the first", 1, v.selected_token)
			v.set_right_to_left (True)
			w.request_render
			v.handle_key (37, False)
			assert_integers_equal ("right to left, Left moves on", 2, v.selected_token)
			v.handle_char (3)
			assert_true ("Ctrl+C copied the word (no failure)", v.selected_token = 2)
		end

	test_gw07_every_line_can_be_pointed_at
			-- The gloss line is text too: the pointer finds its character, so
			-- a hover card can open from it.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			k: INTEGER
			b: TUPLE [x, y, width, height: REAL_64]
		do
			create w.make ("il", 0, 0, 900, 400, create {SW_THEME}.make_light)
			attach_il_kit (w)
			v := twelve_words (False)
			w.set_root (v)
			w.request_render
			from k := 1 until k > v.unit_count or else v.unit_row (k) = {SW_INTERLINEAR_TOKEN}.Line_gloss loop
				k := k + 1
			end
			assert_true ("a gloss unit", k <= v.unit_count)
			b := v.text_boxes (k, 0, 1).first
			assert_true ("the gloss character is found", v.character_at (b.x + b.width / 2.0, b.y + b.height / 2.0) > 0)
			assert_integers_equal ("and its unit is the gloss", k, v.pointed_item (b.x + b.width / 2.0, b.y + b.height / 2.0))
		end

	test_gw07_new_words_after_wipe_out_are_shown
			-- After wipe_out, a new word is what is laid out - even when the
			-- revision arithmetic would have come back to the old value.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			k: INTEGER
		do
			create w.make ("il", 0, 0, 900, 400, create {SW_THEME}.make_light)
			attach_il_kit (w)
			create v.make (400.0)
			k := v.add_token ("old")
			v.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_gloss, "gloss")
			w.set_root (v)
			w.request_render
			v.wipe_out
			k := v.add_token ("new")
			w.request_render
			assert_strings_equal ("the new word is laid out", {STRING_32} "new", v.text_of (1))
		end

	test_gw07_a_click_ends_a_text_selection
			-- Ctrl+A selects every line's text; a click on a word picks that
			-- word and ends the text selection, so Ctrl+C copies what is shown.
		local
			w: SW_WINDOW
			v: SW_INTERLINEAR
			b: TUPLE [x, y, width, height: REAL_64]
		do
			create w.make ("il", 0, 0, 900, 400, create {SW_THEME}.make_light)
			attach_il_kit (w)
			v := twelve_words (False)
			w.set_root (v)
			w.request_render
			v.handle_char (1)
			assert_true ("Ctrl+A selected", v.has_selection)
			b := v.token_box (2)
			assert_true ("click taken", v.handle_click (b.x + b.width / 2.0, b.y + 4.0))
			assert_false ("the text selection ended", v.has_selection)
			assert_integers_equal ("the word picked", 2, v.selected_token)
		end

feature -- Genesis 1:1, both themes

	test_gw07_interlinear_light
		do
			interlinear_gate (create {SW_THEME}.make_light, "gw07_interlinear_light.png")
		end

	test_gw07_interlinear_dark
		do
			interlinear_gate (create {SW_THEME}.make_dark, "gw07_interlinear_dark.png")
		end

feature {NONE} -- Fixtures

	last_token: INTEGER

	note_token (a_token: INTEGER)
		do
			last_token := a_token
		end

	attach_il_kit (a_window: SW_WINDOW)
		local
			kit: SW_SHAPING
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_window.theme)
			a_window.set_shaping (kit)
		end

	twelve_words (a_rtl: BOOLEAN): SW_INTERLINEAR
			-- Twelve made-up words with every line filled.
		local
			i, k: INTEGER
		do
			create Result.make (400.0)
			Result.set_right_to_left (a_rtl)
			from i := 1 until i > 12 loop
				k := Result.add_token ("word" + i.out)
				Result.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_transliteration, "translit" + i.out)
				Result.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_gloss, "gloss " + i.out)
				Result.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_strongs, "H" + (7224 + i).out)
				Result.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_morphology, "noun, masculine singular")
				i := i + 1
			end
		end

	interlinear_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- Genesis 1:1, right to left: each word of the verse with its
			-- transliteration, gloss, Strong's number and morphology; word 1
			-- with every line. Nothing skipped; evidence written.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			v: SW_INTERLINEAR
			words: ARRAYED_LIST [STRING_32]
			k: INTEGER
			l_word: STRING_32
			glosses: ARRAY [STRING]
			translits: ARRAY [STRING]
			strongs: ARRAY [STRING]
			path: STRING_32
		do
			create w.make ("gw07", 0, 0, 900, 460, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			create words.make (8)
			create l_word.make (12)
			across genesis_1_1_wlc as c loop
				if c = ' ' then
					if not l_word.is_empty then
						words.extend (l_word)
					end
					create l_word.make (12)
				else
					l_word.extend (c)
				end
			end
			if not l_word.is_empty then
				words.extend (l_word)
			end
			glosses := <<"in the beginning", "he created", "God", "[object]", "the heavens", "and [object]", "the earth">>
			translits := <<"bereshit", "bara", "elohim", "et", "hashamayim", "veet", "haarets">>
			strongs := <<"H7225", "H1254", "H430", "H853", "H8064", "H853", "H776">>
			create v.make (460.0)
			v.set_right_to_left (True)
			across words as wd loop
				k := v.add_token (wd)
				if k <= glosses.count then
					v.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_transliteration, translits [k])
					v.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_gloss, glosses [k])
					v.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_strongs, strongs [k])
				end
			end
			v.set_verse_label (1, "1:1")
			v.set_token_line (1, {SW_INTERLINEAR_TOKEN}.Line_pronunciation, "be-re-SHEET")
			v.set_token_line (1, {SW_INTERLINEAR_TOKEN}.Line_lemma, "reshit")
			v.set_token_line (1, {SW_INTERLINEAR_TOKEN}.Line_morphology, "preposition + noun, feminine singular")
			v.select_token (2)
			w.set_root (v)
			w.request_render
			assert_true ("laid out", v.is_laid_out)
			assert_true ("every word placed", v.token_count >= 7)
			assert_true ("word 1 at the right (right to left)", v.token_box (1).x > v.token_box (2).x)
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
