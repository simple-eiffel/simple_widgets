note
	description: "[
		A small state chip: mono label in a washed, bordered pill.
		The kind selects the theme's semantic colour pair.
	]"

class
	SW_CHIP

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make

feature -- Kinds

	Kind_neutral: INTEGER = 0
	Kind_accent: INTEGER = 1
	Kind_success: INTEGER = 2
	Kind_warning: INTEGER = 3
	Kind_danger: INTEGER = 4

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_kind: INTEGER)
		require
			kind_known: a_kind >= Kind_neutral and a_kind <= Kind_danger
		do
			create label.make_from_string_general (a_label)
			kind := a_kind
		ensure
			labelled: label.same_string_general (a_label)
			kind_set: kind = a_kind
		end

feature -- Access

	label: STRING_32
	kind: INTEGER

feature -- Element change

	set_kind (a_kind: INTEGER)
		require
			kind_known: a_kind >= Kind_neutral and a_kind <= Kind_danger
		do
			kind := a_kind
		ensure
			set: kind = a_kind
		end

	set_label (a_label: READABLE_STRING_GENERAL)
		do
			create label.make_from_string_general (a_label)
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip, False)
			Result := a_p.advance (label) + 16.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := a_p.theme.chip_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			fg, bg: NATURAL_32
		do
			t := a_p.theme
			inspect kind
			when 1 then
				fg := t.accent
				bg := t.wash_accent
			when 2 then
				fg := t.success
				bg := t.wash_success
			when 3 then
				fg := t.warning
				bg := t.wash_warning
			when 4 then
				fg := t.danger
				bg := t.wash_danger
			else
				fg := t.ink_muted
				bg := t.surface_variant
			end
			a_p.set_color (bg)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if kind = Kind_neutral then
				a_p.set_color (t.outline)
			else
				a_p.set_color (fg)
			end
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.set_color (fg)
			a_p.font ({SW_PAINTER}.Role_mono, t.size_chip, False)
			a_p.text (x + 8.0, y + height - 6.0, label)
		end

invariant
	label_attached: label /= Void
	kind_valid: kind >= Kind_neutral and kind <= Kind_danger

end
