note
	description: "[
		The token vocabulary of a face: surfaces, semantic colours,
		washes, type roles, metrics. Widgets take every visual decision
		from here; an application restyles by swapping the theme, never
		by editing a widget.

		Colours are 0xRRGGBB. The semantic slots are generic - accent,
		success, warning, danger - so no application vocabulary leaks
		into the toolkit.

		Contrast is a contract, not a hope: the invariant computes it.
	]"

class
	SW_THEME

create
	make_light, make_dark

feature {NONE} -- Initialization

	make_light
			-- The documented light palette: every value carried a
			-- computed WCAG check when it was first specified.
		do
			background := 0xE9ECF1
			surface := 0xFFFFFF
			surface_variant := 0xF5F7FA
			outline := 0xD3DAE3
			ink := 0x1A2029
			ink_muted := 0x5A6573
			accent := 0x1F5FA8
			success := 0x1D6B52
			warning := 0x8A5A0B
			danger := 0xAF3A22
			neutral := 0xD3DAE3
			wash_accent := 0xC7DAF1
			wash_success := 0xE0F0E9
			wash_warning := 0xFAF1DD
			wash_danger := 0xF8E7E2
			init_families
			set_metrics
		end

	make_dark
			-- The dark scheme proven on the capture strip.
		do
			background := 0x14181F
			surface := 0x1C222B
			surface_variant := 0x232A35
			outline := 0x3A4250
			ink := 0xE8ECF2
			ink_muted := 0xB9C2CE
			accent := 0x4D8FD6
			success := 0x35C46F
			warning := 0xD6A344
			danger := 0xE0563A
			neutral := 0x3A4250
			wash_accent := 0x24344A
			wash_success := 0x1D3A2C
			wash_warning := 0x3D330E
			wash_danger := 0x40231C
			init_families
			set_metrics
		end

	init_families
		do
			create family_ui.make_from_string_general ("Archivo")
			create family_body.make_from_string_general ("Literata")
			create family_mono.make_from_string_general ("IBM Plex Mono")
		end

	set_metrics
		do
			radius := 3.0
			gap := 8.0
			pad := 11.0
			button_height := 32.0
			chip_height := 20.0
			size_body := 13.5
			size_label := 11.0
			size_chip := 9.5
			line_height := 26.0
		end

feature -- Surfaces

	background: NATURAL_32
	surface: NATURAL_32
	surface_variant: NATURAL_32
	outline: NATURAL_32
	ink: NATURAL_32
	ink_muted: NATURAL_32

feature -- Semantic colours

	accent: NATURAL_32
	success: NATURAL_32
	warning: NATURAL_32
	danger: NATURAL_32
	neutral: NATURAL_32
	wash_accent: NATURAL_32
	wash_success: NATURAL_32
	wash_warning: NATURAL_32
	wash_danger: NATURAL_32

feature -- Type roles

	family_ui: STRING_32
	family_body: STRING_32
	family_mono: STRING_32

feature -- Metrics

	radius: REAL_64
	gap: REAL_64
	pad: REAL_64
	button_height: REAL_64
	chip_height: REAL_64
	size_body: REAL_64
	size_label: REAL_64
	size_chip: REAL_64
	line_height: REAL_64

feature -- Element change

	set_surfaces (a_background, a_surface, a_variant, a_outline, a_ink, a_ink_muted: NATURAL_32)
			-- Recolour the ground. The invariant still holds: an
			-- unreadable combination is rejected at the call site.
		do
			background := a_background
			surface := a_surface
			surface_variant := a_variant
			outline := a_outline
			ink := a_ink
			ink_muted := a_ink_muted
		ensure
			set: background = a_background and surface = a_surface
				and ink = a_ink
		end

	set_semantics (a_accent, a_success, a_warning, a_danger, a_neutral: NATURAL_32)
		do
			accent := a_accent
			success := a_success
			warning := a_warning
			danger := a_danger
			neutral := a_neutral
		ensure
			set: accent = a_accent and danger = a_danger
		end

	set_washes (a_accent, a_success, a_warning, a_danger: NATURAL_32)
		do
			wash_accent := a_accent
			wash_success := a_success
			wash_warning := a_warning
			wash_danger := a_danger
		ensure
			set: wash_accent = a_accent and wash_danger = a_danger
		end

	set_families (a_ui, a_body, a_mono: READABLE_STRING_GENERAL)
			-- Rename the three type roles.
		do
			create family_ui.make_from_string_general (a_ui)
			create family_body.make_from_string_general (a_body)
			create family_mono.make_from_string_general (a_mono)
		ensure
			set: family_ui.same_string_general (a_ui)
		end

feature -- Measurement

	luminance (a_rgb: NATURAL_32): REAL_64
			-- Relative luminance per WCAG.
		local
			r, g, b: REAL_64
		do
			r := channel (a_rgb.bit_shift_right (16).bit_and (0xFF))
			g := channel (a_rgb.bit_shift_right (8).bit_and (0xFF))
			b := channel (a_rgb.bit_and (0xFF))
			Result := 0.2126 * r + 0.7152 * g + 0.0722 * b
		ensure
			normalised: Result >= 0.0 and Result <= 1.0
		end

	contrast_ratio (a, b: NATURAL_32): REAL_64
			-- WCAG contrast ratio between two colours, >= 1.
		local
			la, lb, hi, lo: REAL_64
		do
			la := luminance (a)
			lb := luminance (b)
			hi := la.max (lb)
			lo := la.min (lb)
			Result := (hi + 0.05) / (lo + 0.05)
		ensure
			at_least_one: Result >= 1.0
		end

feature {NONE} -- Implementation

	channel (a_v: NATURAL_32): REAL_64
		local
			s: REAL_64
		do
			s := a_v / 255.0
			if s <= 0.03928 then
				Result := s / 12.92
			else
				Result := ((s + 0.055) / 1.055) ^ 2.4
			end
		end

invariant
	ink_readable_on_surface: contrast_ratio (ink, surface) >= 4.5
	muted_readable_on_surface: contrast_ratio (ink_muted, surface) >= 3.0

end
