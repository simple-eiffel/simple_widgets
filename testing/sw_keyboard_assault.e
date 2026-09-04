note
	description: "[
		THE KEYBOARD: window-wide accelerators, and menu mnemonics.
		Offscreen only - every SW_WINDOW here is built with `make' and
		driven with `request_render' / `write_frame'; `run' (which alone
		creates a native HWND) is never called, so `hwnd' stays
		`default_pointer' and no window, visible or hidden, ever exists.
		No synthetic keystroke is ever posted to this desktop: the
		accelerator table is driven through `fire_accelerator' and the
		mnemonic path through `activate_mnemonic', which are the same
		doors `dispatch_plain' knocks on.

		THE REPORT. Larry: "Alt / Alt+F" does nothing, and there are "no
		mnemonic underlines". Both were true. A key reached exactly one
		place - the FOCUSED widget - and `SW_WIDGET.handle_key' carries
		Shift and nothing else, so an application had nowhere to say
		"Ctrl+N means New wherever the caret is". And no menu class had
		ever heard of an ampersand.

		WHAT IS PROVEN HERE. (1) An accelerator fires no matter who holds
		focus, and matches on the EXACT modifier state. (2) An unclaimed
		Ctrl+A / C / V / X / Z / Y is still the focused text box's own -
		the table answers 0 and the key goes on. (3) The ampersand parse:
		"&File", "Select &All", "R&&D", a trailing "&", the empty label.
		(4) A menu bar underlines its mnemonic and answers Alt+F; an open
		menu answers a bare letter. (5) A window opens the right pad's
		menu under the right pad.

		THE ALT GAP, AND WHY IT IS NOT A TEST FAILURE. Alt STATE is
		exposed (`SW_KEYS.alt_down'), so an Alt accelerator matches. Alt
		DELIVERY is not: simple_shell answers WM_SYSKEYDOWN only for the
		OEM plus/minus pair and lets every other syskey fall through to
		DefWindowProc. Until the shell forwards WM_SYSKEYDOWN/WM_SYSCHAR
		for letters, no Alt keystroke reaches SW_WINDOW at all, and
		`activate_mnemonic' is reachable only from a host, a Ctrl
		accelerator, or a test. That is a shell gap, named in
		SW_WINDOW's own class note and in the README; the toolkit half
		is finished and proven here.
	]"
	author: "Larry Rix"

class
	SW_KEYBOARD_ASSAULT

inherit
	TEST_SET_BASE

feature -- The ampersand parse

	test_mnemonic_parsing
		local
			m: SW_MNEMONIC
		do
			create m

			assert_strings_equal_diff ("the ampersand never reaches the reader",
				{STRING_32} "File", m.plain ("&File"))
			assert_integers_equal ("...it underlines the F", 1, m.underline_index ("&File"))
			assert_true ("...and the Alt-key is F", m.mnemonic_letter ("&File") = 'F')
			assert_integers_equal ("...whose virtual key is 70", 70, m.virtual_key ("&File"))

			assert_strings_equal_diff ("mid-label", {STRING_32} "Select All", m.plain ("Select &All"))
			assert_integers_equal ("the A of All is the eighth character of the plain reading",
				8, m.underline_index ("Select &All"))

			assert_strings_equal_diff ("a doubled ampersand is a literal one",
				{STRING_32} "R&D", m.plain ("R&&D"))
			assert_false ("...and declares no mnemonic", m.has_mnemonic ("R&&D"))
			assert_integers_equal ("...so no virtual key", 0, m.virtual_key ("R&&D"))

			assert_strings_equal_diff ("a trailing ampersand marks nothing and is dropped",
				{STRING_32} "File", m.plain ("File&"))
			assert_false ("...and declares no mnemonic", m.has_mnemonic ("File&"))

			assert_strings_equal_diff ("the empty label survives the parse",
				{STRING_32} "", m.plain (""))
			assert_false ("...with nothing to answer to", m.has_mnemonic (""))

			assert_true ("Alt+f and Alt+F are one gesture", m.matches ("&File", 'f'))
			assert_true ("...either way round", m.matches ("&file", 'F'))
			assert_false ("and a letter that is not there does not match", m.matches ("&File", 'Z'))

			assert_integers_equal ("a digit mnemonic is a digit key", 49, m.virtual_key ("&1 Recent"))
		end

feature -- The accelerator table

	test_an_accelerator_fires_regardless_of_focus
		local
			w: SW_WINDOW
			th: SW_THEME
			box: SW_TEXT_BOX
			root: SW_COLUMN
			fired: BOOLEAN
		do
			create th.make_light
			create w.make ("acc", 0, 0, 400, 300, th)
			create box.make_single_line ("untouched")
			create root.make
			root.put (box)
			w.set_root (root)
			w.request_render
			w.give_focus (box)
			assert_true ("the text box holds the focus", box.is_focused)

			assert_true ("no accelerators to begin with", w.accelerators.is_empty)
			w.register_accelerator (78, True, False, False, agent set_flag)
			assert_integers_equal ("one registered", 1, w.accelerators.count)

			flag := False
			fired := w.fire_accelerator (78, True, False, False)
			assert_true ("Ctrl+N fired", fired)
			assert_true ("...and ran the action", flag)
			assert_strings_equal_diff ("...while the focused box was never touched",
				{STRING_32} "untouched", box.text)
			assert_true ("the box still holds the focus", box.is_focused)
		end

	test_the_modifier_state_must_match_exactly
		local
			w: SW_WINDOW
			th: SW_THEME
		do
			create th.make_light
			create w.make ("acc", 0, 0, 200, 200, th)
			w.register_accelerator (83, True, False, False, agent set_flag)

			assert_integers_equal ("Ctrl+S is claimed", 1, w.accelerator_for (83, True, False, False))
			assert_integers_equal ("Ctrl+Shift+S is NOT the same key",
				0, w.accelerator_for (83, True, False, True))
			assert_integers_equal ("Ctrl+Alt+S is NOT the same key",
				0, w.accelerator_for (83, True, True, False))
			assert_integers_equal ("Alt+S is NOT the same key",
				0, w.accelerator_for (83, False, True, False))
			assert_integers_equal ("a different letter is a different key",
				0, w.accelerator_for (84, True, False, False))

			flag := False
			assert_false ("an unclaimed combination fires nothing",
				w.fire_accelerator (83, True, False, True))
			assert_false ("...and runs no action", flag)
		end

	test_an_unclaimed_ctrl_key_is_still_the_focused_box_s_own
			-- The rule that keeps editing working: the table answers 0
			-- for every editor key nobody registered, and SW_TEXT_BOX
			-- goes on doing what it has always done with the WM_CHAR
			-- control code.
		local
			w: SW_WINDOW
			th: SW_THEME
			box: SW_TEXT_BOX
			root: SW_COLUMN
			codes: ARRAY [INTEGER]
			i: INTEGER
		do
			create th.make_light
			create w.make ("acc", 0, 0, 400, 300, th)
			create box.make ("alpha beta")
			create root.make
			root.put (box)
			w.set_root (root)
			w.request_render
			w.give_focus (box)

				-- Ctrl+A 65, C 67, V 86, X 88, Z 90, Y 89
			codes := <<65, 67, 86, 88, 90, 89>>
			from i := codes.lower until i > codes.upper loop
				assert_integers_equal ("nobody claims virtual key " + codes [i].out,
					0, w.accelerator_for (codes [i], True, False, False))
				i := i + 1
			end

			box.handle_char (1)
			assert_true ("Ctrl+A still selects all, in the box itself", box.has_selection)
			assert_strings_equal_diff ("...the whole text", {STRING_32} "alpha beta", box.selected_text)

			box.handle_char (27)
			assert_false ("Escape still clears it", box.has_selection)

				-- now let the window CLAIM Ctrl+A and watch the answer change
			w.register_accelerator (65, True, False, False, agent set_flag)
			assert_integers_equal ("claimed now", 1, w.accelerator_for (65, True, False, False))
			assert_integers_equal ("...and the box's other keys are untouched",
				0, w.accelerator_for (67, True, False, False))
		end

	test_first_registration_wins_and_clear_empties
		local
			w: SW_WINDOW
			th: SW_THEME
		do
			create th.make_light
			create w.make ("acc", 0, 0, 200, 200, th)
			w.register_accelerator (78, True, False, False, agent set_flag)
			w.register_accelerator (78, True, False, False, agent clear_flag)
			assert_integers_equal ("both registrations are kept", 2, w.accelerators.count)
			assert_integers_equal ("but the FIRST one is the answer",
				1, w.accelerator_for (78, True, False, False))

			flag := True
			assert_true ("it fires", w.fire_accelerator (78, True, False, False))
			assert_true ("and it is the first agent that ran", flag)

			w.clear_accelerators
			assert_true ("cleared", w.accelerators.is_empty)
			assert_integers_equal ("nothing claims Ctrl+N any more",
				0, w.accelerator_for (78, True, False, False))
		end

feature -- Menus: mnemonics

	test_menu_bar_reads_and_answers_its_ampersands
		local
			bar: SW_MENU_BAR
		do
			create bar.make
			bar.add_menu ("&File", agent built_menu)
			bar.add_menu ("&Edit", agent built_menu)
			bar.add_menu ("Help", agent built_menu)

			assert_strings_equal_diff ("the drawn title has no ampersand",
				{STRING_32} "File", bar.labels.i_th (1))
			assert_strings_equal_diff ("the declaration is kept",
				{STRING_32} "&File", bar.raw_labels.i_th (1))
			assert_integers_equal ("File underlines its first character",
				1, bar.pad_underline_index (1))
			assert_integers_equal ("a pad with no ampersand underlines nothing",
				0, bar.pad_underline_index (3))

			assert_integers_equal ("Alt+F opens File", 1, bar.menu_for_mnemonic ('F'))
			assert_integers_equal ("...lower case too", 1, bar.menu_for_mnemonic ('f'))
			assert_integers_equal ("Alt+E opens Edit", 2, bar.menu_for_mnemonic ('E'))
			assert_integers_equal ("Alt+Z opens nothing", 0, bar.menu_for_mnemonic ('Z'))
			assert_integers_equal ("Alt+H opens nothing: Help declared no mnemonic",
				0, bar.menu_for_mnemonic ('H'))
		end

	test_a_disabled_pad_does_not_answer_alt
		local
			bar: SW_MENU_BAR
		do
			create bar.make
			bar.add_menu_when ("&File", agent built_menu, agent always_false)
			bar.add_menu ("&Edit", agent built_menu)
			assert_false ("the File pad is off", bar.pad_enabled (1))
			assert_integers_equal ("...so Alt+F is deaf, exactly as the pad is",
				0, bar.menu_for_mnemonic ('F'))
			assert_integers_equal ("Edit still answers", 2, bar.menu_for_mnemonic ('E'))
		end

	test_an_open_menu_answers_a_bare_letter
		local
			m: SW_MENU
		do
			m := built_menu
			assert_strings_equal_diff ("the item draws without its ampersand",
				{STRING_32} "New", m.items.i_th (1).label)
			assert_integers_equal ("...and underlines the N", 1, m.item_underline_index (1))
			assert_integers_equal ("Open is second and underlines its O",
				1, m.item_underline_index (2))
			assert_integers_equal ("a separator underlines nothing", 0, m.item_underline_index (3))
			assert_strings_equal_diff ("Exit underlines its x",
				{STRING_32} "Exit", m.items.i_th (4).label)
			assert_integers_equal ("...the second character", 2, m.item_underline_index (4))

			assert_integers_equal ("N picks New", 1, m.item_for_mnemonic ('N'))
			assert_integers_equal ("o picks Open, case folded", 2, m.item_for_mnemonic ('o'))
			assert_integers_equal ("x picks Exit", 4, m.item_for_mnemonic ('x'))
			assert_integers_equal ("a letter nobody declares picks nothing",
				0, m.item_for_mnemonic ('Q'))
			assert_integers_equal ("a DISABLED item never answers", 0, m.item_for_mnemonic ('S'))
		end

	test_the_window_opens_the_pad_the_mnemonic_names
		local
			w: SW_WINDOW
			th: SW_THEME
			bar: SW_MENU_BAR
			root: SW_COLUMN
			b: TUPLE [left, width: REAL_64]
		do
			create th.make_light
			create w.make ("mnemonic", 0, 0, 500, 300, th)
			create bar.make
			bar.add_menu ("&File", agent built_menu)
			bar.add_menu ("&Edit", agent built_menu)
			create root.make
			root.put (bar)
			w.set_root (root)
			w.set_menu_bar (bar)
			w.request_render

			assert_void ("nothing is open yet", w.open_popup)
			assert_false ("a letter no pad declares opens nothing", w.activate_mnemonic ('Z'))
			assert_void ("...still nothing", w.open_popup)

			assert_true ("Alt+E answers", w.activate_mnemonic ('e'))
			assert_attached ("...and the menu is up", w.open_popup)
			b := bar.pad_bounds (w.painter, 2)
			if attached w.open_popup as pm then
				assert_reals_equal ("it is dropped under the EDIT pad, not the File pad",
					b.left, pm.x, 6.0)
				assert_true ("...and below the bar", pm.y >= bar.y + bar.height)
			end
			print ("    pads: File at " + bar.pad_bounds (w.painter, 1).left.out
				+ ", Edit at " + b.left.out + "%N")
		end

feature -- Evidence (offscreen only - no window is ever shown)

	test_mnemonic_evidence
			-- A menu bar with its underlines, and one menu open beneath
			-- the pad Alt named.
		local
			w: SW_WINDOW
			th: SW_THEME
			bar: SW_MENU_BAR
			root: SW_COLUMN
			body: SW_LABEL
			evidence: STRING_32
			wrote, opened: BOOLEAN
		do
			create th.make_dark
			th.set_text_scale (2.0)
			create w.make ("mnemonic-evidence", 0, 0, 620, 360, th)
			create bar.make
			bar.add_menu ("&File", agent built_menu)
			bar.add_menu ("&Edit", agent built_menu)
			bar.add_menu ("&View", agent built_menu)
			create body.make_ui ("Alt underlines the letter it answers to.")
			body.set_grow (1.0)
			create root.make
			root.put (bar)
			root.put (body)
			w.set_root (root)
			w.set_menu_bar (bar)
			w.request_render

			evidence := evidence_path ("menu-mnemonics-2x.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end

			opened := w.activate_mnemonic ('F')
			assert_true ("Alt+F opened the File menu for the picture", opened)
			w.request_render
			evidence := evidence_path ("menu-alt-open-2x.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end
		end

feature {NONE} -- Fixtures

	flag: BOOLEAN
			-- Set by `set_flag', cleared by `clear_flag' - how a test
			-- watches an accelerator's agent actually run.

	set_flag
		do
			flag := True
		end

	clear_flag
		do
			flag := False
		end

	always_false: BOOLEAN
		do
		end

	built_menu: SW_MENU
			-- The menu every pad in these tests builds: two mnemonic
			-- items, a disabled one, a separator, and an Exit whose
			-- mnemonic is NOT its first letter.
		do
			create Result.make
			Result.add_item ("&New", "Ctrl+N", True, agent set_flag)
			Result.add_item ("&Open", "Ctrl+O", True, agent set_flag)
			Result.add_separator
			Result.add_item ("E&xit", "", True, agent set_flag)
			Result.add_item ("&Save", "Ctrl+S", False, agent set_flag)
		ensure
			five: Result.items.count = 5
		end

