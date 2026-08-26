note
	description: "[
		A drawn file dialog: path, entry list (directories first,
		'..' on top), name box and verbs - a pure SW_COLUMN
		composition shown through the window's sheet layer. Nothing
		native (R7): every pixel is the toolkit's own. Directory
		access is plain base PATH/DIRECTORY, so the toolkit stays
		dependency-free.
	]"

class
	SW_FILE_DIALOG

inherit
	SW_COLUMN

create
	make_open, make_save

feature {NONE} -- Initialization

	make_open (a_start_dir: READABLE_STRING_GENERAL)
		do
			make_dialog (a_start_dir, "")
		ensure
			opening: not is_save_mode
		end

	make_save (a_start_dir, a_suggested: READABLE_STRING_GENERAL)
		do
			is_save_mode := True
			make_dialog (a_start_dir, a_suggested)
		ensure
			saving: is_save_mode
		end

	make_dialog (a_start_dir, a_name: READABLE_STRING_GENERAL)
		local
			verbs: SW_ROW
			ttl: SW_LABEL
		do
			make
			padding := 6.0
			gap := 10.0
			create current_dir.make_from_string_general (a_start_dir)
			create extension_filter.make_empty
			create entry_names.make (64)
			create entry_is_dir.make (64)
			create path_label.make_mono ("")
			create entries_list.make (260.0)
			create name_box.make_single_line (a_name)
				-- every attached attribute is set: agents are safe now
			entries_list.set_row_height (28.0)
			entries_list.set_row_renderer (agent render_entry)
			entries_list.set_on_select (agent on_entry_selected)
			entries_list.set_on_activate (agent on_entry_activated)
			name_box.set_spellcheck (False)
			create ttl.make (if is_save_mode then "Save File" else "Open File" end,
				{SW_PAINTER}.Role_ui, 17.0, True)
			put (ttl)
			put (path_label.as_muted)
			build_drives_row
			put (entries_list)
			put (name_box)
			create verbs.make
			verbs.put (create {SW_BUTTON}.make_primary (
				if is_save_mode then "Save" else "Open" end, agent do_accept))
			verbs.put (create {SW_BUTTON}.make ("Cancel", agent do_cancel))
			put (verbs)
			load_directory (current_dir)
		end

