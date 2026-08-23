note
	description: "[
		The file manager composite the roadmap promised: a lazy
		directory TREE on the left (SW_TREE over plain base
		DIRECTORY, subdirectories on demand), the selected folder's
		FILES on the right (SW_LIST, virtualized), a path label
		telling the truth about where you stand, and on_open firing
		with the full path when a file is activated. The listing
		engine (subdirs, refresh_listing, file_count/file_name) is
		public and assaulted against a real temp fixture - the same
		honesty the file dialog's tests established.
	]"

class
	SW_FILE_MANAGER

inherit
	SW_SPLITTER
		rename
			make as make_split
		end

create
	make

feature {NONE} -- Initialization

	make (a_root: READABLE_STRING_GENERAL)
		local
			right_col: SW_COLUMN
			roots: ARRAYED_LIST [STRING_32]
		do
				-- every attached attribute lands before any agent
				-- makes Current escape (the VEVI discipline)
			create root_dir.make_from_string_general (a_root)
			create selected_dir.make_from_string_general (a_root)
			create file_names.make (16)
			create dir_tree.make (300.0)
			create files_list.make (300.0)
			create path_label.make_mono (root_dir)
			create right_col.make
			right_col := right_col.with_gap (4.0)
			right_col.put (path_label.as_muted)
			right_col.put (files_list.growing)
			make_split (dir_tree, right_col)
			set_ratio (0.34)
				-- agents from here down
			dir_tree.set_label (agent dir_label)
			dir_tree.set_children (agent dir_children)
			dir_tree.set_on_select (agent on_dir_selected)
			create roots.make (1)
			roots.extend (root_dir.twin)
			dir_tree.set_roots (roots)
			files_list.set_row_height (26.0)
			files_list.set_row_renderer (agent render_file_row)
			files_list.set_on_activate (agent on_file_activated)
			refresh_listing
		ensure
			rooted: selected_dir.same_string (root_dir)
		end

feature -- Access

	root_dir: STRING_32

	selected_dir: STRING_32

	on_open: detachable PROCEDURE [STRING_32]
			-- Fired with the FULL path of an activated file.

	file_count: INTEGER
		do
			Result := file_names.count
		end

	file_name (a_i: INTEGER): STRING_32
		require
			in_range: a_i >= 1 and a_i <= file_count
		do
			Result := file_names.i_th (a_i)
		end

	subdirs (a_path: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- The FULL paths of a directory's subdirectories, sorted;
			-- empty on unreadable paths. Public engine math.
		local
			d: DIRECTORY
			sub: DIRECTORY
			pth: PATH
		do
			create Result.make (8)
			create d.make (a_path.to_string_8)
			if d.exists then
				across
					d.entries as e
				loop
					if not e.is_current_symbol and then not e.is_parent_symbol then
						create pth.make_from_string (a_path)
						pth := pth.extended_path (e)
						create sub.make (pth.name.to_string_8)
						if sub.exists then
							Result.extend (pth.name.to_string_32)
						end
					end
				end
				sort_strings (Result)
			end
		end

feature -- Element change

	set_on_open (a_action: PROCEDURE [STRING_32])
		do
			on_open := a_action
		ensure
			set: on_open = a_action
		end

	refresh_listing
			-- Reload the FILES of selected_dir, sorted.
		local
			d: DIRECTORY
			sub: DIRECTORY
			pth: PATH
		do
			file_names.wipe_out
			create d.make (selected_dir.to_string_8)
			if d.exists then
				across
					d.entries as e
				loop
					if not e.is_current_symbol and then not e.is_parent_symbol then
						create pth.make_from_string (selected_dir)
						pth := pth.extended_path (e)
						create sub.make (pth.name.to_string_8)
						if not sub.exists then
							file_names.extend (e.name.to_string_32)
						end
					end
				end
				sort_strings (file_names)
			end
			files_list.set_row_count (file_names.count)
			path_label.set_text (selected_dir)
		end

	enter_directory (a_path: READABLE_STRING_GENERAL)
		do
			create selected_dir.make_from_string_general (a_path)
			refresh_listing
		ensure
			entered: selected_dir.same_string_general (a_path)
		end

feature {NONE} -- Organs

	dir_tree: SW_TREE [STRING_32]

	files_list: SW_LIST

	path_label: SW_LABEL

	file_names: ARRAYED_LIST [STRING_32]

	dir_label (a_path: STRING_32): STRING_32
			-- The last component, or the whole root.
		local
			pth: PATH
		do
			create pth.make_from_string (a_path)
			if attached pth.entry as e then
				Result := e.name.to_string_32
			else
				Result := a_path.twin
			end
		end

	dir_children (a_path: STRING_32): ARRAYED_LIST [STRING_32]
		do
			Result := subdirs (a_path)
		end

	on_dir_selected (a_path: STRING_32)
		do
			enter_directory (a_path)
		end

	render_file_row (a_p: SW_PAINTER; a_row: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			if a_row >= 1 and a_row <= file_names.count then
				a_p.font ({SW_PAINTER}.Role_ui, 12.5, False)
				a_p.set_color (a_p.theme.ink)
				a_p.text (a_x + 8.0, a_y + a_h - 8.0, file_names.i_th (a_row))
			end
		end

	on_file_activated (a_row: INTEGER)
		local
			pth: PATH
		do
			if a_row >= 1 and a_row <= file_names.count
				and then attached on_open as a
			then
				create pth.make_from_string (selected_dir)
				pth := pth.extended (file_names.i_th (a_row))
				a.call (pth.name.to_string_32)
			end
		end

	sort_strings (a_list: ARRAYED_LIST [STRING_32])
			-- Simple insertion sort, case-blind.
		local
			i, j: INTEGER
			v: STRING_32
		do
			from
				i := 2
			until
				i > a_list.count
			loop
				v := a_list.i_th (i)
				from
					j := i - 1
				until
					j < 1 or else a_list.i_th (j).as_lower <= v.as_lower
				loop
					a_list.put_i_th (a_list.i_th (j), j + 1)
					j := j - 1
				end
				a_list.put_i_th (v, j + 1)
				i := i + 1
			end
		end

invariant
	paths_attached: root_dir /= Void and selected_dir /= Void
	names_attached: file_names /= Void

end
