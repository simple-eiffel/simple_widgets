note
	description: "[
		The devkit override: this cluster replaces src/dev_flags.e
		in dev targets (ECF <override>), turning the inspector's
		compile-time gate ON. Release targets never see this file.
	]"

class
	DEV_FLAGS

feature -- Access

	Dev_build: BOOLEAN = True
			-- This is a dev build: the lens may exist.

end
