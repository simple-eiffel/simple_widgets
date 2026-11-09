note
	description: "[
		The UI Automation bridge in the toolkit's vocabulary (GW-14): the
		machinery and the control-type constants live in simple_shell's
		SHELL_ACCESSIBILITY; SW_WINDOW publishes its widget tree through
		this facade (never reach through to SHELL_* names).
	]"

class
	SW_ACCESSIBILITY

inherit
	SHELL_ACCESSIBILITY

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
			when Role_window then Result := "application"
			else
				Result := "generic"
			end
		ensure
			named: not Result.is_empty
		end

end
