note
	description: "[
		Colour, drawn: a saturation/value field banded from the
		current hue, a hue bar, a live swatch and hex readout.
		HSV in the model, RGB at the border - on_change delivers
		0xRRGGBB. Every conversion is contract-clamped.
	]"

class
	SW_COLOR_PICKER

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag, wants_hover_point,
			handle_char, accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make (a_rgb: NATURAL_32)
		do
			set_rgb (a_rgb)
		ensure
			plausible: rgb <= 0xFFFFFF
		end

feature -- Access

	hue: REAL_64
			-- 0.0 .. 360.0 (exclusive at the top).

	saturation, brightness: REAL_64
			-- 0.0 .. 1.0. ('value' is an Eiffel-adjacent trap in
			-- agent contexts; 'brightness' says the same thing.)

	on_change: detachable PROCEDURE [NATURAL_32]

	Field_h: REAL_64 = 140.0

	Bar_h: REAL_64 = 18.0

	accepts_focus: BOOLEAN
			-- Focusable: hex digits type straight into the readout.
		do
			Result := True
		end

	is_editing_hex: BOOLEAN
			-- Is a typed hex value building in the readout?

	hex_buffer: STRING_32
		attribute
			create Result.make (7)
		end

	from_hex (a_hex: READABLE_STRING_GENERAL): BOOLEAN
			-- Parse '#RRGGBB', 'RRGGBB' or '#RGB' and adopt the
			-- colour; False (and no change) on anything else.
		local
			s: STRING_32
			i, v, d: INTEGER
			c: CHARACTER_32
			ok: BOOLEAN
		do
			create s.make_from_string_general (a_hex)
			s.left_adjust
			s.right_adjust
			if not s.is_empty and then s.item (1) = '#' then
				s.remove_head (1)
			end
			if s.count = 3 then
					-- #RGB doubles each nibble
				s := {STRING_32} "" + s.item (1).out + s.item (1).out
					+ s.item (2).out + s.item (2).out
					+ s.item (3).out + s.item (3).out
			end
			if s.count = 6 then
				ok := True
				from
					i := 1
				until
					i > 6 or not ok
				loop
					c := s.item (i).as_lower
					if c >= '0' and c <= '9' then
						d := c.code - ('0').code
					elseif c >= 'a' and c <= 'f' then
						d := c.code - ('a').code + 10
					else
						ok := False
					end
					v := v * 16 + d
					i := i + 1
				end
				if ok then
					set_rgb (v.to_natural_32)
					Result := True
				end
			end
		end

	handle_char (a_code: INTEGER)
			-- Hex digits and '#' build a typed value; Enter adopts
			-- it (via from_hex), Escape abandons, Backspace edits.
		do
			if a_code = 13 then
				if from_hex (hex_buffer) then
				end
				is_editing_hex := False
				hex_buffer.wipe_out
			elseif a_code = 27 then
				is_editing_hex := False
				hex_buffer.wipe_out
			elseif a_code = 8 then
				if not hex_buffer.is_empty then
					hex_buffer.remove_tail (1)
				end
			elseif a_code = 35 or (a_code >= 48 and a_code <= 57)
				or (a_code >= 65 and a_code <= 70)
				or (a_code >= 97 and a_code <= 102)
			then
				if hex_buffer.count < 7 then
					is_editing_hex := True
					hex_buffer.append_character (a_code.to_character_32)
				end
			end
		end

	rgb: NATURAL_32
			-- The current colour as 0xRRGGBB.
		do
			Result := hsv_to_rgb (hue, saturation, brightness)
		end

	hex_text: STRING_32
			-- '#RRGGBB' readout.
		local
			hx: STRING_8
		do
			hx := rgb.to_hex_string
			create Result.make (7)
			Result.append_character ('#')
			Result.append_string_general (hx.substring (3, 8))
		ensure
			seven: Result.count = 7
		end

