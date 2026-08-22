note
	description: "[
		An integer spin box: the value between a minus and a plus
		button, wheel-adjustable, clamped to [min_value, max_value]
		by contract. Typing arrives later through composition with
		the single-line text box.
	]"

class
	SW_NUMBER_BOX

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, handle_wheel
		end

create
	make

feature {NONE} -- Initialization

	make (a_value, a_min, a_max: INTEGER; a_on_change: detachable PROCEDURE [INTEGER])
		require
			ordered: a_min <= a_max
			value_in_range: a_value >= a_min and a_value <= a_max
		do
			min_value := a_min
			max_value := a_max
			value := a_value
			step := 1
			on_change := a_on_change
		ensure
			kept: value = a_value
		end

feature -- Access

	value: INTEGER
	min_value: INTEGER
	max_value: INTEGER
	step: INTEGER

	on_change: detachable PROCEDURE [INTEGER]

feature -- Element change

	set_value (a_v: INTEGER)
		do
			value := a_v.max (min_value).min (max_value)
		ensure
			in_range: value >= min_value and value <= max_value
		end

	set_step (a_s: INTEGER)
		require
			positive: a_s > 0
		do
			step := a_s
		ensure
			set: step = a_s
		end

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	Btn_w: REAL_64 = 30.0

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_label, False)
			Result := 2.0 * Btn_w + a_p.advance (max_value.out) + 26.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := a_p.theme.button_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if shows_hover then
				a_p.set_color (t.ink_muted)
			else
				a_p.set_color (t.outline)
			end
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.vline (x + Btn_w, y + 4.0, height - 8.0)
			a_p.vline (x + width - Btn_w, y + 4.0, height - 8.0)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label + 2.0, False)
			if is_enabled and value > min_value then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.text (x + Btn_w / 2.0 - 5.0, y + height / 2.0 + 6.0, "-")
			if is_enabled and value < max_value then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.text (x + width - Btn_w / 2.0 - 5.0, y + height / 2.0 + 6.0, "+")
			a_p.font ({SW_PAINTER}.Role_mono, t.size_label, False)
			if is_enabled then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.text (x + Btn_w + (width - 2.0 * Btn_w - a_p.advance (value.out)) / 2.0,
				y + height / 2.0 + t.size_label / 2.0 - 2.0, value.out)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if a_px <= x + Btn_w then
					bump (-step)
				elseif a_px >= x + width - Btn_w then
					bump (step)
				end
				Result := True
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			if is_enabled then
				bump ((a_delta // 120) * step)
				Result := True
			end
		end

feature {NONE} -- Implementation

	bump (a_by: INTEGER)
		local
			old_v: INTEGER
		do
			old_v := value
			set_value (value + a_by)
			if value /= old_v and then attached on_change as a then
				a.call (value)
			end
		end

invariant
	ordered: min_value <= max_value
	value_in_range: value >= min_value and value <= max_value
	step_positive: step > 0

end
