note
	description: "[
		Wave 6 media: the transport - play/pause, a seek bar, and
		m:ss readouts. Deliberately CODEC-AGNOSTIC: this is the
		control surface, and playback belongs to whoever owns the
		medium (simple_audio's player is the natural mate) - the
		host subscribes on_play / on_pause / on_seek and reports
		position back through set_position. The clock formatting
		(format_clock) and the seek arithmetic (position_at,
		fraction) are public and assaulted.
	]"

class
	SW_MEDIA_TRANSPORT

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag
		end

create
	make

feature {NONE} -- Initialization

	make (a_duration_s: REAL_64)
		require
			some_length: a_duration_s > 0.0
		do
			duration_s := a_duration_s
		ensure
			kept: duration_s = a_duration_s
		end

feature -- Access

	duration_s: REAL_64

	position_s: REAL_64

	is_playing: BOOLEAN

	on_play, on_pause: detachable PROCEDURE

	on_seek: detachable PROCEDURE [REAL_64]

	Button_zone: REAL_64 = 44.0

	Time_zone: REAL_64 = 96.0

	fraction: REAL_64
		do
			Result := (position_s / duration_s).max (0.0).min (1.0)
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

	bar_x: REAL_64
		do
			Result := x + Button_zone
		end

	bar_w: REAL_64
		do
			Result := (width - Button_zone - Time_zone).max (10.0)
		end

	position_at (a_px: REAL_64): REAL_64
			-- The second the bar names at a surface x, clamped.
		do
			Result := ((a_px - bar_x) / bar_w).max (0.0).min (1.0) * duration_s
		ensure
			held: Result >= 0.0 and Result <= duration_s
		end

	format_clock (a_seconds: REAL_64): STRING_32
			-- "m:ss", floored, honest on the hour boundary too
			-- (61:05 rather than lying wraps).
		local
			total, m, s: INTEGER
		do
			total := a_seconds.max (0.0).truncated_to_integer
			m := total // 60
			s := total \\ 60
			create Result.make (8)
			Result.append_string_general (m.out)
			Result.append_character (':')
			if s < 10 then
				Result.append_character ('0')
			end
			Result.append_string_general (s.out)
		end

feature -- Element change

	set_position (a_seconds: REAL_64)
			-- The host reports playback progress here; clamped.
		do
			position_s := a_seconds.max (0.0).min (duration_s)
		ensure
			held: position_s >= 0.0 and position_s <= duration_s
		end

	set_on_play (a_action: PROCEDURE)
		do
			on_play := a_action
		end

	set_on_pause (a_action: PROCEDURE)
		do
			on_pause := a_action
		end

	set_on_seek (a_action: PROCEDURE [REAL_64])
		do
			on_seek := a_action
		end

	toggle_play
		do
			is_playing := not is_playing
			if is_playing then
				if attached on_play as a then
					a.call (Void)
				end
			elseif attached on_pause as a then
				a.call (Void)
			end
		ensure
			flipped: is_playing = not old is_playing
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 44.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cy: REAL_64
			clock: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			cy := y + height / 2.0
				-- play / pause glyph
			a_p.set_color (t.accent)
			if is_playing then
				a_p.fill_rect (x + 15.0, cy - 8.0, 5.0, 16.0)
				a_p.fill_rect (x + 24.0, cy - 8.0, 5.0, 16.0)
			else
				a_p.polygon_fill (create {ARRAYED_LIST [TUPLE [px, py: REAL_64]]}.make_from_array
					(<<[x + 16.0, cy - 9.0], [x + 30.0, cy], [x + 16.0, cy + 9.0]>>))
			end
				-- the bar
			a_p.set_color (t.surface_variant)
			a_p.rrect_fill (bar_x, cy - 3.0, bar_w, 6.0, 3.0)
			a_p.set_color (t.accent)
			a_p.rrect_fill (bar_x, cy - 3.0, (bar_w * fraction).max (1.0), 6.0, 3.0)
			a_p.circle_fill (bar_x + bar_w * fraction, cy, 6.0)
				-- the clocks
			create clock.make (16)
			clock.append (format_clock (position_s))
			clock.append ({STRING_32} " / ")
			clock.append (format_clock (duration_s))
			a_p.font ({SW_PAINTER}.Role_mono, 11.5, False)
			a_p.set_color (t.ink_muted)
			a_p.text (x + width - Time_zone + 8.0, cy + 4.0, clock)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if a_px < x + Button_zone then
					toggle_play
				elseif a_px <= bar_x + bar_w then
					set_position (position_at (a_px))
					if attached on_seek as a then
						a.call (position_s)
					end
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if a_px >= bar_x - 8.0 and then a_px <= bar_x + bar_w + 8.0 then
				set_position (position_at (a_px))
				if attached on_seek as a then
					a.call (position_s)
				end
			end
		end

invariant
	length_positive: duration_s > 0.0
	position_held: position_s >= 0.0 and position_s <= duration_s

end
