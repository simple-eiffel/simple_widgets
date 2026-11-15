note
	description: "[
		Assault on SW_FILE_DIALOG against a real fixture directory it
		builds and tears down itself: listing order, kinds, filter,
		navigation both ways, and the accept path's full-path promise.
	]"

class
	SW_FILE_DIALOG_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_short_window_keeps_the_buttons_in_reach
			-- simple_widgets #75: laid out shorter than its natural height (a sheet in a small
			-- window), the dialog's list gives the height back, so every child, the name box and
			-- the Save and Cancel row included, stays inside it; a 560 sheet in a 440 window is
			-- given a width that fits.
		local
			fd: SW_FILE_DIALOG
			w: SW_WINDOW
			l_short, l_bottom: REAL_64
		do
			build_fixture
			create fd.make_save (fixture_root, "report.pdf")
			fd.set_bounds (0.0, 0.0, 400.0, 1000.0)
			fd.arrange (headless_painter)
			l_short := fd.children.last.y + fd.children.last.height - 200.0
			assert ("natural height is more than the short box", l_short > 0.0)
				-- #75's case: a 440 by 450 window; a centered sheet's content gets 450 - 160
			fd.set_bounds (0.0, 0.0, 400.0, 290.0)
			fd.arrange (headless_painter)
			across fd.children as c loop
				l_bottom := c.y + c.height
				assert ("inside: " + c.generating_type.name.to_string_8 + " ends at " + l_bottom.out, l_bottom <= 290.0 + 0.5)
			end
			fd.set_bounds (0.0, 0.0, 400.0, 1.0)
			fd.arrange (headless_painter)
			print ("    the dialog's least height: " + (fd.children.last.y + fd.children.last.height).out + "%N")
			create w.make ("small", 0, 0, 440, 200, create {SW_THEME}.make_light)
			assert ("a 560 sheet fits a 440 window: " + w.sheet_content_width (560.0).out, w.sheet_content_width (560.0) + 32.0 <= 440.0)
			assert ("a wide window keeps the width asked", w.sheet_content_width (300.0) = 300.0)
			drop_fixture
		end

	test_listing_order_and_kinds
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			assert_integers_equal ("dotdot + dir + three files", 5, fd.entry_count)
			assert ("dotdot first", fd.entry_name (1).same_string_general (".."))
			assert ("dotdot is a directory", fd.is_entry_directory (1))
			assert ("directory before files", fd.is_entry_directory (2)
				and fd.entry_name (2).same_string_general ("beta_dir"))
			assert ("case-insensitive sort: A before b",
				fd.entry_name (3).same_string_general ("A.txt")
				and fd.entry_name (4).same_string_general ("b.txt"))
			assert ("png last", fd.entry_name (5).same_string_general ("zz.png"))
			assert ("files are files", not fd.is_entry_directory (3)
				and not fd.is_entry_directory (4) and not fd.is_entry_directory (5))
			drop_fixture
		end

	test_extension_filter
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			fd.set_extension_filter (".txt")
			assert_integers_equal ("png filtered away", 4, fd.entry_count)
			assert ("directories always survive the filter", fd.is_entry_directory (2))
			drop_fixture
		end

	test_drive_roots_and_hop
			-- The drives row's engine: on Windows, mask-derived roots
			-- (never probed - probing dead letters blocks for minutes);
			-- on Linux and macOS the one root "/". Hopping to one relands
			-- the listing there.
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			assert ("this machine has roots", not fd.available_drives.is_empty)
			across
				fd.available_drives as d
			loop
				if {PLATFORM}.is_windows then
					assert ("root is X-colon-backslash", d.count = 3)
				else
					assert ("the root is /", d.same_string_general ("/"))
				end
			end
			assert ("the system root is among them",
				across fd.available_drives as d some d.same_string (system_root) end)
			fd.go_to_drive (system_root)
			assert ("landed on the root", fd.current_dir.same_string (system_root))
			assert ("listing refreshed", fd.entry_count >= 1)
			drop_fixture
		end

	test_typed_absolute_directory_navigates
			-- Larry's repro 2026-08-26: type "C:\" and press Open -
			-- the dialog must hop there, not glue it onto current_dir.
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			fd.type_name (system_root)
			fd.press_accept
			assert ("hopped to the root", fd.current_dir.same_string (system_root))
			assert ("listing refreshed there", fd.entry_count >= 1)
			drop_fixture
		end

	test_typed_bare_drive_normalizes
			-- Windows: "C:" is a bare drive and lands on its root. Linux and macOS: "C:" is an
			-- ordinary file name, so it stays relative to the folder shown.
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			fd.type_name ({STRING_32} "C:")
			if {PLATFORM}.is_windows then
				fd.press_accept
				assert ("bare drive lands on its root", fd.current_dir.same_string_general ("C:\"))
			else
				assert ("a plain name here", fd.chosen_path.ends_with ({STRING_32} "/C:"))
			end
			drop_fixture
		end

	test_folder_mode_lists_folders_and_chooses
			-- make_folder lists only folders; Choose with an empty name box accepts the folder
			-- shown, and with a child folder's name accepts that child.
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_folder (fixture_root)
			assert ("folder mode", fd.is_folder_mode and not fd.is_save_mode)
			assert_integers_equal ("dotdot + the one folder, no files", 2, fd.entry_count)
			assert ("the folder", fd.entry_name (2).same_string_general ("beta_dir"))
			create accepted.make_empty
			fd.set_on_accept (agent record_accept)
			fd.press_accept
			assert ("the folder shown", accepted.same_string (fd.current_dir))
			fd.type_name ({STRING_32} "beta_dir")
			fd.press_accept
			assert ("the typed child", accepted.as_lower.ends_with ({STRING_32} "beta_dir"))
			drop_fixture
		end

	system_file: STRING_32
			-- An absolute file path on this platform.
		do
			if {PLATFORM}.is_windows then
				Result := {STRING_32} "C:\Windows\win.ini"
			else
				Result := {STRING_32} "/etc/hosts"
			end
		end

	system_root: STRING_32
			-- This platform's root: C:\ on Windows, / elsewhere.
		do
			if {PLATFORM}.is_windows then
				Result := {STRING_32} "C:\"
			else
				Result := {STRING_32} "/"
			end
		end

	test_typed_relative_directory_descends
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			fd.type_name ({STRING_32} "beta_dir")
			fd.press_accept
			assert ("descended into the typed child",
				fd.current_dir.as_lower.ends_with ({STRING_32} "beta_dir"))
			assert ("name box cleared after navigating", fd.chosen_path.same_string (fd.current_dir))
			drop_fixture
		end

	test_typed_absolute_file_accepts
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			create accepted.make_empty
			fd.set_on_accept (agent record_accept)
			fd.type_name (system_file)
			fd.press_accept
			assert ("typed absolute file accepted verbatim", accepted.same_string (system_file))
			drop_fixture
		end

	test_navigation_down_and_up
		local
			fd: SW_FILE_DIALOG
			home: STRING_32
		do
			build_fixture
			create fd.make_open (fixture_root)
			home := fd.current_dir
			fd.open_entry (2)
			assert ("descended", fd.current_dir.as_lower.ends_with ({STRING_32} "beta_dir"))
			assert_integers_equal ("child holds one file", 2, fd.entry_count)
			fd.open_entry (1)
			assert ("left the child", not fd.current_dir.as_lower.ends_with ({STRING_32} "beta_dir"))
			assert ("home remembered for the record", not home.is_empty)
			drop_fixture
		end

	test_accept_delivers_full_path
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			create accepted.make_empty
			fd.set_on_accept (agent record_accept)
			fd.open_entry (3)
			assert ("accept fired with the file", accepted.as_lower.ends_with ({STRING_32} "a.txt"))
			assert ("path is rooted in the fixture", accepted.as_lower.has_substring ({STRING_32} "sw_assault_fixture"))
			assert ("chosen_path agrees", fd.chosen_path.same_string (accepted))
			drop_fixture
		end

feature {NONE} -- Fixture

	fixture_root: STRING_32
		once
			Result := {STRING_32} "sw_assault_fixture"
		end

	build_fixture
		local
			d: DIRECTORY
		do
			create d.make (fixture_root)
			if not d.exists then
				d.create_dir
			end
			create d.make (fixture_root + {STRING_32} "/beta_dir")
			if not d.exists then
				d.create_dir
			end
			write_file (fixture_root + {STRING_32} "/b.txt")
			write_file (fixture_root + {STRING_32} "/A.txt")
			write_file (fixture_root + {STRING_32} "/zz.png")
			write_file (fixture_root + {STRING_32} "/beta_dir/inner.txt")
		end

	write_file (a_path: STRING_32)
		local
			f: PLAIN_TEXT_FILE
		do
			create f.make_create_read_write (a_path)
			f.put_string ("assault")
			f.close
		end

	drop_fixture
		local
			d: DIRECTORY
		do
			create d.make (fixture_root)
			if d.exists then
				d.recursive_delete
			end
		end

	accepted: STRING_32
		attribute
			create Result.make_empty
		end

	record_accept (a_path: STRING_32)
		do
			accepted := a_path
		end


feature {NONE} -- Painting

	headless_painter: SW_PAINTER
			-- A painter on an off-screen surface, for laying widgets out.
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (800, 600)
			create ctx.make (surf)
			create th.make_light
			create Result.make (ctx, th)
		end

end
