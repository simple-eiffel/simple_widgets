note
	description: "[
		The lens seam, release edition: every hook is a no-op and
		names no inspector class at all. Dev targets OVERRIDE this
		class from the devkit cluster with the real lens - so a
		finalized release build does not merely skip the inspector,
		it never compiles it. (The vehicle debug-clauses could not
		be: finalize strips those.)
	]"

class
	DEV_LENS

feature -- Status

	is_active (a_dev_mode_on: BOOLEAN): BOOLEAN
			-- Release lens: never.
		do
		end

feature -- Hooks

	reveal (a_window: SW_WINDOW; a_subject: SW_WIDGET; a_x, a_y: INTEGER)
		do
		end

	draw_chip (a_p: SW_PAINTER; a_theme: SW_THEME; a_hovered: SW_WIDGET)
		do
		end

end