feature -- Access

	current_dir: STRING_32

	is_save_mode: BOOLEAN

	extension_filter: STRING_32
			-- Lower-case suffix files must carry; empty = show all.

	on_accept: detachable PROCEDURE [STRING_32]

	on_cancel: detachable PROCEDURE

	entry_count: INTEGER
			-- How many rows the entry list currently shows.
		do
			Result := entry_names.count
		ensure
			at_least_dotdot: Result >= 1
		end

	entry_name (a_i: INTEGER): STRING_32
		require
			in_range: a_i >= 1 and a_i <= entry_count
		do
			Result := entry_names.i_th (a_i)
		end

	is_entry_directory (a_i: INTEGER): BOOLEAN
		require
			in_range: a_i >= 1 and a_i <= entry_count
		do
			Result := entry_is_dir.i_th (a_i)
		end

	available_drives: ARRAYED_LIST [STRING_32]
			-- Drive roots that exist right now ("C:\", "D:\", ...) -
			-- probed A: through Z: with plain base DIRECTORY, so the
			-- toolkit stays dependency-free. Empty on platforms
			-- without drive letters (and the drives row then never
			-- appears).
		local
			i: INTEGER
			l_root: STRING_32
		do
			create Result.make (8)
			from
				i := 0
			until
				i > 25
			loop
				create l_root.make (3)
				l_root.append_code ((65 + i).to_natural_32)
				l_root.append_string_general (":\")
				if (create {DIRECTORY}.make (l_root)).exists then
					Result.extend (l_root)
				end
				i := i + 1
			end
		ensure
			roots_shaped: across Result as r all r.count = 3 end
		end

	chosen_path: STRING_32
			-- The name box's text joined onto the current directory -
			-- unless the typed text is already absolute ("C:\..." or
			-- UNC), which wins outright; a bare drive ("C:") is
			-- normalized to its root.
		local
			pth: PATH
			l_typed: STRING_32
		do
			l_typed := name_box.text.twin
			l_typed.left_adjust
			l_typed.right_adjust
			if is_absolute_path (l_typed) then
				if l_typed.count = 2 and then l_typed.item (2).natural_32_code = 58 then
					l_typed.append_code (92) -- "C:" -> "C:\"
				end
				Result := l_typed
			else
				create pth.make_from_string (current_dir)
				if not l_typed.is_empty then
					pth := pth.extended (l_typed)
				end
				Result := pth.name
			end
		end

	is_absolute_path (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Drive-rooted ("X:...") or UNC (two leading backslashes)?
		do
			Result := (a_text.count >= 2 and then a_text.item (2).natural_32_code = 58)
				or else (a_text.count >= 2
					and then a_text.item (1).natural_32_code = 92
					and then a_text.item (2).natural_32_code = 92)
		end

feature -- Element change

	type_name (a_text: READABLE_STRING_GENERAL)
			-- Put `a_text' in the name box, as typing would - hosts
			-- prefill with it, the assault drives with it.
		do
			name_box.set_text (a_text)
		end

	press_accept
			-- The Open/Save verb, driveable by hosts and the assault.
		do
			do_accept
		end

	go_to_drive (a_root: READABLE_STRING_GENERAL)
			-- Jump the listing to a drive root - what a drives-row
			-- chip does; public so hosts and the assault can too.
		require
			drive_exists: (create {DIRECTORY}.make (a_root)).exists
		do
			load_directory (a_root)
		ensure
			landed: current_dir.same_string_general (a_root)
		end

	open_entry (a_i: INTEGER)
			-- Act on entry `a_i' as a double-click would: descend into
			-- directories, accept files.
		require
			in_range: a_i >= 1 and a_i <= entry_count
		do
			on_entry_activated (a_i)
		end

	set_on_accept (a_action: PROCEDURE [STRING_32])
		do
			on_accept := a_action
		ensure
			set: on_accept = a_action
		end

	set_on_cancel (a_action: PROCEDURE)
		do
			on_cancel := a_action
		ensure
			set: on_cancel = a_action
		end

	set_extension_filter (a_suffix: READABLE_STRING_GENERAL)
			-- Only list files matching the pattern set: one suffix
			-- (".png") or several joined by ';' (".png;.jpg" -
			-- '*.png;*.jpg' spelling welcome too).
		local
			part: STRING_32
			i, start: INTEGER
		do
			create extension_filter.make_from_string_general (a_suffix)
			extension_filter.to_lower
			filter_suffixes.wipe_out
			from
				start := 1
				i := 1
			until
				i > extension_filter.count + 1
			loop
				if i > extension_filter.count or else extension_filter.item (i) = ';' then
					if i > start then
						part := extension_filter.substring (start, i - 1)
						part.left_adjust
						part.right_adjust
						if part.starts_with ({STRING_32} "*") then
							part.remove_head (1)
						end
						if not part.is_empty and then part.item (1) /= '.' then
							part.prepend ({STRING_32} ".")
						end
						if not part.is_empty then
							filter_suffixes.extend (part)
						end
					end
					start := i + 1
				end
				i := i + 1
			end
			load_directory (current_dir)
		end

	filter_suffixes: ARRAYED_LIST [STRING_32]
			-- The parsed pattern set; empty = everything passes.
		attribute
			create Result.make (2)
		end

	passes_filter (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_name' survive the pattern set? Public so the
			-- assault can hold the matcher to account directly.
		local
			low: STRING_32
		do
			if filter_suffixes.is_empty then
				Result := True
			else
				low := a_name.to_string_32.as_lower
				across
					filter_suffixes as s
				loop
					Result := Result or low.ends_with (s)
				end
			end
		end

feature {NONE} -- Engine

	entry_names: ARRAYED_LIST [STRING_32]

	entry_is_dir: ARRAYED_LIST [BOOLEAN]

	path_label: SW_LABEL

	entries_list: SW_LIST

	name_box: SW_TEXT_BOX

	build_drives_row
			-- A chip per live drive root, between path and listing;
			-- absent when the platform reports none.
		local
			l_row: SW_ROW
			l_drives: ARRAYED_LIST [STRING_32]
		do
			l_drives := available_drives
			if not l_drives.is_empty then
				create l_row.make
				l_row := l_row.with_gap (6.0)
				across
					l_drives as d
				loop
					l_row.put (create {SW_BUTTON}.make (d.substring (1, 2), agent go_to_drive (d.twin)))
				end
				put (l_row)
			end
		end

	load_directory (a_dir: READABLE_STRING_GENERAL)
			-- Read `a_dir': directories first, both halves sorted,
			-- '..' always on top.
		local
			d, sub: DIRECTORY
			base: PATH
			dirs, files: ARRAYED_LIST [STRING_32]
			nm: STRING_32
		do
			create current_dir.make_from_string_general (a_dir)
			create base.make_from_string (current_dir)
			create dirs.make (16)
			create files.make (32)
			create d.make_with_path (base)
			if d.exists and then d.is_readable then
				across
					d.entries as e
				loop
					nm := e.name
					if not nm.same_string_general (".") and then not nm.same_string_general ("..") then
						create sub.make_with_path (base.extended_path (e))
						if sub.exists then
							dirs.extend (nm)
						elseif passes_filter (nm) then
							files.extend (nm)
						end
					end
				end
			end
			sort_names (dirs)
			sort_names (files)
			entry_names.wipe_out
			entry_is_dir.wipe_out
			entry_names.extend ({STRING_32} "..")
			entry_is_dir.extend (True)
			across
				dirs as s
			loop
				entry_names.extend (s)
				entry_is_dir.extend (True)
			end
			across
				files as s
			loop
				entry_names.extend (s)
				entry_is_dir.extend (False)
			end
			entries_list.set_row_count (entry_names.count)
			entries_list.select_row (0)
			entries_list.scroll_to_row (1)
			path_label.set_text (current_dir)
		ensure
			parallel: entry_names.count = entry_is_dir.count
			dotdot_present: entry_names.count >= 1
		end

	sort_names (a_list: ARRAYED_LIST [STRING_32])
			-- Case-insensitive insertion sort; entry counts are modest.
		local
			i, j: INTEGER
			key: STRING_32
		do
			from
				i := 2
			until
				i > a_list.count
			loop
				key := a_list.i_th (i)
				from
					j := i - 1
				until
					j < 1 or else a_list.i_th (j).as_lower <= key.as_lower
				loop
					a_list.put_i_th (a_list.i_th (j), j + 1)
					j := j - 1
				end
				a_list.put_i_th (key, j + 1)
				i := i + 1
			end
		ensure
			same_count: a_list.count = old a_list.count
		end

	render_entry (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			a_p.font ({SW_PAINTER}.Role_mono, 13.0, False)
			if a_i >= 1 and a_i <= entry_names.count then
				if entry_is_dir.i_th (a_i) then
					a_p.set_color (a_p.theme.accent)
					a_p.text (a_x + 8.0, a_y + a_h - 8.0, entry_names.i_th (a_i) + {STRING_32} "/")
				else
					a_p.set_color (a_p.theme.ink)
					a_p.text (a_x + 8.0, a_y + a_h - 8.0, entry_names.i_th (a_i))
				end
			end
		end

	on_entry_selected (a_i: INTEGER)
			-- Clicking a file offers its name; directories only arm
			-- the double-click.
		do
			if a_i >= 1 and a_i <= entry_names.count and then not entry_is_dir.i_th (a_i) then
				name_box.set_text (entry_names.i_th (a_i))
			end
		end

	on_entry_activated (a_i: INTEGER)
			-- Double-click: descend into directories, accept files.
		local
			base: PATH
		do
			if a_i >= 1 and a_i <= entry_names.count then
				if entry_is_dir.i_th (a_i) then
					create base.make_from_string (current_dir)
					if entry_names.i_th (a_i).same_string_general ("..") then
						load_directory (base.parent.name)
					else
						load_directory (base.extended (entry_names.i_th (a_i)).name)
					end
				else
					name_box.set_text (entry_names.i_th (a_i))
					do_accept
				end
			end
		end

	do_accept
			-- Accept the chosen path - unless it names a directory, in
			-- which case navigate there instead: typing "C:\" then Open
			-- hops drives, typing a child folder's name descends.
		local
			l_target: STRING_32
		do
			if not name_box.text.is_empty then
				l_target := chosen_path
				if (create {DIRECTORY}.make (l_target)).exists then
					name_box.set_text ("")
					load_directory (l_target)
				elseif attached on_accept as a then
					a.call (l_target)
				end
			end
		end

	do_cancel
		do
			if attached on_cancel as a then
				a.call
			end
		end

invariant
	parallel_entries: entry_names.count = entry_is_dir.count
	filter_lower: extension_filter.same_string (extension_filter.as_lower)

end
