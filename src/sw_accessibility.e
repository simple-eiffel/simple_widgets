note
	description: "[
		The UI Automation bridge in the toolkit's vocabulary (GW-14): the
		machinery and the control-type constants live in simple_shell's
		SHELL_ACCESSIBILITY; SW_WINDOW publishes its widget tree through
		this facade (never reach through to SHELL_* names).

		A value handed over as an IMMUTABLE_STRING_32 is converted to its
		native form once and the conversion kept, by node, for as long as
		each publish hands over the very same object (it cannot have
		changed); any other value is converted on every publish, as
		before. SW_TEXT_BOX hands over its text that way.
	]"
	performance: "[
		2026-11-10: while a UI Automation client listens, a window
		publishes on every frame. Before the kept conversion a text box
		holding 388,893 characters cost 10 to 14 milliseconds a frame
		there (a copy of the text and its conversion each time).
	]"

class
	SW_ACCESSIBILITY

inherit
	SHELL_ACCESSIBILITY
		redefine
			begin_tree, add_node, commit, disable
		end

feature -- Publishing

	begin_tree (a_capacity: INTEGER)
			-- <Precursor>
		do
			Precursor (a_capacity)
			next_natives.wipe_out
		end

	add_node (a_id, a_parent, a_role: INTEGER; a_name: READABLE_STRING_GENERAL;
			a_value: detachable READABLE_STRING_GENERAL; a_x, a_y, a_w, a_h: REAL_64;
			a_focusable, a_enabled: BOOLEAN)
			-- <Precursor>
			-- An immutable value is converted to its native form once; the
			-- conversion serves for as long as each publish hands over the
			-- very same object for node `a_id'.
		local
			l_name: NATIVE_STRING
			l_kept: TUPLE [source: IMMUTABLE_STRING_32; native: NATIVE_STRING]
		do
			if attached {IMMUTABLE_STRING_32} a_value as al_value then
				if attached natives.item (a_id) as al_found and then al_found.source = al_value then
					l_kept := al_found
				else
					l_kept := [al_value, create {NATIVE_STRING}.make (al_value)]
					conversions := conversions + 1
				end
				next_natives.force (l_kept, a_id)
				create l_name.make (a_name)
				if c_add (a_id, a_parent, a_role, a_focusable.to_integer, a_enabled.to_integer,
					a_x, a_y, a_w, a_h, l_name.item, l_kept.native.item) /= 0
				then
					rows_added := rows_added + 1
				end
			else
				Precursor (a_id, a_parent, a_role, a_name, a_value, a_x, a_y, a_w, a_h, a_focusable, a_enabled)
			end
		end

	commit (a_hwnd: POINTER)
			-- <Precursor>
			-- The conversions of nodes left out of this table are dropped.
		local
			l_spent: like natives
		do
			Precursor (a_hwnd)
			l_spent := natives
			natives := next_natives
			next_natives := l_spent
			next_natives.wipe_out
		end

	disable
			-- <Precursor>
		do
			Precursor
			natives.wipe_out
			next_natives.wipe_out
		end

feature -- Measurement

	conversions: INTEGER
			-- How many times an immutable value has been converted to its
			-- native form (a publish that is handed the same object again
			-- converts nothing).

feature -- Shared vocabulary (W10)

	role_name (a_role: INTEGER): STRING_32
			-- The role name simple_gui's shared tests read for UI Automation control type
			-- `a_role': GTK's accessible-role nicknames ("button", "text-box", "label",
			-- "list", "list-item", "menu-bar", "menu-item", "menu", "img", "checkbox",
			-- "slider", "application" ...). Panes, groups and custom controls are
			-- "generic", which a tree reading leaves out, as GTK's does. A table reads as GTK
			-- 4.14's column view does (probed): "tree-grid", its rows "row", headers
			-- "column-header".
		do
			inspect a_role
			when Role_button then Result := "button"
			when Role_edit then Result := "text-box"
			when Role_text then Result := "label"
			when Role_list then Result := "list"
			when Role_list_item then Result := "list-item"
			when Role_menu_bar then Result := "menu-bar"
			when Role_menu_item then Result := "menu-item"
			when Role_menu then Result := "menu"
			when Role_image then Result := "img"
			when Role_check_box then Result := "checkbox"
			when Role_radio_button then Result := "radio"
			when Role_slider then Result := "slider"
			when Role_combo_box then Result := "combo-box"
			when Role_hyperlink then Result := "link"
			when Role_progress_bar then Result := "progress-bar"
			when Role_scroll_bar then Result := "scrollbar"
			when Role_spinner then Result := "spin-button"
			when Role_status_bar then Result := "status"
			when Role_tab then Result := "tab-list"
			when Role_tab_item then Result := "tab"
			when Role_tool_bar then Result := "toolbar"
			when Role_tool_tip then Result := "tooltip"
			when Role_tree then Result := "tree"
			when Role_tree_item then Result := "tree-item"
			when Role_data_grid, Role_table then Result := "tree-grid"
			when Role_data_item then Result := "row"
			when Role_header then Result := "row"
			when Role_header_item then Result := "column-header"
			when Role_document then Result := "document"
			when Role_separator then Result := "separator"
			when Role_group then Result := "group"
			when Role_calendar then Result := "grid"
			when Role_window then Result := "application"
			else
				Result := "generic"
			end
		ensure
			named: not Result.is_empty
		end

feature {NONE} -- Kept conversions

	natives: HASH_TABLE [TUPLE [source: IMMUTABLE_STRING_32; native: NATIVE_STRING], INTEGER]
			-- By node id: the immutable values of the table published last,
			-- each with its native form.
		attribute
			create Result.make (4)
		end

	next_natives: like natives
			-- The same for the table being built.
		attribute
			create Result.make (4)
		end

end
