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

end
