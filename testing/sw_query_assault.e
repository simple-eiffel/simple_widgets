note
	description: "[
		Assault on GW-12, SW_QUERY_BUILDER's clause tree: nested groups,
		NOT, proximity, the readable expression and the display-only
		SQL-shaped text, incomplete nodes left out, typed value pickers (a
		choice of codes, a lemma picker following the typing), removal,
		and the builder in both themes (evidence gw12_builder_light.png and
		gw12_builder_dark.png).
	]"

class
	SW_QUERY_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- The tree

	test_gw12_tree_reads_and_renders
			-- ALL of: a lemma, ANY of (a morphology code, NOT a word), and a
			-- proximity - read back as the reader reads it and as display
			-- SQL.
		local
			q: SW_QUERY_BUILDER
			g: SW_QUERY_GROUP
			c: SW_QUERY_CONDITION
		do
			q := new_builder
			q.root.add_condition (1, 1, "bara").do_nothing
			g := q.root.add_group
			g.set_join_all (False)
			g.add_condition (2, 1, "V-QAL").do_nothing
			c := g.add_condition (3, 5, "light")
			c.set_negated (True)
			q.root.add_proximity (3, "light", "darkness", 5).do_nothing
			assert_strings_equal ("the expression",
				{STRING_32} "lemma = %"bara%" AND (morph = %"V-QAL%" OR NOT (word contains %"light%")) AND %"light%" NEAR/5 %"darkness%" in word",
				q.expression)
			assert_strings_equal ("the display SQL",
				{STRING_32} "lemma = 'bara' AND (morph = 'V-QAL' OR NOT (word LIKE '%%light%%')) AND NEAR(word, 'light', 'darkness', 5)",
				q.query_text)
		end

	test_gw12_incomplete_and_negated_groups
			-- An empty condition or group is left out; a negated group is
			-- wrapped in NOT; an ordered proximity reads BEFORE.
		local
			q: SW_QUERY_BUILDER
			g: SW_QUERY_GROUP
			p: SW_QUERY_PROXIMITY
		do
			q := new_builder
			q.root.add_condition (1, 1, "").do_nothing
			q.root.add_group.do_nothing
			assert_true ("nothing complete, nothing said", q.expression.is_empty and q.query_text.is_empty)
			g := q.root.add_group
			g.add_condition (1, 1, "bara").do_nothing
			g.set_negated (True)
			p := q.root.add_proximity (3, "in", "beginning", 2)
			p.set_ordered (True)
			assert_strings_equal ("NOT around the group, BEFORE for in-order",
				{STRING_32} "NOT (lemma = %"bara%") AND %"in%" BEFORE/2 %"beginning%" in word", q.expression)
		end

	test_gw12_typed_pickers_and_removal
			-- A choice field shows its codes; a lemma field's picker follows
			-- the typing; removing a node takes it out of the question.
		local
			w: SW_WINDOW
			q: SW_QUERY_BUILDER
			c: SW_QUERY_CONDITION
			changes_before: INTEGER
		do
			create w.make ("qb", 0, 0, 900, 400, create {SW_THEME}.make_light)
			q := new_builder
			q.set_field_choices (2, <<"V-QAL", "N-M-S">>)
			q.set_field_suggester (1, agent lemma_suggestions)
			q.set_on_change (agent note_change)
			q.root.add_condition (2, 1, "").do_nothing
			q.root.add_condition (1, 1, "").do_nothing
			q.add_clause
			w.set_root (q)
			w.request_render
			if attached {SW_COMBO} value_control_of (q, 1) as al_codes then
				assert_true ("the codes are offered", al_codes.options.count = 2
					and then al_codes.options.first.same_string ("V-QAL"))
			else
				assert_true ("a choice field gets a picker", False)
			end
			if attached {SW_COMBO} value_control_of (q, 2) as al_lemma then
				al_lemma.set_focused (True)
				al_lemma.handle_char (('b').code)
				assert_true ("the lemma follows the typing", q.root.children.i_th (2) /= Void
					and then attached {SW_QUERY_CONDITION} q.root.children.i_th (2) as al_c2
					and then al_c2.value.same_string ("b"))
				assert_true ("and so do its choices", al_lemma.options.count = 2
					and then al_lemma.options.first.same_string ("bara"))
			else
				assert_true ("a lemma field gets a picker", False)
			end
			if attached {SW_QUERY_CONDITION} q.root.children.i_th (2) as al_c then
				c := al_c
				changes_before := changes
				q.remove_node (c)
				assert_integers_equal ("two left", 2, q.root.children.count)
				assert_true ("and the host heard", changes > changes_before)
			end
		end

	test_gw12_distance_edit_is_heard
			-- Turning the proximity's distance changes the tree and tells the
			-- host, like every other edit.
		local
			w: SW_WINDOW
			q: SW_QUERY_BUILDER
			p: SW_QUERY_PROXIMITY
			changes_before: INTEGER
		do
			create w.make ("qb", 0, 0, 900, 400, create {SW_THEME}.make_light)
			q := new_builder
			p := q.root.add_proximity (3, "light", "darkness", 5)
			q.add_clause
			q.set_on_change (agent note_change)
			w.set_root (q)
			w.request_render
			if attached distance_box_of (q) as al_box then
				changes_before := changes
				al_box.handle_wheel (120).do_nothing
				assert_true ("the distance moved", p.distance /= 5)
				assert_integers_equal ("the tree has the box's value", al_box.value, p.distance)
				assert_true ("and the host heard", changes > changes_before)
			else
				assert_true ("a proximity row has a distance box", False)
			end
		end

	test_gw12_long_distance_preset_renders
			-- A saved question may say "within 120 words"; rebuilding the
			-- rows must show it, not abort.
		local
			w: SW_WINDOW
			q: SW_QUERY_BUILDER
		do
			create w.make ("qb", 0, 0, 900, 400, create {SW_THEME}.make_light)
			q := new_builder
			q.root.add_proximity (3, "light", "darkness", 120).do_nothing
			q.add_clause
			w.set_root (q)
			w.request_render
			if attached distance_box_of (q) as al_box then
				assert_integers_equal ("the box shows 120", 120, al_box.value)
			else
				assert_true ("a proximity row has a distance box", False)
			end
		end

