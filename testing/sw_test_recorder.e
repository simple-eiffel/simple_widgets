note
	description: "[
		A test widget that remembers what reached it: clicks, releases,
		keys, characters, wheel turns, focus. Fills its bounds with the
		accent so a frame shows it was drawn.
	]"

class
	SW_TEST_RECORDER

inherit
	SW_WIDGET
		redefine
			handle_click, handle_release, handle_key, handle_char, handle_wheel, accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create typed.make_empty
			grow := 1.0
		end

feature -- What reached it

	clicks, releases, wheel_turns: INTEGER

	keys: ARRAYED_LIST [INTEGER]
		attribute
			create Result.make (4)
		end

	typed: STRING_32

feature -- Input

	accepts_focus: BOOLEAN = True

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			clicks := clicks + 1
			Result := True
		end

	handle_release (a_x, a_y: INTEGER)
		do
			releases := releases + 1
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			keys.extend (a_vk)
		end

	handle_char (a_code: INTEGER)
		do
			typed.append_code (a_code.to_natural_32)
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			wheel_turns := wheel_turns + 1
			Result := True
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 40.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			a_p.set_color (a_p.theme.accent)
			a_p.fill_rect (x, y, width, height)
		end

end
