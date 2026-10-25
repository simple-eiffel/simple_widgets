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
			handle_click,
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

feature -- Removal

	is_removable: BOOLEAN

	on_remove: detachable PROCEDURE

	with_remove (a_action: PROCEDURE): like Current
			-- Fluent: grow an x zone that fires `a_action'.
		do
			is_removable := True
			on_remove := a_action
			Result := Current
		ensure
			armed: is_removable and on_remove = a_action
			chained: Result = Current
		end

	remove_zone_contains (a_px: REAL_64): BOOLEAN
			-- Is a surface x inside the x-glyph zone (right 16px)?
		do
			Result := is_removable and then a_px >= x + width - 16.0 and then a_px <= x + width
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

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled and then remove_zone_contains (a_px) then
				if attached on_remove as a then
					a.call (Void)
				end
				Result := True
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			fg, bg: NATURAL_32
		do
			t := a_p.theme
			fg := text_color (t)
			bg := fill_color (t)
			a_p.set_color (bg)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if is_removable then
				a_p.set_color (fg)
				a_p.line (x + width - 12.0, y + height / 2.0 - 3.5,
					x + width - 5.0, y + height / 2.0 + 3.5, 1.4)
				a_p.line (x + width - 12.0, y + height / 2.0 + 3.5,
					x + width - 5.0, y + height / 2.0 - 3.5, 1.4)
			end
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

feature -- Colours

	fill_color (a_theme: SW_THEME): NATURAL_32
			-- The chip's ground: its kind's wash.
		do
			inspect kind
			when 1 then
				Result := a_theme.wash_accent
			when 2 then
				Result := a_theme.wash_success
			when 3 then
				Result := a_theme.wash_warning
			when 4 then
				Result := a_theme.wash_danger
			else
				Result := a_theme.surface_variant
			end
		end

	text_color (a_theme: SW_THEME): NATURAL_32
			-- The label, the outline and the remove cross: the theme's strong
			-- ink for that wash (it drew the fill colour itself, under 4.5:1 on
			-- the wash in dark).
		do
			inspect kind
			when 1 then
				Result := a_theme.ink_accent
			when 2 then
				Result := a_theme.ink_success
			when 3 then
				Result := a_theme.ink_warning
			when 4 then
				Result := a_theme.ink_danger
			else
				Result := neutral_text_color (a_theme)
			end
		end

	neutral_text_color (a_theme: SW_THEME): NATURAL_32
			-- A neutral chip's text: muted where muted ink reads on its ground,
			-- else full ink (a contrast palette promises only the ink there).
		do
			if a_theme.contrast_ratio (a_theme.ink_muted, a_theme.surface_variant) >= a_theme.Body_contrast then
				Result := a_theme.ink_muted
			else
				Result := a_theme.ink
			end
		end

invariant
	label_attached: label /= Void
	kind_valid: kind >= Kind_neutral and kind <= Kind_danger

end