feature -- The builder, both themes

	test_gw12_builder_light
		do
			builder_gate (create {SW_THEME}.make_light, "gw12_builder_light.png")
		end

	test_gw12_builder_dark
		do
			builder_gate (create {SW_THEME}.make_dark, "gw12_builder_dark.png")
		end

feature {NONE} -- Fixtures

	changes: INTEGER

	note_change
		do
			changes := changes + 1
		end

	new_builder: SW_QUERY_BUILDER
		do
			create Result.make (<<"lemma", "morph", "word">>)
		end

	lemma_suggestions (a_typed: STRING_32): ITERABLE [READABLE_STRING_GENERAL]
			-- Lemmas starting with what was typed.
		local
			l: ARRAYED_LIST [STRING_32]
		do
			create l.make (2)
			across <<"bara", "bayit", "elohim">> as s loop
				if s.to_string_32.starts_with (a_typed) then
					l.extend (s.to_string_32)
				end
			end
			Result := l
		end

	value_control_of (q: SW_QUERY_BUILDER; a_row: INTEGER): detachable SW_WIDGET
			-- The value control of the root group's `a_row'-th child row
			-- (row 1 is the group's head).
		do
			if attached {SW_COLUMN} q.children.first as al_root
				and then al_root.children.count > a_row
				and then attached {SW_ROW} al_root.children.i_th (a_row + 1) as al_row
				and then al_row.children.count >= 4
			then
				Result := al_row.children.i_th (4)
			end
		end

	distance_box_of (q: SW_QUERY_BUILDER): detachable SW_NUMBER_BOX
			-- The distance box of the root group's first child, a proximity
			-- (its first line: not, field, first word, "within", the box).
		do
			if attached {SW_COLUMN} q.children.first as al_root
				and then al_root.children.count >= 2
				and then attached {SW_COLUMN} al_root.children.i_th (2) as al_prox
				and then attached {SW_ROW} al_prox.children.first as al_words
				and then al_words.children.count >= 5
				and then attached {SW_NUMBER_BOX} al_words.children.i_th (5) as al_box
			then
				Result := al_box
			end
		end

	builder_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- A census criterion: the Hebrew lemma bara, ANY of two
			-- morphology codes with one negated, and "light" within five
			-- words of "darkness".
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			q: SW_QUERY_BUILDER
			g: SW_QUERY_GROUP
			path: STRING_32
		do
			create w.make ("gw12", 0, 0, 900, 420, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			q := new_builder
			q.set_field_choices (2, <<"V-QAL", "V-NIF", "N-M-S">>)
			q.root.add_condition (1, 1, genesis_first_word).do_nothing
			g := q.root.add_group
			g.set_join_all (False)
			g.add_condition (2, 1, "V-QAL").do_nothing
			g.add_condition (2, 1, "V-NIF").set_negated (True)
			q.root.add_proximity (3, "light", "darkness", 5).do_nothing
			q.set_join_all (True)
			w.set_root (q)
			w.request_render
			assert_true ("the question reads", not q.expression.is_empty)
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
