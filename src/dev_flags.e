note
	description: "[
		The release truth: no dev machinery. Targets that want the
		lens OVERRIDE this class from a devkit cluster (see
		sw_demo's ECF): same class name, Dev_build = True. Combined
		with dead-code removal, finalized release builds compile
		none of the inspector paths - the compile-time gate that
		debug-clauses could not deliver (finalize strips them).
	]"

class
	DEV_FLAGS

feature -- Access

	Dev_build: BOOLEAN = False
			-- Release builds say no; the devkit override says yes.

end
