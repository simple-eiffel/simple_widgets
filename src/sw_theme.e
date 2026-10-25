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
	make_light, make_dark, make_high_contrast

feature {NONE} -- Initialization

	make_light
			-- The documented light palette: every value carried a
			-- computed WCAG check when it was first specified.
		do
			create locale.make_us
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
				-- GW-28 (2026-10-22): the tokens the simple_bible mockups
				-- needed, light values as drawn in the approved light page.
			ink_on_accent := 0xFFFFFF
			ink_on_success := 0xFFFFFF
			ink_on_warning := 0xFFFFFF
			ink_on_danger := 0xFFFFFF
			ink_accent := 0x154A85
			ink_success := 0x13503D
			ink_warning := 0x6E4708
			ink_danger := 0x8A2D19
			ink_soft := 0x3A4452
			divider := 0xEEF1F5
			selection := 0xEEF4FB
			scrim := 0x7D8796
			ramp_1 := 0xC7DAF1
			ramp_2 := 0x9BBBE3
			ramp_3 := 0x7BA9DE
			ramp_4 := 0x4D8FD6
			ramp_5 := 0x1F5FA8
			init_families
			set_metrics
		ensure
			light: not is_dark
			readable: is_readable
		end

	make_dark
			-- The dark scheme proven on the capture strip.
		do
			create locale.make_us
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
				-- GW-28 (2026-10-22): dark values as drawn in the approved
				-- dark page. Fills brighten in dark, so their text goes dark.
			ink_on_accent := 0x0B1220
			ink_on_success := 0x0B1220
			ink_on_warning := 0x0B1220
			ink_on_danger := 0x0B1220
			ink_accent := 0x9CC3EE
			ink_success := 0x7FD9A4
			ink_warning := 0xE8C77A
			ink_danger := 0xF0937D
			ink_soft := 0xC9D1DC
			divider := 0x2A313C
			selection := 0x1F2B3B
			scrim := 0x07090C
			ramp_1 := 0x24344A
			ramp_2 := 0x2F5378
			ramp_3 := 0x3A6A9C
			ramp_4 := 0x4378B3
			ramp_5 := 0x4D8FD6
			init_families
			set_metrics
		ensure
			dark: is_dark
			readable: is_readable
		end

	make_high_contrast (a_window, a_window_text, a_highlight, a_highlight_text, a_button_face, a_hotlight: NATURAL_32)
			-- A theme painted with a Windows contrast theme's system colors
			-- (GW-16): one ground (`a_window'), one ink (`a_window_text') for
			-- body, soft and muted text alike, strong outlines in that ink,
			-- `a_highlight' for accent fills with `a_highlight_text' on them
			-- (the ink instead if the highlight is not 3:1 on the window),
			-- `a_hotlight' for accent-family text, `a_button_face' for the
			-- quiet control ground. No washes: they all take the ground.
			-- Every pairing is MENDED rather than refused - a custom palette
			-- whose ink fails 4.5:1 gets black or white instead, a selection
			-- ground moves from the highlight toward the window until the ink
			-- reads on it - so the result is always readable.
		local
			l_base: SW_THEME
		do
			if luminance (a_window) < 0.5 then
				create l_base.make_dark
			else
				create l_base.make_light
			end
			create locale.make_us
			is_high_contrast := True
			background := a_window
			surface := a_window
			ink := readable_on (a_window_text, a_window)
			ink_muted := ink
			ink_soft := ink
			outline := ink
			divider := ink
			neutral := ink
			if contrast_ratio (ink, a_button_face) >= Body_contrast then
				surface_variant := a_button_face
			else
				surface_variant := a_window
			end
				-- accent marks and outlined labels sit on the window too
			if contrast_ratio (a_highlight, a_window) >= Label_contrast then
				accent := a_highlight
			else
				accent := ink
			end
			ink_on_accent := readable_on (a_highlight_text, accent)
			selection := readable_ground (a_highlight, a_window, ink)
			ink_accent := readable_on (a_hotlight, a_window)
				-- the semantic hues stay (Windows gives none), made readable
			success := l_base.success
			warning := l_base.warning
			danger := l_base.danger
			ink_on_success := readable_on (l_base.ink_on_success, success)
			ink_on_warning := readable_on (l_base.ink_on_warning, warning)
			ink_on_danger := readable_on (l_base.ink_on_danger, danger)
			ink_success := readable_on (l_base.ink_success, a_window)
			ink_warning := readable_on (l_base.ink_warning, a_window)
			ink_danger := readable_on (l_base.ink_danger, a_window)
			wash_accent := a_window
			wash_success := a_window
			wash_warning := a_window
			wash_danger := a_window
			scrim := l_base.scrim
			set_contrast_ramp (a_window)
			init_families
			set_metrics
		ensure
			high_contrast: is_high_contrast
			one_ground: background = a_window and surface = a_window
			readable: is_readable
			ink_kept_when_readable: contrast_ratio (a_window_text, a_window) >= Body_contrast implies ink = a_window_text
			accent_visible: contrast_ratio (accent, surface) >= Label_contrast
			dark_follows_the_window: is_dark = (luminance (a_window) < 0.5)
		end

	init_families
		do
			create family_ui.make_from_string_general ("Archivo")
			create family_body.make_from_string_general ("Literata")
			create family_mono.make_from_string_general ("IBM Plex Mono")
		end

	set_metrics
		do
			text_scale := 1.0
			radius := 3.0
			gap := 8.0
			pad := 12.0
			control_pad := 11.0
				-- sizes raised 2026-08-22: readability first (Larry)
			button_height := 38.0
			chip_height := 24.0
			size_body := 16.0
			size_label := 13.0
			size_chip := 11.0
			line_height := 30.0
		end

feature -- Culture

	locale: SW_LOCALE
			-- Cultural presentation truth (date order, week start,
			-- clock style). US by default; swap with `set_locale',
			-- or override per control on regional widgets.

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

feature -- Ink on filled controls (GW-28)

	ink_on_accent: NATURAL_32
			-- Text on an `accent' fill (a filled button, a selected chip or
			-- segment, a link-set badge).

	ink_on_success: NATURAL_32
			-- Text on a `success' fill.

	ink_on_warning: NATURAL_32
			-- Text on a `warning' fill.

	ink_on_danger: NATURAL_32
			-- Text on a `danger' fill.

feature -- Strong semantic inks (GW-28)

	ink_accent: NATURAL_32
			-- Accent-family text on `wash_accent' or on `surface' (status
			-- chips, banners).

	ink_success: NATURAL_32
			-- Success-family text on `wash_success' or on `surface'.

	ink_warning: NATURAL_32
			-- Warning-family text on `wash_warning' or on `surface'.

	ink_danger: NATURAL_32
			-- Danger-family text on `wash_danger' or on `surface'.

