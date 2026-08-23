note
	description: "[
		A count pill or a bare dot: the notification badge. Counts
		past the cap render as '99+' - the caption query is public
		so the truth is testable.
	]"

class
	SW_BADGE

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make_count, make_dot

feature {NONE} -- Initialization

	make_count (a_count: INTEGER)
		require
			non_negative: a_count >= 0
		do
			count := a_count
		ensure
			kept: count = a_count
		end

	make_dot
		do
			is_dot := True
		ensure
			dotted: is_dot
		end

feature -- Access

	count: INTEGER

	kind: INTEGER
			-- 0 danger (default), 1 accent, 2 success, 3 warning.

	hides_at_zero: BOOLEAN

	set_kind (a_kind: INTEGER)
		require
			known: a_kind >= 0 and a_kind <= 3
		do
			kind := a_kind
		ensure
			set: kind = a_kind
		end

	set_hides_at_zero (a_flag: BOOLEAN)
		do
			hides_at_zero := a_flag
		ensure
			set: hides_at_zero = a_flag
		end

	is_dot: BOOLEAN
			-- A bare presence dot, no number.

	Cap: INTEGER = 99

	caption: STRING_32
			-- What the pill shows: the count, or '99+' past the cap.
		do
			if count > Cap then
				Result := Cap.out.to_string_32 + {STRING_32} "+"
			else
				Result := count.out.to_string_32
			end
		ensure
			capped: count > Cap implies Result.same_string_general (Cap.out + "+")
		end

feature -- Element change

	set_count (a_count: INTEGER)
		require
			non_negative: a_count >= 0
		do
			count := a_count
		ensure
			set: count = a_count
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			if is_dot then
				Result := 10.0
			else
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_chip, True)
				Result := (a_p.advance (caption) + 12.0).max (18.0)
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			if is_dot then
				Result := 10.0
			else
				Result := 18.0
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			if hides_at_zero and then not is_dot and then count = 0 then
					-- zero with the policy on: nothing to say
			else
				inspect kind
				when 1 then
					a_p.set_color (t.accent)
				when 2 then
					a_p.set_color (t.success)
				when 3 then
					a_p.set_color (t.warning)
				else
					a_p.set_color (t.danger)
				end
				if is_dot then
					a_p.circle_fill (x + width / 2.0, y + height / 2.0, 5.0)
				else
					a_p.rrect_fill (x, y, width, height, height / 2.0)
					a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
					a_p.set_color (t.surface)
					a_p.text (x + (width - a_p.advance (caption)) / 2.0, y + height - 5.0, caption)
				end
			end
		end

invariant
	count_non_negative: count >= 0

end