feature -- Element change

	set_rgb (a_rgb: NATURAL_32)
		local
			r, g, b, mx, mn, d, q: REAL_64
		do
			r := (a_rgb.bit_shift_right (16).bit_and (0xFF)) / 255.0
			g := (a_rgb.bit_shift_right (8).bit_and (0xFF)) / 255.0
			b := (a_rgb.bit_and (0xFF)) / 255.0
			mx := r.max (g.max (b))
			mn := r.min (g.min (b))
			d := mx - mn
			brightness := mx
			if mx > 0.0 then
				saturation := d / mx
			else
				saturation := 0.0
			end
			if d = 0.0 then
				hue := 0.0
			elseif mx = r then
				q := (g - b) / d
				hue := 60.0 * (q - 6.0 * (q / 6.0).floor)
			elseif mx = g then
				hue := 60.0 * (((b - r) / d) + 2.0)
			else
				hue := 60.0 * (((r - g) / d) + 4.0)
			end
			if hue < 0.0 then
				hue := hue + 360.0
			end
		ensure
			ranges_hold: saturation >= 0.0 and saturation <= 1.0
				and brightness >= 0.0 and brightness <= 1.0
		end

	set_on_change (a_action: PROCEDURE [NATURAL_32])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Conversion

	hsv_to_rgb (a_h, a_s, a_v: REAL_64): NATURAL_32
		require
			hue_range: a_h >= 0.0 and a_h < 360.0
			sat_range: a_s >= 0.0 and a_s <= 1.0
			val_range: a_v >= 0.0 and a_v <= 1.0
		local
			c, xx, m, r, g, b, q: REAL_64
			sector: INTEGER
		do
			c := a_v * a_s
			sector := (a_h / 60.0).truncated_to_integer
			q := a_h / 60.0
			xx := c * (1.0 - ((q - 2.0 * (q / 2.0).floor) - 1.0).abs)
			m := a_v - c
			inspect sector
			when 0 then
				r := c
				g := xx
			when 1 then
				r := xx
				g := c
			when 2 then
				g := c
				b := xx
			when 3 then
				g := xx
				b := c
			when 4 then
				r := xx
				b := c
			else
				r := c
				b := xx
			end
			Result := (((r + m) * 255.0).rounded.to_natural_32.bit_shift_left (16))
				.bit_or (((g + m) * 255.0).rounded.to_natural_32.bit_shift_left (8))
				.bit_or (((b + m) * 255.0).rounded.to_natural_32)
		ensure
			in_range: Result <= 0xFFFFFF
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Field_h + 8.0 + Bar_h + 8.0 + 26.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, j: INTEGER
			bw, bh, cx, cy: REAL_64
			s, v: REAL_64
		do
			t := a_p.theme
				-- the saturation/value field, banded 24 x 12
			bw := width / 24.0
			bh := Field_h / 12.0
			from
				i := 0
			until
				i >= 24
			loop
				from
					j := 0
				until
					j >= 12
				loop
					s := (i + 0.5) / 24.0
					v := 1.0 - (j + 0.5) / 12.0
					a_p.set_color (hsv_to_rgb (hue, s, v))
					a_p.fill_rect (x + i * bw, y + j * bh, bw + 0.5, bh + 0.5)
					j := j + 1
				end
				i := i + 1
			end
				-- the picked point
			cx := x + saturation * width
			cy := y + (1.0 - brightness) * Field_h
			a_p.set_color (0xFFFFFF)
			a_p.circle_stroke (cx, cy, 6.0)
			a_p.set_color (0x000000)
			a_p.circle_stroke (cx, cy, 7.0)
				-- the hue bar
			from
				i := 0
			until
				i >= 36
			loop
				a_p.set_color (hsv_to_rgb (i * 10.0, 1.0, 1.0))
				a_p.fill_rect (x + i * (width / 36.0), y + Field_h + 8.0, width / 36.0 + 0.5, Bar_h)
				i := i + 1
			end
			cx := x + (hue / 360.0) * width
			a_p.set_color (0xFFFFFF)
			a_p.rrect_stroke (cx - 2.0, y + Field_h + 6.5, 4.0, Bar_h + 3.0, 2.0)
				-- swatch and hex
			a_p.set_color (rgb)
			a_p.rrect_fill (x, y + Field_h + 8.0 + Bar_h + 8.0, 46.0, 22.0, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + Field_h + 8.0 + Bar_h + 8.5, 45.0, 21.0, t.radius)
			a_p.font ({SW_PAINTER}.Role_mono, t.size_label, False)
			if is_editing_hex then
				a_p.set_color (t.accent)
				a_p.text (x + 56.0, y + Field_h + 8.0 + Bar_h + 24.0,
					hex_buffer + {STRING_32} "|")
			else
				a_p.set_color (t.ink)
				a_p.text (x + 56.0, y + Field_h + 8.0 + Bar_h + 24.0, hex_text)
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				apply_point (a_px, a_py)
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			apply_point (a_px, a_py)
		end

feature {NONE} -- Engine

	apply_point (a_px, a_py: REAL_64)
		do
			if a_py < y + Field_h then
				saturation := ((a_px - x) / width).max (0.0).min (1.0)
				brightness := (1.0 - (a_py - y) / Field_h).max (0.0).min (1.0)
				fire
			elseif a_py >= y + Field_h + 8.0 and a_py < y + Field_h + 8.0 + Bar_h then
				hue := (((a_px - x) / width) * 360.0).max (0.0).min (359.9)
				fire
			end
		end

	fire
		do
			if attached on_change as a then
				a.call (rgb)
			end
		end

invariant
	hue_range: hue >= 0.0 and hue < 360.0
	sat_range: saturation >= 0.0 and saturation <= 1.0
	val_range: brightness >= 0.0 and brightness <= 1.0

end