feature -- Secondary ink, lines, selection, scrim (GW-28)

	ink_soft: NATURAL_32
			-- Secondary body text: quieter than `ink', still body-readable
			-- (unlike `ink_muted', which is for labels and hints).

	divider: NATURAL_32
			-- Row and list separators, quieter than `outline'.

	selection: NATURAL_32
			-- Selected row or verse ground, quieter than `wash_accent';
			-- `ink' and `ink_soft' read on it.

	scrim: NATURAL_32
			-- The dimmed ground behind a modal dialog or sheet.

feature -- Sequential ramp (GW-28)

	Ramp_count: INTEGER = 5
			-- Steps in the sequential ramp.

	ramp (a_step: INTEGER): NATURAL_32
			-- Step `a_step' of the sequential ramp for heat maps and ordered
			-- charts: 1 sits nearest the surface, `Ramp_count' stands out
			-- most, in light and dark alike.
		require
			step_in_range: a_step >= 1 and a_step <= Ramp_count
		do
			inspect a_step
			when 1 then Result := ramp_1
			when 2 then Result := ramp_2
			when 3 then Result := ramp_3
			when 4 then Result := ramp_4
			else Result := ramp_5
			end
		end

feature -- Status (GW-28)

	is_high_contrast: BOOLEAN
			-- Was this theme painted from a Windows contrast theme (GW-16)?

	is_dark: BOOLEAN
			-- Is this a dark theme? Decided by its surface.
		do
			Result := luminance (surface) < 0.5
		end

	is_readable: BOOLEAN
			-- Does every text-bearing pairing meet its contrast rule?
			-- Body text 4.5:1 (WCAG AA), labels and hints 3:1, and the ramp
			-- moving strictly away from the surface step by step.
			-- Kept out of the invariant on purpose: the invariant runs on
			-- every call during painting, and this is about thirty WCAG
			-- computations. Creation procedures and the GW-28 setters
			-- guarantee it instead.
		do
			Result := contrast_ratio (ink, surface) >= Body_contrast
				and contrast_ratio (ink_soft, surface) >= Body_contrast
				and contrast_ratio (ink_muted, surface) >= Label_contrast
				and contrast_ratio (ink, selection) >= Body_contrast
				and contrast_ratio (ink_soft, selection) >= Body_contrast
				and contrast_ratio (ink_on_accent, accent) >= Body_contrast
				and contrast_ratio (ink_on_success, success) >= Body_contrast
				and contrast_ratio (ink_on_warning, warning) >= Body_contrast
				and contrast_ratio (ink_on_danger, danger) >= Body_contrast
				and contrast_ratio (ink_accent, wash_accent) >= Body_contrast
				and contrast_ratio (ink_success, wash_success) >= Body_contrast
				and contrast_ratio (ink_warning, wash_warning) >= Body_contrast
				and contrast_ratio (ink_danger, wash_danger) >= Body_contrast
				and contrast_ratio (ink_accent, surface) >= Body_contrast
				and contrast_ratio (ink_success, surface) >= Body_contrast
				and contrast_ratio (ink_warning, surface) >= Body_contrast
				and contrast_ratio (ink_danger, surface) >= Body_contrast
				and ramp_moves_away
		end

	Body_contrast: REAL_64 = 4.5
			-- WCAG AA for body text.

	Label_contrast: REAL_64 = 3.0
			-- WCAG AA for large text, labels and non-text marks.

