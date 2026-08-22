note
	description: "[
		Keyboard modifier state, as a SURFACE-layer service - widgets
		ask here (like SW_CLIPBOARD) so they never declare externals.
	]"

class
	SW_KEYS

feature -- Status

	shift_down: BOOLEAN
		do
			Result := c_shift_down = 1
		end

feature {NONE} -- Externals

	c_shift_down: INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_shift_down();"
		end

end
