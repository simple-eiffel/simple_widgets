note
	description: "[
		Colour arithmetic on 0xRRGGBB values, in one place (pushed up
		2026-10-25 from SW_THEME, SW_PAINTER, SW_HEATMAP and
		SW_COLOR_PICKER, whose copies had drifted - the heat map's blend
		did not clamp): the channels as fractions, WCAG relative luminance
		and contrast ratio, and a channel-wise blend. Stateless: inherit it
		beside anything that needs it.
	]"

deferred class
	SW_COLOR_MATH

feature -- Channels

	channel_fraction (a_rgb: NATURAL_32; a_shift: INTEGER): REAL_64
			-- The channel at `a_shift' (16 red, 8 green, 0 blue) as 0 to 1.
		require
			a_channel: a_shift = 16 or a_shift = 8 or a_shift = 0
		do
			Result := a_rgb.bit_shift_right (a_shift).bit_and (0xFF) / 255.0
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

feature -- Contrast

	luminance (a_rgb: NATURAL_32): REAL_64
			-- Relative luminance per WCAG.
		do
			Result := 0.2126 * linear (channel_fraction (a_rgb, 16)) + 0.7152 * linear (channel_fraction (a_rgb, 8))
				+ 0.0722 * linear (channel_fraction (a_rgb, 0))
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

feature -- Blending

	mixed (a_from, a_to: NATURAL_32; a_t: REAL_64): NATURAL_32
			-- The colour `a_t' of the way from `a_from' to `a_to', per channel.
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
			-- One channel `a_t' of the way, clamped to 0 .. 255.
		do
			Result := (a_from.to_real_64 + (a_to.to_real_64 - a_from.to_real_64) * a_t).rounded.max (0).to_natural_32.min (255)
		ensure
			byte: Result <= 255
		end

feature {NONE} -- Implementation

	linear (a_s: REAL_64): REAL_64
			-- The sRGB channel `a_s' (0 to 1) linearised, per WCAG.
		do
			if a_s <= 0.03928 then
				Result := a_s / 12.92
			else
				Result := ((a_s + 0.055) / 1.055) ^ 2.4
			end
		end

end