feature -- Element change (GW-28)

	set_inks_on_fills (a_accent, a_success, a_warning, a_danger: NATURAL_32)
			-- Recolour the text drawn on filled controls.
		require
			on_accent_readable: contrast_ratio (a_accent, accent) >= Body_contrast
			on_success_readable: contrast_ratio (a_success, success) >= Body_contrast
			on_warning_readable: contrast_ratio (a_warning, warning) >= Body_contrast
			on_danger_readable: contrast_ratio (a_danger, danger) >= Body_contrast
		do
			ink_on_accent := a_accent
			ink_on_success := a_success
			ink_on_warning := a_warning
			ink_on_danger := a_danger
		ensure
			set: ink_on_accent = a_accent and ink_on_success = a_success
				and ink_on_warning = a_warning and ink_on_danger = a_danger
		end

	set_semantic_inks (a_accent, a_success, a_warning, a_danger: NATURAL_32)
			-- Recolour the strong semantic inks.
		require
			accent_readable: contrast_ratio (a_accent, wash_accent) >= Body_contrast
				and contrast_ratio (a_accent, surface) >= Body_contrast
			success_readable: contrast_ratio (a_success, wash_success) >= Body_contrast
				and contrast_ratio (a_success, surface) >= Body_contrast
			warning_readable: contrast_ratio (a_warning, wash_warning) >= Body_contrast
				and contrast_ratio (a_warning, surface) >= Body_contrast
			danger_readable: contrast_ratio (a_danger, wash_danger) >= Body_contrast
				and contrast_ratio (a_danger, surface) >= Body_contrast
		do
			ink_accent := a_accent
			ink_success := a_success
			ink_warning := a_warning
			ink_danger := a_danger
		ensure
			set: ink_accent = a_accent and ink_success = a_success
				and ink_warning = a_warning and ink_danger = a_danger
		end

	set_quiet_tones (a_ink_soft, a_divider, a_selection, a_scrim: NATURAL_32)
			-- Recolour secondary ink, dividers, selection and scrim.
		require
			soft_readable: contrast_ratio (a_ink_soft, surface) >= Body_contrast
			selection_keeps_ink: contrast_ratio (ink, a_selection) >= Body_contrast
				and contrast_ratio (a_ink_soft, a_selection) >= Body_contrast
		do
			ink_soft := a_ink_soft
			divider := a_divider
			selection := a_selection
			scrim := a_scrim
		ensure
			set: ink_soft = a_ink_soft and divider = a_divider
				and selection = a_selection and scrim = a_scrim
		end

	set_ramp (a_1, a_2, a_3, a_4, a_5: NATURAL_32)
			-- Replace the sequential ramp, nearest-the-surface first.
		require
			moves_away: contrast_ratio (a_1, surface) < contrast_ratio (a_2, surface)
				and contrast_ratio (a_2, surface) < contrast_ratio (a_3, surface)
				and contrast_ratio (a_3, surface) < contrast_ratio (a_4, surface)
				and contrast_ratio (a_4, surface) < contrast_ratio (a_5, surface)
		do
			ramp_1 := a_1
			ramp_2 := a_2
			ramp_3 := a_3
			ramp_4 := a_4
			ramp_5 := a_5
		ensure
			set: ramp (1) = a_1 and ramp (2) = a_2 and ramp (3) = a_3
				and ramp (4) = a_4 and ramp (5) = a_5
			moves_away: ramp_moves_away
		end

