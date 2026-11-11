note
	description: "[
		An inline banner (alert, callout): a row on the wash of its kind - information,
		success, warning or danger - with the kind's mark first and a stripe of the kind's
		ink down its left edge. Its children are whatever the caller lays in it (a label,
		action buttons, a close button). Reads as a status region.
	]"

class
	SW_INFO_BAR

inherit
	SW_ROW
		rename
			make as make_row
		redefine
			draw, accessible_role, shows_style
		end

create
	make

feature {NONE} -- Initialization

	make (a_kind: INTEGER)
		require
			known: a_kind >= Kind_info and a_kind <= Kind_danger
		do
			make_row
			kind := a_kind
			create mark.make (mark_glyph (a_kind), 22.0)
			put (mark)
			set_padding (10.0)
		ensure
			kind_set: kind = a_kind
			marked: children.first = mark
		end

feature -- Access

	kind: INTEGER

	mark: SW_ICON
			-- The kind's glyph, the first child.

	Kind_info: INTEGER = 1
	Kind_success: INTEGER = 2
	Kind_warning: INTEGER = 3
	Kind_danger: INTEGER = 4

feature -- Element change

	set_kind (a_kind: INTEGER)
		require
			known: a_kind >= Kind_info and a_kind <= Kind_danger
		do
			kind := a_kind
			mark.set_glyph (mark_glyph (a_kind))
		ensure
			set: kind = a_kind
		end

feature -- Colors

	ink (t: SW_THEME): NATURAL_32
			-- The kind's ink in `t'.
		do
			inspect kind
			when Kind_success then Result := t.success
			when Kind_warning then Result := t.warning
			when Kind_danger then Result := t.danger
			else Result := t.accent
			end
		end

	wash (t: SW_THEME): NATURAL_32
			-- The kind's wash in `t'.
		do
			inspect kind
			when Kind_success then Result := t.wash_success
			when Kind_warning then Result := t.wash_warning
			when Kind_danger then Result := t.wash_danger
			else Result := t.wash_accent
			end
		end

feature -- Drawing

	shows_style (a_part: INTEGER): BOOLEAN
			-- Only the padding: this is a surface with its own drawing.
		do
			Result := a_part = {SW_WIDGET_STYLE}.Part_padding
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color (wash (t))
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (ink (t))
			a_p.fill_rect (x, y + 3.0, 4.0, height - 6.0)
			mark.set_color (ink (t))
			Precursor (a_p)
		end

feature -- Accessibility

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_status_bar
		end

feature {NONE} -- Implementation

	mark_glyph (a_kind: INTEGER): INTEGER
		do
			inspect a_kind
			when Kind_success then Result := {SW_PAINTER}.Glyph_check
			when Kind_warning then Result := {SW_PAINTER}.Glyph_warning
			when Kind_danger then Result := {SW_PAINTER}.Glyph_error
			else Result := {SW_PAINTER}.Glyph_info
			end
		end

invariant
	known_kind: kind >= Kind_info and kind <= Kind_danger

end
