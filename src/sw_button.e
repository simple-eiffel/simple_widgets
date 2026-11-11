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
		THEME - every value below is a token; no literal colors here.
	]"

class
	SW_BUTTON

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, shows_style,
			accessible_role, default_accessible_name
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
			labeled: label.same_string_general (a_label)
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

	glyph_kind: INTEGER
			-- A drawn glyph from SW_PAINTER's set (0 = none): beside
			-- the label, or alone when the label is empty (icon
			-- button). R7-pure - no font gambling.

	set_glyph (a_glyph: INTEGER)
		require
			known: a_glyph >= 0 and a_glyph <= {SW_PAINTER}.Glyph_last
		do
			glyph_kind := a_glyph
		ensure
			set: glyph_kind = a_glyph
		end

	with_glyph (a_glyph: INTEGER): like Current
			-- Fluent face: `create b.make ("Save", agent ...).with_glyph (...)'.
		require
			known: a_glyph >= 0 and a_glyph <= {SW_PAINTER}.Glyph_last
		do
			set_glyph (a_glyph)
			Result := Current
		ensure
			chained: Result = Current
		end

	kind: INTEGER
			-- The author-chosen variant; never changes with input.
			-- (Named kind because the natural word is an Eiffel keyword.)

	on_click: detachable PROCEDURE

	is_pill: BOOLEAN
			-- Fully rounded ends (half the height), for simple_gui's pill style (1n)?

	is_busy: BOOLEAN
			-- Is a turning spinner drawn where the glyph goes (simple_gui's busy state, 1n)?

feature -- Element change

	set_pill (a_on: BOOLEAN)
		do
			is_pill := a_on
		ensure
			set: is_pill = a_on
		end

	set_busy (a_on: BOOLEAN)
			-- Draw a spinner in the glyph's place; it turns a step each frame, so a host that
			-- wants it turning steadily repaints on a fast tick while it is busy.
		do
			is_busy := a_on
		ensure
			set: is_busy = a_on
		end

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
			-- The label's MEASURED advance plus the theme's inside inset
			-- either side - Vision2's `set_default_width_for_button'
			-- law (EV_LAYOUT_CONSTANTS, contrib/ev_layout_constants.e:75),
			-- with a measurement in place of its dialog-unit constant.
		local
			t: SW_THEME
		do
			t := a_p.theme
			use_font (a_p, {SW_PAINTER}.Role_ui, t.size_label, False)
			if label.is_empty and has_lead then
				Result := (2.0 * t.control_inset + t.size_label * t.text_scale).max (36.0)
			else
				Result := a_p.min_control_width (label)
				if has_lead then
					Result := Result + 19.0 * t.text_scale
				end
			end
			Result := Result + style_inset_width
		ensure then
			clears_the_insets: Result >= 2.0 * a_p.theme.control_inset
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The theme's nominal button height, or the MINIMUM the font
			-- demands - ascent + descent + the inside inset above and
			-- below - whichever is larger. A larger explicit anchor still
			-- wins through `clamped_height'; a smaller one is clamped up.
		do
			use_font (a_p, {SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := a_p.theme.button_height.max (a_p.min_control_height) + style_inset_height
		ensure then
			at_least_the_minimum: Result >= a_p.min_control_height
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

	shows_style (a_part: INTEGER): BOOLEAN
			-- Every button: the label's color and font, and the padding. A quiet button,
			-- which has no chrome of its own for a style to fight, also the background, the
			-- border, the shadow and (unless it is a pill) the radius.
		do
			Result := is_text_style_part (a_part) or a_part = {SW_WIDGET_STYLE}.Part_padding
				or (kind = Kind_quiet and is_frame_style_part (a_part)
					and (a_part /= {SW_WIDGET_STYLE}.Part_radius or not is_pill))
		end

	draw (a_p: SW_PAINTER)
		do
			draw_background (a_p)
			draw_border (a_p)
			if attached style then
				within_style_frame (agent draw_label (a_p))
			else
				draw_label (a_p)
			end
		end

	draw_background (a_p: SW_PAINTER)
		do
			if has_style_frame then
					-- the style's own frame; hover and press still answer, as a veil of ink
				draw_style_frame_rounded (a_p, corner_radius (a_p))
				if is_enabled and (is_pressed or shows_hover) then
					a_p.set_color_alpha (a_p.theme.ink, (if is_pressed then 0.16 else 0.08 end))
					a_p.rrect_fill (x, y, width, height, corner_radius (a_p))
				end
			else
				a_p.set_color (fill_color (a_p.theme))
				a_p.rrect_fill (x, y, width, height, corner_radius (a_p))
			end
		end

	draw_border (a_p: SW_PAINTER)
			-- The button's own border; none over a style's frame.
		do
			if not has_style_frame then
				a_p.set_color (border_color (a_p.theme))
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, corner_radius (a_p))
			end
		end

	corner_radius (a_p: SW_PAINTER): REAL_64
			-- Half the height for a pill; else the style's radius where it shows, or the theme's.
		do
			if is_pill then
				Result := (height / 2.0).max (0.0)
			elseif attached shown_style ({SW_WIDGET_STYLE}.Part_radius) then
				Result := style_radius
			else
				Result := a_p.theme.radius
			end
		ensure
			non_negative: Result >= 0.0
		end

	has_lead: BOOLEAN
			-- Is something drawn before the label (a glyph, or the busy spinner)?
		do
			Result := glyph_kind > 0 or is_busy
		end

	spinner_step: INTEGER
			-- How far the busy spinner has turned (a step each frame).

	draw_lead (a_p: SW_PAINTER; a_cx, a_cy, a_s: REAL_64)
			-- The glyph, or the busy spinner: three quarters of a ring, turned a step more each frame.
		local
			l_from: REAL_64
		do
			if is_busy then
				spinner_step := (spinner_step + 1) \\ 12
				l_from := spinner_step * 3.141592653589793 / 6.0
				a_p.set_line_width ((a_s / 8.0).max (1.5))
				a_p.arc_stroke (a_cx, a_cy, a_s * 0.4, l_from, l_from + 4.7)
				a_p.set_line_width (1.0)
			else
				a_p.glyph (glyph_kind, a_cx, a_cy, a_s)
			end
		end

	draw_label (a_p: SW_PAINTER)
		local
			t: SW_THEME
			inset, sc: REAL_64
		do
			t := a_p.theme
			sc := t.text_scale
			inset := t.control_inset
			if is_enabled then
				a_p.set_color (styled_ink (label_color (t)))
			else
					-- a disabled button keeps its muted label, whatever the style says
				a_p.set_color (label_color (t))
			end
			use_font (a_p, {SW_PAINTER}.Role_ui, t.size_label, False)
			if has_lead then
				if label.is_empty then
					draw_lead (a_p, x + width / 2.0, y + height / 2.0, 15.0 * sc)
				else
					draw_lead (a_p, x + 18.0 * sc, y + height / 2.0, 14.0 * sc)
					a_p.text (x + 30.0 * sc, a_p.baseline_in (y, height), label)
				end
			else
				a_p.text (x + inset, a_p.baseline_in (y, height), label)
			end
		end

feature -- Input

	click_actions: SW_EVENT [TUPLE]
			-- The click as an agent QUEUE - permanents and kamikazes
			-- beside the single on_click (which stays for the simple
			-- hand). Lazily allocated.
		do
			if attached click_event as e then
				Result := e
			else
				create Result.make
				click_event := Result
			end
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if attached click_event as ce then
					ce.call ([])
				end
				if attached on_click as a then
					a.call
				end
				Result := True
			end
		end

feature {NONE} -- Event backing

	click_event: detachable SW_EVENT [TUPLE]


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_button
		end

	default_accessible_name: STRING_32
		do
			Result := label.twin
		end

invariant
	label_attached: label /= Void
	kind_known: kind >= Kind_normal and kind <= Kind_danger

end
