note
	description: "[
		Twelve hues, each with an INK and a WASH for a light theme and
		again for a dark one - and the promise, stated as postconditions
		against the theme's own WCAG arithmetic, that neither can make
		text hard to read:

		    wash   tints BEHIND the text: the theme's ink on it reads
		           at 4.5:1 or better (AA for body text)
		    ink    colours the text itself, an outline or a box: it
		           reads on the theme's surface at 3:1 or better (AA
		           for large type and graphics, which is what a box
		           rule and a coloured word are)

		Light themes get pale washes and deep inks; dark themes get deep
		washes and pale inks. Which a theme is comes from the luminance
		of its surface, so a custom theme is served correctly without
		declaring anything.

		The values were chosen by hand and are HELD by the contracts:
		change one and the assault that walks every hue on both shipped
		themes says so. Nothing here depends on the widgets; a chart or
		a legend swatch may use the same twelve.
	]"
	author: "Larry Rix"

class
	SW_MARK_PALETTE

feature -- Access

	Hue_count: INTEGER = 12

	name (a_hue: INTEGER): STRING_32
			-- The hue's plain name.
		require
			hue_known: a_hue >= 1 and a_hue <= Hue_count
		do
			inspect a_hue
			when 1 then
				Result := {STRING_32} "red"
			when 2 then
				Result := {STRING_32} "orange"
			when 3 then
				Result := {STRING_32} "amber"
			when 4 then
				Result := {STRING_32} "yellow"
			when 5 then
				Result := {STRING_32} "lime"
			when 6 then
				Result := {STRING_32} "green"
			when 7 then
				Result := {STRING_32} "teal"
			when 8 then
				Result := {STRING_32} "cyan"
			when 9 then
				Result := {STRING_32} "blue"
			when 10 then
				Result := {STRING_32} "indigo"
			when 11 then
				Result := {STRING_32} "violet"
			else
				Result := {STRING_32} "magenta"
			end
		ensure
			named: not Result.is_empty
		end

	is_dark (a_theme: SW_THEME): BOOLEAN
			-- Is `a_theme' a dark one? Decided by its surface, so a
			-- custom theme needs no declaration.
		do
			Result := a_theme.luminance (a_theme.surface) < 0.5
		end

	ink (a_hue: INTEGER; a_theme: SW_THEME): NATURAL_32
			-- The colour for the text itself, an outline or a box rule.
		require
			hue_known: a_hue >= 1 and a_hue <= Hue_count
		do
			if is_dark (a_theme) then
				Result := Dark_inks [a_hue]
			else
				Result := Light_inks [a_hue]
			end
		ensure
			readable_on_surface: a_theme.contrast_ratio (Result, a_theme.surface) >= 3.0
		end

	wash (a_hue: INTEGER; a_theme: SW_THEME): NATURAL_32
			-- The tint behind the text.
		require
			hue_known: a_hue >= 1 and a_hue <= Hue_count
		do
			if is_dark (a_theme) then
				Result := Dark_washes [a_hue]
			else
				Result := Light_washes [a_hue]
			end
		ensure
			text_readable_on_it: a_theme.contrast_ratio (a_theme.ink, Result) >= 4.5
		end

feature {NONE} -- Values

	Light_inks: ARRAY [NATURAL_32]
			-- Deep, saturated; on a white surface.
		once
			Result := <<0xB3261E, 0xB45309, 0x92610A, 0x7A5C00, 0x4D7C0F, 0x15803D,
				0x0F766E, 0x0E7490, 0x1D4ED8, 0x4338CA, 0x7E22CE, 0xBE185D>>
		end

	Light_washes: ARRAY [NATURAL_32]
			-- Pale tints; dark ink reads on them.
		once
			Result := <<0xFEE2E2, 0xFFEDD5, 0xFEF3C7, 0xFEF9C3, 0xECFCCB, 0xDCFCE7,
				0xCCFBF1, 0xCFFAFE, 0xDBEAFE, 0xE0E7FF, 0xF3E8FF, 0xFCE7F3>>
		end

	Dark_inks: ARRAY [NATURAL_32]
			-- Pale, saturated; on a near-black surface.
		once
			Result := <<0xF87171, 0xFB923C, 0xFBBF24, 0xFDE047, 0xA3E635, 0x4ADE80,
				0x2DD4BF, 0x22D3EE, 0x60A5FA, 0xA5B4FC, 0xC084FC, 0xF472B6>>
		end

	Dark_washes: ARRAY [NATURAL_32]
			-- Deep tints; pale ink reads on them.
		once
			Result := <<0x3B1111, 0x3D2008, 0x3D2E05, 0x3A3505, 0x263A08, 0x0C3A1E,
				0x0A3A34, 0x083744, 0x0F2A5C, 0x1E1B4B, 0x2E1065, 0x4A0F2E>>
		end

end