feature -- Adopting (GW-16)

	adopt_metrics_from (a_other: SW_THEME)
			-- Take `a_other''s text scale, spacing, type families and locale,
			-- so a contrast theme worn in place of an application's own keeps
			-- its sizes and faces.
		do
			text_scale := a_other.text_scale
			pad := a_other.pad
			gap := a_other.gap
			control_pad := a_other.control_pad
			family_ui := a_other.family_ui.twin
			family_body := a_other.family_body.twin
			family_mono := a_other.family_mono.twin
			locale := a_other.locale
		ensure
			scale_taken: text_scale = a_other.text_scale
			spacing_taken: border_width = a_other.border_width and padding = a_other.padding
				and control_inset = a_other.control_inset
			faces_taken: family_ui.same_string (a_other.family_ui) and family_body.same_string (a_other.family_body)
		end

feature -- Type roles

	family_ui: STRING_32
	family_body: STRING_32
	family_mono: STRING_32

feature -- Metrics

	text_scale: REAL_64
			-- Global text magnification applied at the painter's font
			-- choke point. 1.0 is nominal.

	set_text_scale (a_scale: REAL_64)
			-- Grow or shrink every piece of text in the toolkit.
		require
			sane: a_scale >= 0.5 and a_scale <= 3.0
		do
			text_scale := a_scale
		ensure
			set: text_scale = a_scale
		end

	radius: REAL_64
	gap: REAL_64
	pad: REAL_64
	control_pad: REAL_64
			-- Nominal INSIDE inset of a control at 1x - the space between
			-- a control's own edge and its label. Vision2 has no name for
			-- it because a native control owns its own margins; a DRAWN
			-- toolkit must carry it as a token.

	button_height: REAL_64
	chip_height: REAL_64
	size_body: REAL_64
	size_label: REAL_64
	size_chip: REAL_64
	line_height: REAL_64

feature -- Spacing (the Vision2 outside/inside model, scaled)

	border_width: REAL_64
			-- Space between a CONTAINER'S EDGE and its content, in pixels
			-- at the current `text_scale'.
			--
			-- This is EV_BOX.border_width
			-- (ISE 25.02, library/vision2/interface/widgets/containers/ev_box.e:43
			-- "Width of border around container in pixels"). Vision2's own
			-- default is 0 (EV_BOX_I.Default_border_width, implementation_
			-- interface/widgets/containers/ev_box_i.e:29) and ISE's dialogs
			-- then set it per container - EV_MESSAGE_DIALOG does
			-- `vb.set_border_width (10)'
			-- (interface/widgets/dialogs/ev_message_dialog.e:146). The
			-- toolkit does the same thing once, at the window/dialog root,
			-- so no application has to remember it and no NESTED container
			-- doubles it.
		do
			Result := pad * text_scale
		ensure
			non_negative: Result >= 0.0
			scales_with_text: Result = pad * text_scale
		end

	padding: REAL_64
			-- Space between SIBLINGS inside a container, in pixels at the
			-- current `text_scale'.
			--
			-- This is EV_BOX.padding / padding_width (ev_box.e:54, "Space
			-- between children in pixels"); the toolkit's boxes have
			-- always called it `gap', and this is the theme-level,
			-- scale-aware default that a box adopts when the application
			-- has not set one.
		do
			Result := gap * text_scale
		ensure
			non_negative: Result >= 0.0
			scales_with_text: Result = gap * text_scale
		end

	control_inset: REAL_64
			-- Space between a CONTROL'S OWN EDGE and its label, in pixels
			-- at the current `text_scale' - Vision2's "inside" padding.
			--
			-- Together with the measured font this fixes a control's
			-- MINIMUM size, the way EV_LAYOUT_CONSTANTS fixes Vision2's
			-- (contrib/ev_layout_constants.e:11-22, whose
			-- `default_button_height' is 23 dialog units run through
			-- `dialog_unit_to_pixels' - i.e. a constant SCALED by the
			-- display, exactly the role `text_scale' plays here).
		do
			Result := control_pad * text_scale
		ensure
			non_negative: Result >= 0.0
			scales_with_text: Result = control_pad * text_scale
		end

	Scrollbar_nominal: REAL_64 = 12.0
			-- `scrollbar_width' at 1x.

	Thumb_nominal: REAL_64 = 24.0
			-- `min_thumb' at 1x.

	scrollbar_width: REAL_64
			-- The column a vertical scrollbar takes (SW_VSCROLLBAR), at the
			-- current `text_scale': a bigger text gets a bigger target.
		do
			Result := Scrollbar_nominal * text_scale
		ensure
			scales_with_text: Result = Scrollbar_nominal * text_scale
		end

	min_thumb: REAL_64
			-- The shortest a scrollbar thumb ever draws, so it stays
			-- grabbable over long content.
		do
			Result := Thumb_nominal * text_scale
		ensure
			scales_with_text: Result = Thumb_nominal * text_scale
		end

	scaled_line_height: REAL_64
			-- `line_height' at the current `text_scale': a text row must
			-- grow with the glyphs standing in it.
		do
			Result := line_height * text_scale
		ensure
			non_negative: Result >= 0.0
		end

	set_spacing (a_border, a_padding, a_control_inset: REAL_64)
			-- Retune the three spacing tokens AT 1x; `border_width',
			-- `padding' and `control_inset' keep scaling with the text.
		require
			non_negative: a_border >= 0.0 and a_padding >= 0.0
				and a_control_inset >= 0.0
		do
			pad := a_border
			gap := a_padding
			control_pad := a_control_inset
		ensure
			border_set: pad = a_border
			padding_set: gap = a_padding
			inset_set: control_pad = a_control_inset
		end

feature -- Element change

	set_locale (a_locale: SW_LOCALE)
		do
			locale := a_locale
		ensure
			set: locale = a_locale
		end

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

feature {NONE} -- Ramp storage (GW-28)

	ramp_1, ramp_2, ramp_3, ramp_4, ramp_5: NATURAL_32

	ramp_moves_away: BOOLEAN
			-- Does each ramp step contrast more with the surface than the
			-- one before?
		do
			Result := contrast_ratio (ramp_1, surface) < contrast_ratio (ramp_2, surface)
				and contrast_ratio (ramp_2, surface) < contrast_ratio (ramp_3, surface)
				and contrast_ratio (ramp_3, surface) < contrast_ratio (ramp_4, surface)
				and contrast_ratio (ramp_4, surface) < contrast_ratio (ramp_5, surface)
		end

feature {NONE} -- Contrast mending (GW-16)

	readable_on (a_ink, a_ground: NATURAL_32): NATURAL_32
			-- `a_ink' when it reads on `a_ground' at body contrast; else black
			-- or white, whichever reads better (one of them always reaches
			-- 4.5:1 on any ground).
		do
			if contrast_ratio (a_ink, a_ground) >= Body_contrast then
				Result := a_ink
			elseif contrast_ratio (0x000000, a_ground) >= contrast_ratio (0xFFFFFF, a_ground) then
				Result := 0x000000
			else
				Result := 0xFFFFFF
			end
		ensure
			readable: contrast_ratio (Result, a_ground) >= Body_contrast
		end

	readable_ground (a_wanted, a_fallback, a_ink: NATURAL_32): NATURAL_32
			-- `a_wanted' if `a_ink' reads on it; else the first step from
			-- `a_wanted' toward `a_fallback' (tenths) on which it does; else
			-- `a_fallback'.
		require
			fallback_readable: contrast_ratio (a_ink, a_fallback) >= Body_contrast
		local
			k: INTEGER
		do
			Result := a_fallback
			from
				k := 10
			until
				k < 0 or else contrast_ratio (a_ink, mixed (a_fallback, a_wanted, k / 10.0)) >= Body_contrast
			loop
				k := k - 1
			end
			if k >= 0 then
				Result := mixed (a_fallback, a_wanted, k / 10.0)
			end
		ensure
			readable: contrast_ratio (a_ink, Result) >= Body_contrast
		end

	mixed (a_from, a_to: NATURAL_32; a_t: REAL_64): NATURAL_32
			-- The color `a_t' of the way from `a_from' to `a_to', per channel.
		require
			fraction: a_t >= 0.0 and a_t <= 1.0
		do
			Result := (mixed_channel ((a_from |>> 16) & 0xFF, (a_to |>> 16) & 0xFF, a_t) |<< 16)
				| (mixed_channel ((a_from |>> 8) & 0xFF, (a_to |>> 8) & 0xFF, a_t) |<< 8)
				| mixed_channel (a_from & 0xFF, a_to & 0xFF, a_t)
		ensure
			ends: (a_t = 0.0 implies Result = a_from & 0xFFFFFF) and (a_t = 1.0 implies Result = a_to & 0xFFFFFF)
		end

	mixed_channel (a_from, a_to: NATURAL_32; a_t: REAL_64): NATURAL_32
		do
			Result := (a_from.to_real_64 + (a_to.to_real_64 - a_from.to_real_64) * a_t).rounded.to_natural_32.min (255)
		end

	set_contrast_ramp (a_ground: NATURAL_32)
			-- A grey ramp from `a_ground' toward black (light grounds) or
			-- white (dark grounds): every channel moves the same way, so each
			-- step stands further from the ground than the last.
		local
			l_far: NATURAL_32
		do
			if contrast_ratio (0x000000, a_ground) >= contrast_ratio (0xFFFFFF, a_ground) then
				l_far := 0x000000
			else
				l_far := 0xFFFFFF
			end
			ramp_1 := mixed (a_ground, l_far, 0.2)
			ramp_2 := mixed (a_ground, l_far, 0.4)
			ramp_3 := mixed (a_ground, l_far, 0.6)
			ramp_4 := mixed (a_ground, l_far, 0.8)
			ramp_5 := l_far
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
	text_scale_positive: text_scale > 0.0
	border_nominal_non_negative: pad >= 0.0
	padding_nominal_non_negative: gap >= 0.0
	control_pad_non_negative: control_pad >= 0.0
	ink_readable_on_surface: contrast_ratio (ink, surface) >= 4.5
	muted_readable_on_surface: contrast_ratio (ink_muted, surface) >= 3.0

end
