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

	chosen_path: STRING_32
			-- The current directory joined with the name box's text.
		local
			pth: PATH
		do
			create pth.make_from_string (current_dir)
			if not name_box.text.is_empty then
				pth := pth.extended (name_box.text)
			end
			Result := pth.name
		end

feature -- Element change

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
			-- Only list files ending with `a_suffix' (e.g. ".png").
		do
			create extension_filter.make_from_string_general (a_suffix)
			extension_filter.to_lower
			load_directory (current_dir)
		end

feature {NONE} -- Engine

	entry_names: ARRAYED_LIST [STRING_32]

	entry_is_dir: ARRAYED_LIST [BOOLEAN]

	path_label: SW_LABEL

	entries_list: SW_LIST

	name_box: SW_TEXT_BOX

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
						elseif extension_filter.is_empty or else nm.as_lower.ends_with (extension_filter) then
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
		do
			if not name_box.text.is_empty and then attached on_accept as a then
				a.call (chosen_path)
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
