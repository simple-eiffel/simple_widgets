note
	description: "[
		The printers, as the toolkit names them (GW-20): a SURFACE-layer
		service so applications never declare the externals. The machinery
		lives in simple_shell (SHELL_PRINTER); SW_PRINT_JOB prints through
		it.
	]"

class
	SW_PRINTER

inherit
	SHELL_PRINTER

create
	make

end
