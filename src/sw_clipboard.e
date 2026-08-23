note
	description: "[
		The system clipboard, as text. A SURFACE-layer service: widgets
		use it so applications never declare the externals. The
		machinery lives in simple_shell; this facade keeps the toolkit
		vocabulary (never reach through to SHELL_* names).
	]"

class
	SW_CLIPBOARD

inherit
	SHELL_CLIPBOARD

end
