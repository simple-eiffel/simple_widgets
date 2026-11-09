note
	description: "[
		A system appearance that answers light, no contrast and full motion, and counts every
		question: a hosted SW_WINDOW must never ask (on macOS the real question goes through
		simple_shell's application and replaces its main menu).
	]"

class
	TEST_COUNTING_APPEARANCE

inherit
	SHELL_APPEARANCE
		redefine
			system_prefers_dark, system_high_contrast, system_reduces_motion
		end

feature -- Access

	asks: INTEGER
			-- Questions put so far.

	system_prefers_dark: BOOLEAN
		do
			asks := asks + 1
		end

	system_high_contrast: BOOLEAN
		do
			asks := asks + 1
		end

	system_reduces_motion: BOOLEAN
		do
			asks := asks + 1
		end

end
