note
	description: "[
		A clickable button, decomposed along the appearance model:

		STRUCTURE - three parts: background, border, label, each its
		own feature, individually redefinable (Eiffel redefinition is
		this library's ControlTemplate).
		STYLE - the queries fill_color / border_color / label_color map
		(variant, state) to theme tokens; a descendant restyles by
		redefining a query, and inherited contracts survive the reskin.
		VARIANT (the kind query) - author-chosen: normal, primary, quiet, danger.
		STATE - inherited from SW_WIDGET: enabled, hovered, pressed,
		focused; all drawing keys off these.
		THEME - every value below is a token; no literal colours here.
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

feature -- Variants

	Kind_normal: INTEGER = 0
	Kind_primary: INTEGER = 1
	Kind_quiet: INTEGER = 2
	Kind_danger: INTEGER = 3

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_on_click: detachable PROCEDURE)
		do
			create label.make_from_string_general (a_label)
			on_click := a_on_click
		ensure
			labelled: label.same_string_general (a_label)
			enabled: is_enabled
			normal: kind = Kind_normal
		end

	make_primary (a_label: READABLE_STRING_GENERAL; a_on_click: detachable PROCEDURE)
		do
			make (a_label, a_on_click)
			kind := Kind_primary
		ensure
			primary: kind = Kind_primary
		end

feature -- Access

	label: STRING_32

	kind: INTEGER
			-- The author-chosen variant; never changes with input.
			-- (Named kind because the natural word is an Eiffel keyword.)

	on_click: detachable PROCEDURE

feature -- Element change

	set_kind (a_kind: INTEGER)
		require
			known: a_kind >= Kind_normal and a_kind <= Kind_danger
		do
			kind := a_kind
		ensure
			set: kind = a_kind
		end

	as_kind (a_kind: INTEGER): like Current
			-- Fluent variant selection.
		require
			known: a_kind >= Kind_normal and a_kind <= Kind_danger
		do
			set_kind (a_kind)
			Result := Current
		ensure
			chained: Result = Current
		end

	set_label (a_label: READABLE_STRING_GENERAL)
		do
			create label.make_from_string_general (a_label)
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

feature -- Style (the rule layer: variant and state select tokens)

	fill_color (a_t: SW_THEME): NATURAL_32
			-- Background token for the current variant and state.
		do
			if is_pressed then
				inspect kind
				when 1 then
					Result := a_t.wash_accent
				when 3 then
					Result := a_t.wash_danger
				else
					Result := a_t.outline
				end
			elseif shows_hover then
				Result := a_t.surface_variant
			else
				Result := a_t.surface
			end
		end

	border_color (a_t: SW_THEME): NATURAL_32
		do
			if not is_enabled then
				Result := a_t.outline
			else
				inspect kind
				when 1 then
					Result := a_t.accent
				when 3 then
					Result := a_t.danger
				when 2 then
					Result := fill_color (a_t)
				else
					Result := a_t.outline
				end
			end
		end

	label_color (a_t: SW_THEME): NATURAL_32
		do
			if not is_enabled then
				Result := a_t.ink_muted
			else
				inspect kind
				when 1 then
					Result := a_t.accent
				when 3 then
					Result := a_t.danger
				else
					Result := a_t.ink
				end
			end
		end

feature -- Drawing (structure: three parts)

	draw (a_p: SW_PAINTER)
		do
			draw_background (a_p)
			draw_border (a_p)
			draw_label (a_p)
		end

	draw_background (a_p: SW_PAINTER)
		do
			a_p.set_color (fill_color (a_p.theme))
			a_p.rrect_fill (x, y, width, height, a_p.theme.radius)
		end

	draw_border (a_p: SW_PAINTER)
		do
			a_p.set_color (border_color (a_p.theme))
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, a_p.theme.radius)
		end

	draw_label (a_p: SW_PAINTER)
		do
			a_p.set_color (label_color (a_p.theme))
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			a_p.text (x + 11.0, y + height - 11.0, label)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if attached on_click as a then
					a.call
				end
				Result := True
			end
		end

invariant
	label_attached: label /= Void
	kind_known: kind >= Kind_normal and kind <= Kind_danger

end
