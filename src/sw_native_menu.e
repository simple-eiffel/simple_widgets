note
	description: "[
		The native right-click menu for text controls - the one users
		already know. A SURFACE-layer service, native in v1 the way the
		periphery of any young toolkit is; a drawn menu can replace it
		later without touching any caller.
	]"

class
	SW_NATIVE_MENU

feature -- Commands

	Cmd_none: INTEGER = 0
	Cmd_cut: INTEGER = 1
	Cmd_copy: INTEGER = 2
	Cmd_paste: INTEGER = 3
	Cmd_select_all: INTEGER = 4

feature -- Operation

	text_context_menu (a_can_cut, a_can_copy, a_can_paste, a_can_select: BOOLEAN): INTEGER
			-- Show the standard text menu at the cursor; the chosen
			-- command, or Cmd_none.
		do
			Result := c_text_menu (b (a_can_cut), b (a_can_copy), b (a_can_paste), b (a_can_select))
		ensure
			known_command: Result >= Cmd_none and Result <= Cmd_select_all
		end

feature {NONE} -- Implementation

	b (a_flag: BOOLEAN): INTEGER
		do
			if a_flag then
				Result := 1
			end
		end

feature {NONE} -- Externals

	c_text_menu (a_cut, a_copy, a_paste, a_select: INTEGER): INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_text_menu((int)$a_cut, (int)$a_copy, (int)$a_paste, (int)$a_select);"
		end

end
