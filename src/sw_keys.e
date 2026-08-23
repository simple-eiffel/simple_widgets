note
	description: "[
		Keyboard modifier state, as a SURFACE-layer service - widgets
		ask here (like SW_CLIPBOARD) so they never declare externals.
		The machinery lives in simple_shell; this facade keeps the
		toolkit vocabulary (never reach through to SHELL_* names).
	]"

class
	SW_KEYS

inherit
	SHELL_KEYS

end
