note
	description: "[
		One widget's own appearance, set over the theme: colors, the font, the room inside
		the border, a border, a corner radius, a shadow and the scroll bars. Every part is
		optional; a part that is not set leaves the theme's (or the widget's own) value alone.

		A widget shows only the parts its drawing has a place for (SW_WIDGET.shows_style);
		the rest are carried and ignored.

		Lengths (padding, border, radius, shadow) are device pixels, as SW_PADDED.set_padding
		takes them. The font size is a type size like SW_LABEL.size: the theme's text_scale
		is applied when it is drawn.

		WHY NOT A THEME OF THE WIDGET'S OWN: SW_THEME's invariant holds its ink readable on
		its surface. A style is the application's choice for one widget and may pair any two
		colors, so it cannot be a theme.
	]"

class
	SW_WIDGET_STYLE

create
	make

feature {NONE} -- Initialization

	make
			-- A style that sets nothing.
		do
			create family.make_empty
		ensure
			empty: is_empty
		end

feature -- Parts

	Part_foreground: INTEGER = 1
	Part_background: INTEGER = 2
	Part_placeholder: INTEGER = 3
	Part_selection: INTEGER = 4
	Part_family: INTEGER = 5
	Part_size: INTEGER = 6
	Part_weight: INTEGER = 7
	Part_italic: INTEGER = 8
	Part_padding: INTEGER = 9
	Part_border: INTEGER = 10
	Part_radius: INTEGER = 11
	Part_shadow: INTEGER = 12
	Part_scroll_bars: INTEGER = 13

	is_part (a_part: INTEGER): BOOLEAN
			-- Is `a_part' one of the Part_* codes?
		do
			Result := a_part >= Part_foreground and a_part <= Part_scroll_bars
		ensure
			definition: Result = (a_part >= Part_foreground and a_part <= Part_scroll_bars)
		end

	has (a_part: INTEGER): BOOLEAN
			-- Does this style set `a_part'?
		require
			part_known: is_part (a_part)
		do
			Result := parts.bit_test (a_part)
		end

	is_empty: BOOLEAN
			-- Does this style set nothing?
		do
			Result := parts = 0
		ensure
			definition: Result = (parts = 0)
		end

feature -- Colors (0xRRGGBB)

	foreground: NATURAL_32
			-- The color of the text.

	background: NATURAL_32
			-- The fill behind the widget.

	placeholder: NATURAL_32
			-- The color of a field's placeholder.

	selection: NATURAL_32
			-- The fill behind selected text or a selected row.

	set_foreground (a_rgb: NATURAL_32)
		do
			foreground := a_rgb
			mark (Part_foreground)
		ensure
			set: has (Part_foreground) and foreground = a_rgb
		end

	set_background (a_rgb: NATURAL_32)
		do
			background := a_rgb
			mark (Part_background)
		ensure
			set: has (Part_background) and background = a_rgb
		end

	set_placeholder (a_rgb: NATURAL_32)
		do
			placeholder := a_rgb
			mark (Part_placeholder)
		ensure
			set: has (Part_placeholder) and placeholder = a_rgb
		end

	set_selection (a_rgb: NATURAL_32)
		do
			selection := a_rgb
			mark (Part_selection)
		ensure
			set: has (Part_selection) and selection = a_rgb
		end

