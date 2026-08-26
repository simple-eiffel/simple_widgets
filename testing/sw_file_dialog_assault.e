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
			-- The drives row's engine: probed roots are real, and
			-- hopping to one relands the listing there.
		local
			fd: SW_FILE_DIALOG
		do
			build_fixture
			create fd.make_open (fixture_root)
			assert ("this machine has drive roots", not fd.available_drives.is_empty)
			across
				fd.available_drives as d
			loop
				assert ("root is X-colon-backslash", d.count = 3)
				assert ("root exists", (create {DIRECTORY}.make (d)).exists)
			end
			fd.go_to_drive (fd.available_drives.first)
			assert ("landed on the root",
				fd.current_dir.same_string (fd.available_drives.first))
			assert ("listing refreshed", fd.entry_count >= 1)
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

end
