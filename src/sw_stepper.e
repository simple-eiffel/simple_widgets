note
	description: "[
		A process worn as circles: done steps carry checks, the
		current step is accent-filled, upcoming steps wait outlined.
		Clicking a DONE step jumps back; the future is not clickable
		- processes move forward by work, not by wishing.
	]"

class
	SW_STEPPER

inherit
	SW_WIDGET
		redefine
			handle_click, wants_hover_point, preferred_width
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create steps.make (4)
			current_step := 0
		end

feature -- Access

	steps: ARRAYED_LIST [STRING_32]

	current_step: INTEGER
			-- 1-based; 0 only while empty.

	on_change: detachable PROCEDURE [INTEGER]

	Step_w: REAL_64 = 120.0

	Circle_r: REAL_64 = 13.0

feature -- Element change

	add_step (a_label: READABLE_STRING_GENERAL)
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_label)
			steps.extend (s)
			if current_step = 0 then
				current_step := 1
			end
		ensure
			grew: steps.count = old steps.count + 1
			started: current_step >= 1
		end

	with_step (a_label: READABLE_STRING_GENERAL): like Current
		do
			add_step (a_label)
			Result := Current
		ensure
			chained: Result = Current
		end

	advance
			-- One step forward, clamped at the last.
		require
			has_steps: steps.count > 0
		do
			set_current_step (current_step + 1)
		ensure
			moved_or_at_end: current_step >= old current_step
		end

	retreat
		require
			has_steps: steps.count > 0
		do
			set_current_step (current_step - 1)
		ensure
			moved_or_at_start: current_step <= old current_step
		end

	set_current_step (a_i: INTEGER)
			-- Clamped into 1 .. count.
		require
			has_steps: steps.count > 0
		do
			current_step := a_i.max (1).min (steps.count)
			if attached on_change as a then
				a.call (current_step)
			end
		ensure
			in_range: current_step >= 1 and current_step <= steps.count
		end

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	step_at (a_px: REAL_64): INTEGER
			-- The step whose column the point is in; 0 outside.
		do
			if a_px >= x and a_px < x + steps.count * Step_w then
				Result := ((a_px - x) / Step_w).truncated_to_integer + 1
			end
		ensure
			in_range: Result >= 0 and Result <= steps.count
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			Result := steps.count * Step_w
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 58.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			cx, cy: REAL_64
		do
			t := a_p.theme
			cy := y + 18.0
			from
				i := 1
			until
				i > steps.count
			loop
				cx := x + (i - 1) * Step_w + Step_w / 2.0
				if i < steps.count then
						-- connector to the next circle
					if i < current_step then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.outline)
					end
					a_p.line (cx + Circle_r + 3.0, cy, cx + Step_w - Circle_r - 3.0, cy, 2.0)
				end
				if i < current_step then
						-- done: accent ring with a check
					a_p.set_color (t.accent)
					a_p.circle_stroke (cx, cy, Circle_r)
					a_p.line (cx - 5.0, cy, cx - 1.0, cy + 4.0, 2.0)
					a_p.line (cx - 1.0, cy + 4.0, cx + 5.0, cy - 4.0, 2.0)
				elseif i = current_step then
						-- current: filled accent with the number
					a_p.set_color (t.accent)
					a_p.circle_fill (cx, cy, Circle_r)
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
					a_p.set_color (t.surface)
					a_p.text (cx - a_p.advance (i.out) / 2.0, cy + 5.0, i.out)
				else
						-- upcoming: outlined with a muted number
					a_p.set_color (t.outline)
					a_p.circle_stroke (cx, cy, Circle_r)
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
					a_p.set_color (t.ink_muted)
					a_p.text (cx - a_p.advance (i.out) / 2.0, cy + 5.0, i.out)
				end
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip + 1.0, i = current_step)
				if i = current_step then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (cx - a_p.advance (steps.i_th (i)) / 2.0, y + 52.0, steps.i_th (i))
				i := i + 1
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			k: INTEGER
		do
			if is_enabled and then steps.count > 0 then
				k := step_at (a_px)
				if k >= 1 and k < current_step then
						-- only completed ground is revisitable
					set_current_step (k)
				end
				Result := True
			end
		end

invariant
	steps_attached: steps /= Void
	current_in_range: current_step >= 0 and current_step <= steps.count
	started_when_populated: steps.count > 0 implies current_step >= 1

end
