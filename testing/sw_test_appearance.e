note
	description: "[
		A stand-in for Windows' appearance settings (GW-16 tests): answers
		light/dark, the high-contrast switch and the system colors it is
		told, so SW_WINDOW's following is proven without touching Windows.
	]"

class
	SW_TEST_APPEARANCE

inherit
	SHELL_APPEARANCE
		redefine
			system_prefers_dark, system_high_contrast, system_color
		end

feature -- Access

	system_prefers_dark: BOOLEAN

	system_high_contrast: BOOLEAN

	system_color (a_index: INTEGER): NATURAL_32
		do
			if a_index = Color_window then
				Result := window
			elseif a_index = Color_window_text then
				Result := window_text
			elseif a_index = Color_highlight then
				Result := highlight
			elseif a_index = Color_highlight_text then
				Result := highlight_text
			elseif a_index = Color_button_face then
				Result := button_face
			elseif a_index = Color_hotlight then
				Result := hotlight
			end
		end

	window, window_text, highlight, highlight_text, button_face, hotlight: NATURAL_32

feature -- Element change

	set_dark (a_dark: BOOLEAN)
		do
			system_prefers_dark := a_dark
		end

	set_high_contrast (a_on: BOOLEAN)
		do
			system_high_contrast := a_on
		end

	set_palette (a_window, a_window_text, a_highlight, a_highlight_text, a_button_face, a_hotlight: NATURAL_32)
		do
			window := a_window
			window_text := a_window_text
			highlight := a_highlight
			highlight_text := a_highlight_text
			button_face := a_button_face
			hotlight := a_hotlight
		end

end
