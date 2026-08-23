note
	description: "[
		An on/off switch: a pill track with a sliding knob, accent
		when on. Toggles on click; the change agent fires after.
	]"

class
	SW_SWITCH

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click
		end

create
	make

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_on: BOOLEAN; a_on_change: detachable PROCEDURE)
		do
			create label.make_from_string_general (a_label)
			is_on := a_on
			on_change := a_on_change
		ensure
			labelled: label.same_string_general (a_label)
			state_kept: is_on = a_on
		end

feature -- Access

	label: STRING_32

	is_on: BOOLEAN

	on_change: detachable PROCEDURE

	on_caption, off_caption: detachable STRING_32
			-- Optional words inside the track.

	set_captions (a_on, a_off: READABLE_STRING_GENERAL)
		do
			create on_caption.make_from_string_general (a_on)
			create off_caption.make_from_string_general (a_off)
		end

feature -- Element change

	set_on (a_on: BOOLEAN)
		do
			is_on := a_on
		ensure
			set: is_on = a_on
		end

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	Track_w: REAL_64 = 40.0
	Track_h: REAL_64 = 22.0

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := Track_w + 10.0 + a_p.advance (label)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 30.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			ty, kx: REAL_64
		do
			t := a_p.theme
			ty := y + (height - Track_h) / 2.0
			if is_on and is_enabled then
				a_p.set_color (t.accent)
			elseif shows_hover then
				a_p.set_color (t.ink_muted)
			else
				a_p.set_color (t.outline)
			end
			a_p.rrect_fill (x, ty, Track_w, Track_h, Track_h / 2.0)
			if is_on then
				kx := x + Track_w - Track_h + 3.0
			else
				kx := x + 3.0
			end
			a_p.set_color (t.surface)
			a_p.rrect_fill (kx, ty + 3.0, Track_h - 6.0, Track_h - 6.0, (Track_h - 6.0) / 2.0)
			a_p.font ({SW_PAINTER}.Role_ui, 9.5, True)
			if is_on and then attached on_caption as oc then
				a_p.set_color (t.surface)
				a_p.text (x + 6.0, ty + Track_h - 7.0, oc)
			elseif not is_on and then attached off_caption as fc then
				a_p.set_color (t.ink_muted)
				a_p.text (x + Track_h - 3.0, ty + Track_h - 7.0, fc)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			if is_enabled then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.text (x + Track_w + 10.0, y + height / 2.0 + t.size_label / 2.0 - 2.0, label)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				is_on := not is_on
				if attached on_change as a then
					a.call
				end
				Result := True
			end
		end

invariant
	label_attached: label /= Void

end
