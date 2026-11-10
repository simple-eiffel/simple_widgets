note
	description: "[
		GUI_ICON's names and the SW_PAINTER glyph that draws each: the one table behind the
		icons of SW_TEXT_LIST rows and SW_GRID_VIEW cells.
	]"

deferred class
	SW_ICON_NAMES

feature -- Icons

	glyph_of_icon_name (a_name: READABLE_STRING_GENERAL): INTEGER
			-- The SW_PAINTER glyph that draws icon `a_name' (GUI_ICON's vocabulary); 0 for an
			-- unknown name.
		local
			l_names: ARRAY [STRING_32]
			i: INTEGER
		do
			l_names := icon_names
			from i := l_names.lower until i > l_names.upper or Result > 0 loop
				if l_names [i].same_string_general (a_name) then
					Result := icon_glyphs [i - l_names.lower + icon_glyphs.lower]
				end
				i := i + 1
			end
		ensure
			known: Result >= 0 and Result <= {SW_PAINTER}.Glyph_last
		end

feature {NONE} -- Icon tables

	icon_names: ARRAY [STRING_32]
			-- GUI_ICON's names, in its order.
		once
			Result := <<
				{STRING_32} "add", {STRING_32} "remove", {STRING_32} "close", {STRING_32} "check",
				{STRING_32} "chevron-right", {STRING_32} "chevron-left", {STRING_32} "chevron-up", {STRING_32} "chevron-down",
				{STRING_32} "back", {STRING_32} "forward",
				{STRING_32} "search", {STRING_32} "settings", {STRING_32} "delete", {STRING_32} "edit",
				{STRING_32} "folder", {STRING_32} "document", {STRING_32} "open", {STRING_32} "save",
				{STRING_32} "copy", {STRING_32} "cut", {STRING_32} "paste", {STRING_32} "undo", {STRING_32} "redo",
				{STRING_32} "refresh",
				{STRING_32} "play", {STRING_32} "pause", {STRING_32} "stop", {STRING_32} "more", {STRING_32} "menu",
				{STRING_32} "info", {STRING_32} "warning", {STRING_32} "error", {STRING_32} "help",
				{STRING_32} "star", {STRING_32} "picture", {STRING_32} "home", {STRING_32} "user", {STRING_32} "mail",
				{STRING_32} "calendar", {STRING_32} "clock", {STRING_32} "lock", {STRING_32} "bell",
				{STRING_32} "download", {STRING_32} "upload", {STRING_32} "print", {STRING_32} "filter", {STRING_32} "sort"
			>>
		ensure
			forty_seven: Result.count = 47
		end

	icon_glyphs: ARRAY [INTEGER]
			-- The SW_PAINTER glyph for each of `icon_names'.
		once
			Result := <<1, 2, 3, 4, 5, 7, 8, 6, 7, 5, 9, 10, 11, 12, 13, 14, 29, 30, 31, 32, 33, 34, 35, 15,
				16, 17, 18, 19, 20, 21, 22, 25, 36, 26, 28, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48>>
		ensure
			one_each: Result.count = icon_names.count
		end

end
