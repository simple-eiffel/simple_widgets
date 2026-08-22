note
	description: "[
		Contract assault on the SW_TEXT_BOX engine and SW_COMBO:
		drive the public API through edge states and let the class
		invariants and postconditions do the judging - F_code -keep
		bakes every assertion in.
	]"

class
	SW_ENGINE_ASSAULT

inherit
	TEST_SET_BASE

feature -- The regression that started this suite

	test_set_text_kills_stale_ranges
			-- Disjoint multi-select, then swap in SHORTER text: the
			-- stale extras breached extras_well_formed before the fix.
		local
			b: SW_TEXT_BOX
		do
			create b.make ("hello world")
			b.handle_key (39, False)
			b.handle_key (39, False)
			b.handle_key (39, True)
			b.handle_key (39, True)
			b.handle_key (39, True)
			assert ("selection built", b.has_selection)
			b.invert_selection
			assert ("still selected after invert", b.has_selection)
			b.set_text ("hi")
			assert ("extras gone", not b.has_selection)
			assert ("text swapped", b.text.same_string_general ("hi"))
			assert ("caret clamped", b.caret <= b.text.count)
		end

	test_arrow_selection_and_invert
		local
			b: SW_TEXT_BOX
		do
			create b.make ("abcdef")
			b.handle_key (39, False)
			b.handle_key (39, False)
			b.handle_key (39, True)
			b.handle_key (39, True)
			assert ("cd selected", b.selected_text.same_string_general ("cd"))
			b.invert_selection
			assert_true ("complement selected", b.has_selection)
			b.select_none
			assert ("collapsed", not b.has_selection)
			b.select_all
			assert ("all", b.selected_text.same_string_general ("abcdef"))
		end

feature -- Password mode

	test_masked_glyph_state
		local
			b: SW_TEXT_BOX
		do
			create b.make_password ("secret")
			assert ("masked", b.is_masked)
			assert ("hiding", b.is_hiding)
			assert ("single line forever", b.is_single_line)
			b.toggle_reveal
			assert ("revealed shows", not b.is_hiding)
			assert ("still masked in nature", b.is_masked)
			b.toggle_reveal
			assert ("hidden again", b.is_hiding)
		end

	test_masked_copy_denied
		local
			b: SW_TEXT_BOX
			clip: SW_CLIPBOARD
		do
			create clip
			clip.set_text ("SENTINEL")
			create b.make_password ("hunter2")
			b.select_all
			assert ("selection exists", b.has_selection)
			b.copy_selection
			assert ("clipboard untouched", clip.text.same_string_general ("SENTINEL"))
			b.cut_selection
			assert ("cut still no leak", clip.text.same_string_general ("SENTINEL"))
			assert ("cut still deleted", b.text.is_empty)
		end

	test_reveal_is_view_only
		local
			b: SW_TEXT_BOX
			clip: SW_CLIPBOARD
		do
			create clip
			clip.set_text ("SENTINEL")
			create b.make_password ("secret")
			b.toggle_reveal
			b.select_all
			b.copy_selection
			assert ("revealed still refuses the clipboard", clip.text.same_string_general ("SENTINEL"))
		end

feature -- Clipboard shapes

	test_single_line_paste_flattens
		local
			b: SW_TEXT_BOX
			clip: SW_CLIPBOARD
		do
			create clip
			clip.set_text ("a%Nb%Nc")
			create b.make_single_line ("")
			b.paste_clipboard
			assert ("newlines flattened", b.text.same_string_general ("a b c"))
		end

	test_astral_code_point_round_trip
			-- R8: one astral character is ONE code point in the box,
			-- and survives the clipboard's UTF-16 surrogate pairing.
		local
			b: SW_TEXT_BOX
			clip: SW_CLIPBOARD
		do
			create b.make ("")
			b.handle_char (0x1F600)
			assert_integers_equal ("one code point", 1, b.text.count)
			assert_integers_equal ("the emoji", 0x1F600, b.text.code (1).as_integer_32)
			b.select_all
			b.copy_selection
			create clip
			assert ("clipboard has it", clip.has_text)
			assert_integers_equal ("round-tripped intact", 0x1F600, clip.text.code (1).as_integer_32)
		end

feature -- Combo

	test_combo_choose_option
		local
			c: SW_COMBO
		do
			create c.make_with_options
			c.add_option ("Cairo")
			c.add_option ("Vision2")
			c.add_option ("WEL")
			c.choose_option (2)
			assert ("text taken", c.text.same_string_general ("Vision2"))
			assert_integers_equal ("caret at end", c.text.count, c.caret)
			assert ("no dangling selection", not c.has_selection)
		end

	test_caret_clamps_on_shorter_text
		local
			b: SW_TEXT_BOX
		do
			create b.make ("a long line of text")
			b.select_all
			b.set_text ("x")
			assert ("caret in range", b.caret >= 0 and b.caret <= 1)
			b.handle_char (33)
			assert ("still editable", not b.text.is_empty)
		end

end
