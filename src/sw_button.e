note
	description: "[
		A clickable button. The behaviour is an agent; the chrome is the
		theme's. Disabled buttons draw muted and swallow clicks.
	]"

class
	SW_BUTTON

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click
		end

create
	make, make_primary

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_on_click: detachable PROCEDURE)
		do
			create label.make_from_string_general (a_label)
			on_click := a_on_click
			is_enabled := True
		ensure
			labelled: label.same_string_general (a_label)
			enabled: is_enabled
		end

	make_primary (a_label: READABLE_STRING_GENERAL; a_on_click: detachable PROCEDURE)
		do
			make (a_label, a_on_click)
			is_primary := True
		ensure
			primary: is_primary
		end

feature -- Access

	label: STRING_32
	is_enabled: BOOLEAN
	is_primary: BOOLEAN
	on_click: detachable PROCEDURE

feature -- Element change

	set_enabled (a_enabled: BOOLEAN)
		do
			is_enabled := a_enabled
		ensure
			set: is_enabled = a_enabled
		end

	disabled: like Current
			-- Fluent: Current, disabled.
		do
			is_enabled := False
			Result := Current
		ensure
			off: not is_enabled
		end

	set_on_click (a_action: PROCEDURE)
		do
			on_click := a_action
		ensure
			set: on_click = a_action
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := a_p.advance (label) + 22.0
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
			if is_primary and is_enabled then
				a_p.set_color (t.accent)
			else
				a_p.set_color (t.outline)
			end
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			if is_primary and is_enabled then
				a_p.set_color (t.accent)
			elseif is_enabled then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			a_p.text (x + 11.0, y + height - 11.0, label)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64)
		do
			if is_enabled and then attached on_click as a then
				a.call
			end
		end

invariant
	label_attached: label /= Void

end