feature -- Font

	font_role: INTEGER
			-- The type role the text is set in (SW_PAINTER.Role_ui, Role_body or Role_mono);
			-- 0 keeps the widget's own.

	family: STRING_32
			-- The family that leads the role's faces; empty keeps the role's own.

	size: REAL_64
			-- The type size, before the theme's text_scale.

	weight: INTEGER
			-- 100 to 900 as OpenType counts it: 400 regular, 700 bold.

	is_italic: BOOLEAN

	is_role (a_role: INTEGER): BOOLEAN
			-- Is `a_role' a type role, or 0 for "the widget's own"?
		do
			Result := a_role = 0 or a_role = {SW_PAINTER}.Role_ui
				or a_role = {SW_PAINTER}.Role_body or a_role = {SW_PAINTER}.Role_mono
		end

	set_face (a_role: INTEGER; a_family: READABLE_STRING_GENERAL)
			-- Set the text in the role `a_role' (0: the widget's own), led by the family
			-- `a_family' (empty: the role's own face).
		require
			role_known: is_role (a_role)
		do
			font_role := a_role
			create family.make_from_string_general (a_family)
			mark (Part_family)
		ensure
			set: has (Part_family) and font_role = a_role and family.same_string_general (a_family)
		end

	set_size (a_size: REAL_64)
		require
			positive: a_size > 0.0
		do
			size := a_size
			mark (Part_size)
		ensure
			set: has (Part_size) and size = a_size
		end

	set_weight (a_weight: INTEGER)
		require
			in_range: a_weight >= 1 and a_weight <= 1000
		do
			weight := a_weight
			mark (Part_weight)
		ensure
			set: has (Part_weight) and weight = a_weight
		end

	set_italic (a_on: BOOLEAN)
			-- Slant the text, or (False) hold it upright where the widget's own is slanted.
		do
			is_italic := a_on
			mark (Part_italic)
		ensure
			set: has (Part_italic) and is_italic = a_on
		end

feature -- Frame (device pixels)

	padding_top, padding_end, padding_bottom, padding_start: REAL_64
			-- The room inside the border. Start and end follow the reading direction.

	border_width: REAL_64

	border_color: NATURAL_32
			-- The border's color when `has_border_color'; the theme's outline otherwise.

	has_border_color: BOOLEAN

	radius: REAL_64
			-- The corner radius of the background and the border.

	shadow_x, shadow_y, shadow_blur: REAL_64
			-- The shadow's offset (`shadow_y' grows downward) and how far it fades.

	shadow_alpha: REAL_64
			-- The shadow's strength, 0 (none) to 1 (solid).

	shadow_color: NATURAL_32
			-- The shadow's color when `has_shadow_color'; black otherwise.

	has_shadow_color: BOOLEAN

	set_padding (a_top, a_end, a_bottom, a_start: REAL_64)
		require
			non_negative: a_top >= 0.0 and a_end >= 0.0 and a_bottom >= 0.0 and a_start >= 0.0
		do
			padding_top := a_top
			padding_end := a_end
			padding_bottom := a_bottom
			padding_start := a_start
			mark (Part_padding)
		ensure
			set: has (Part_padding) and padding_top = a_top and padding_end = a_end
				and padding_bottom = a_bottom and padding_start = a_start
		end

	set_border (a_width: REAL_64)
		require
			non_negative: a_width >= 0.0
		do
			border_width := a_width
			mark (Part_border)
		ensure
			set: has (Part_border) and border_width = a_width
		end

	set_border_color (a_rgb: NATURAL_32)
		do
			border_color := a_rgb
			has_border_color := True
		ensure
			set: has_border_color and border_color = a_rgb
		end

	set_radius (a_radius: REAL_64)
		require
			non_negative: a_radius >= 0.0
		do
			radius := a_radius
			mark (Part_radius)
		ensure
			set: has (Part_radius) and radius = a_radius
		end

	set_shadow (a_x, a_y, a_blur, a_alpha: REAL_64)
		require
			blur_non_negative: a_blur >= 0.0
			alpha_in_range: a_alpha >= 0.0 and a_alpha <= 1.0
		do
			shadow_x := a_x
			shadow_y := a_y
			shadow_blur := a_blur
			shadow_alpha := a_alpha
			mark (Part_shadow)
		ensure
			set: has (Part_shadow) and shadow_x = a_x and shadow_y = a_y
				and shadow_blur = a_blur and shadow_alpha = a_alpha
		end

	set_shadow_color (a_rgb: NATURAL_32)
		do
			shadow_color := a_rgb
			has_shadow_color := True
		ensure
			set: has_shadow_color and shadow_color = a_rgb
		end

feature -- Scroll bars

	Scroll_bars_system: INTEGER = 0
			-- Shown when there is something to scroll.

	Scroll_bars_overlay: INTEGER = 1
			-- Drawn over the content, taking no room of their own.

	Scroll_bars_always: INTEGER = 2
			-- Shown even with nothing to scroll.

	Scroll_bars_hidden: INTEGER = 3
			-- Never shown; the wheel and the keys still scroll.

	scroll_bars: INTEGER
			-- One of the Scroll_bars_* codes.

	is_scroll_bar_kind (a_kind: INTEGER): BOOLEAN
		do
			Result := a_kind >= Scroll_bars_system and a_kind <= Scroll_bars_hidden
		ensure
			definition: Result = (a_kind >= Scroll_bars_system and a_kind <= Scroll_bars_hidden)
		end

	set_scroll_bars (a_kind: INTEGER)
		require
			kind_known: is_scroll_bar_kind (a_kind)
		do
			scroll_bars := a_kind
			mark (Part_scroll_bars)
		ensure
			set: has (Part_scroll_bars) and scroll_bars = a_kind
		end

feature {NONE} -- Implementation

	parts: INTEGER
			-- Bit n is set when part n is.

	mark (a_part: INTEGER)
		require
			part_known: is_part (a_part)
		do
			parts := parts.set_bit (True, a_part)
		ensure
			marked: has (a_part)
		end

invariant
	role_known: is_role (font_role)
	size_positive: has (Part_size) implies size > 0.0
	weight_in_range: has (Part_weight) implies (weight >= 1 and weight <= 1000)
	padding_non_negative: padding_top >= 0.0 and padding_end >= 0.0 and padding_bottom >= 0.0 and padding_start >= 0.0
	border_non_negative: border_width >= 0.0
	radius_non_negative: radius >= 0.0
	shadow_sane: shadow_blur >= 0.0 and shadow_alpha >= 0.0 and shadow_alpha <= 1.0
	scroll_bars_known: is_scroll_bar_kind (scroll_bars)

end