feature {NONE} -- Evidence location (mirrors SW_CHAT_SCROLL_ASSAULT)

	evidence_path (a_name: STRING): STRING_32
			-- `<repo>/evidence/<a_name>', or empty when the repository is
			-- not underfoot - which simply means no file is written.
		require
			name_not_empty: not a_name.is_empty
		local
			env: EXECUTION_ENVIRONMENT
			starts: ARRAYED_LIST [PATH]
			base, marker, dir: PATH
			d: DIRECTORY
			i, step: INTEGER
			found: BOOLEAN
		do
			create Result.make_empty
			create env
			create starts.make (2)
			starts.extend (env.current_working_path)
			starts.extend ((create {PATH}.make_from_string (env.arguments.command_name)).parent)
			from i := 1 until i > starts.count or found loop
				base := starts [i]
				from step := 0 until step > 6 or found loop
					marker := base.extended ("simple_widgets.ecf")
					if file_exists (marker.name) then
						dir := base.extended ("evidence")
						if not directory_exists (dir.name) then
							create d.make_with_path (dir)
							d.recursive_create_dir
						end
						if directory_exists (dir.name) then
							Result := dir.extended (a_name).name.to_string_32
						end
						found := True
					else
						base := base.parent
					end
					step := step + 1
				end
				i := i + 1
			end
		end

	directory_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			d: DIRECTORY
		do
			create d.make_with_name (a_path)
			Result := d.exists
		end

	file_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			f: RAW_FILE
		do
			create f.make_with_name (a_path)
			Result := f.exists
		end

end
