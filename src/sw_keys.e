note
	description: "[
		Keyboard modifier state, as a SURFACE-layer service - widgets
		ask here (like SW_CLIPBOARD) so they never declare externals.
		The machinery lives in simple_shell; this facade keeps the
		toolkit vocabulary (never reach through to SHELL_* names).

		SIMULATION (0.22.0). `simulate' makes every SW_KEYS answer fixed
		states until `stop_simulating'. A headless test run sets "nothing
		held" first, so a key held on the real keyboard while the tests
		run can no longer turn a test's click into a Ctrl+click or a
		Shift+click (two such tests failed at random on 2026-10-24/25).
		A test that needs a modifier simulates it.
	]"

class
	SW_KEYS

inherit
	SHELL_KEYS
		redefine
			shift_down, control_down, alt_down
		end

feature -- Status

	shift_down: BOOLEAN
			-- Shift: the simulated state while simulating, else the
			-- physical one.
		do
			if attached simulation.item as al_s then
				Result := al_s.shift
			else
				Result := Precursor
			end
		end

	control_down: BOOLEAN
			-- Ctrl, likewise.
		do
			if attached simulation.item as al_s then
				Result := al_s.control
			else
				Result := Precursor
			end
		end

	alt_down: BOOLEAN
			-- Alt, likewise.
		do
			if attached simulation.item as al_s then
				Result := al_s.alt
			else
				Result := Precursor
			end
		end

	is_simulating: BOOLEAN
			-- Are the states simulated?
		do
			Result := simulation.item /= Void
		end

feature -- Simulation

	simulate (a_shift, a_control, a_alt: BOOLEAN)
			-- From now on every SW_KEYS answers these states.
		do
			simulation.put ([a_shift, a_control, a_alt])
		ensure
			simulating: is_simulating
			shift_set: shift_down = a_shift
			control_set: control_down = a_control
			alt_set: alt_down = a_alt
		end

	stop_simulating
			-- Back to the physical keyboard.
		do
			simulation.put (Void)
		ensure
			physical: not is_simulating
		end

feature {NONE} -- Implementation

	simulation: CELL [detachable TUPLE [shift, control, alt: BOOLEAN]]
			-- The simulated states, shared by every SW_KEYS; Void: none.
		once
			create Result.put (Void)
		end

end
