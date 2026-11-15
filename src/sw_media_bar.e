note
	description: "[
		A media player's transport bar, drawn: play and pause, a seek bar, the time, mute, the
		volume and full screen, left to right. simple_gui's media player shows it on Windows
		(1z-b), where a drawn window has no native media controls.

		Codec-agnostic, like SW_MEDIA_TRANSPORT, whose clock, seek arithmetic and play agents it
		keeps: the host plays the medium, hears the user through the agents (`on_play',
		`on_pause', `on_seek', `on_volume', `on_mute', `on_full_screen'), and reports back
		through the silent setters (`set_position', `set_playing', `set_duration', `set_volume',
		`set_muted', `set_full_screen'). A medium's length is not known before it is ready, so
		until `set_duration' the clock reads 0:00 and the seek bar does nothing.

		Mute and full screen ask (their agents get the state asked for); the host answers with
		the setter once the change has come, so the bar never shows a state the player is not in.
	]"

class
	SW_MEDIA_BAR

inherit
	SW_MEDIA_TRANSPORT
		rename
			make as make_transport
		redefine
			bar_w, draw, handle_click, handle_drag, preferred_width, preferred_height,
			accessible_role, default_accessible_name, accessible_value
		end

create
	make

feature {NONE} -- Initialization

	make
			-- A bar for a medium of unknown length, paused, at full volume.
		do
			make_transport (1.0)
			volume := 1.0
		ensure
			unknown_length: not has_duration
			paused: not is_playing
			at_start: position_s = 0.0
			full_volume: volume = 1.0
			not_muted: not is_muted
			not_full_screen: not is_full_screen
		end

feature -- Access

	has_duration: BOOLEAN
			-- Has the host told the medium's length (`set_duration')?

	volume: REAL_64
			-- 0 (silent) to 1 (full), as the host last told or the user last chose.

	is_muted: BOOLEAN

	is_full_screen: BOOLEAN

	on_volume: detachable PROCEDURE [REAL_64]
			-- The user chose this volume (0 to 1) on the volume bar.

	on_mute: detachable PROCEDURE [BOOLEAN]
			-- The user asked for sound off (True) or on (False).

	on_full_screen: detachable PROCEDURE [BOOLEAN]
			-- The user asked to fill the screen (True) or to come back (False).

	Mute_zone: REAL_64 = 32.0
			-- The mute button's width.

	Volume_zone: REAL_64 = 72.0
			-- The volume bar's width, its margins included.

	Full_screen_zone: REAL_64 = 40.0
			-- The full screen button's width.

	Bar_height: REAL_64 = 40.0
			-- The height it asks for.

	tail_w: REAL_64
			-- The width of the part right of the clock: mute, volume and full screen.
		do
			Result := Mute_zone + Volume_zone + Full_screen_zone
		end

	bar_w: REAL_64
			-- The seek bar's length: what is left after the button, the clock and the tail.
		do
			Result := (width - Button_zone - Time_zone - tail_w).max (10.0)
		end

	time_x: REAL_64
			-- Where the clock starts.
		do
			Result := bar_x + bar_w
		end

	mute_x: REAL_64
			-- Where the mute button starts.
		do
			Result := time_x + Time_zone
		end

	volume_x: REAL_64
			-- Where the volume bar's track starts.
		do
			Result := mute_x + Mute_zone + 6.0
		end

	volume_w: REAL_64
			-- The volume bar's track length.
		do
			Result := Volume_zone - 12.0
		end

	full_screen_x: REAL_64
			-- Where the full screen button starts.
		do
			Result := mute_x + Mute_zone + Volume_zone
		end

	volume_at (a_px: REAL_64): REAL_64
			-- The volume the volume bar names at a surface x, clamped.
		do
			Result := ((a_px - volume_x) / volume_w).max (0.0).min (1.0)
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

	shown_fraction: REAL_64
			-- How far along the seek bar shows it: `fraction', or 0 with no length known.
		do
			if has_duration then
				Result := fraction
			end
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

feature -- Element change (the host reports; none of these calls an agent)

	set_duration (a_seconds: REAL_64)
			-- The medium's length is known: `a_seconds'.
		require
			some_length: a_seconds > 0.0
		do
			duration_s := a_seconds
			has_duration := True
			position_s := position_s.min (duration_s)
		ensure
			kept: duration_s = a_seconds
			known: has_duration
		end

	clear_duration
			-- A new medium, length not known yet: back to the start.
		do
			duration_s := 1.0
			has_duration := False
			position_s := 0.0
		ensure
			unknown: not has_duration
			at_start: position_s = 0.0
		end

	set_playing (a_on: BOOLEAN)
			-- The medium plays (`a_on') or is paused.
		do
			is_playing := a_on
		ensure
			set: is_playing = a_on
		end

	set_volume (a_volume: REAL_64)
		require
			unit: a_volume >= 0.0 and a_volume <= 1.0
		do
			volume := a_volume
		ensure
			set: volume = a_volume
		end

	set_muted (a_on: BOOLEAN)
		do
			is_muted := a_on
		ensure
			set: is_muted = a_on
		end

	set_full_screen (a_on: BOOLEAN)
		do
			is_full_screen := a_on
		ensure
			set: is_full_screen = a_on
		end

	set_on_volume (a_action: PROCEDURE [REAL_64])
		do
			on_volume := a_action
		ensure
			set: on_volume = a_action
		end

	set_on_mute (a_action: PROCEDURE [BOOLEAN])
		do
			on_mute := a_action
		ensure
			set: on_mute = a_action
		end

	set_on_full_screen (a_action: PROCEDURE [BOOLEAN])
		do
			on_full_screen := a_action
		ensure
			set: on_full_screen = a_action
		end

feature -- Basic operations (as the user's clicks)

	ask_mute
			-- The user's click on the mute button: sound off when on, on when off.
		do
			is_muted := not is_muted
			if attached on_mute as al_mute then
				al_mute.call (is_muted)
			end
		ensure
			flipped: is_muted = not old is_muted
		end

	ask_full_screen
			-- The user's click on the full screen button: ask for the other state. The bar shows
			-- it once the host says it came (`set_full_screen').
		do
			if attached on_full_screen as al_full then
				al_full.call (not is_full_screen)
			end
		ensure
			unchanged: is_full_screen = old is_full_screen
		end

	choose_volume (a_volume: REAL_64)
			-- The user's choice on the volume bar.
		require
			unit: a_volume >= 0.0 and a_volume <= 1.0
		do
			volume := a_volume
			if attached on_volume as al_volume then
				al_volume.call (a_volume)
			end
		ensure
			set: volume = a_volume
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- Its button, a seek bar `Min_bar_width' long, its clock and its tail.
		do
			Result := Button_zone + Min_bar_width + Time_zone + tail_w
		ensure then
			room_for_all: Result >= Button_zone + Min_bar_width + Time_zone + tail_w
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Bar_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cy, l_fx, l_mx, l_s: REAL_64
			clock: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.fill_rect (x, y, width, height)
			cy := y + height / 2.0
				-- play / pause, as the transport draws them
			a_p.set_color (t.accent)
			if is_playing then
				a_p.fill_rect (x + 15.0, cy - 8.0, 5.0, 16.0)
				a_p.fill_rect (x + 24.0, cy - 8.0, 5.0, 16.0)
			else
				a_p.triangle_fill (x + 16.0, cy - 9.0, x + 30.0, cy, x + 16.0, cy + 9.0)
			end
				-- the seek bar
			a_p.set_color (t.surface_variant)
			a_p.rrect_fill (bar_x, cy - 3.0, bar_w, 6.0, 3.0)
			a_p.set_color (t.accent)
			a_p.rrect_fill (bar_x, cy - 3.0, (bar_w * shown_fraction).max (1.0), 6.0, 3.0)
			a_p.circle_fill (bar_x + bar_w * shown_fraction, cy, 6.0)
				-- the clock
			create clock.make (16)
			clock.append (format_clock (position_s))
			clock.append ({STRING_32} " / ")
			if has_duration then
				clock.append (format_clock (duration_s))
			else
				clock.append (format_clock (0.0))
			end
			a_p.font ({SW_PAINTER}.Role_mono, 11.5, False)
			a_p.set_color (t.ink_muted)
			a_p.text (time_x + 8.0, cy + 4.0, clock)
				-- mute: a speaker, struck through when muted
			l_mx := mute_x + 9.0
			a_p.set_color (t.ink)
			a_p.fill_rect (l_mx, cy - 3.0, 4.0, 6.0)
			a_p.triangle_fill (l_mx + 4.0, cy - 3.0, l_mx + 10.0, cy - 8.0, l_mx + 10.0, cy + 8.0)
			a_p.triangle_fill (l_mx + 4.0, cy + 3.0, l_mx + 4.0, cy - 3.0, l_mx + 10.0, cy + 8.0)
			if is_muted then
				a_p.set_color (t.danger)
				a_p.line (l_mx - 2.0, cy + 8.0, l_mx + 14.0, cy - 8.0, 2.0)
			end
				-- the volume
			a_p.set_color (t.surface_variant)
			a_p.rrect_fill (volume_x, cy - 2.0, volume_w, 4.0, 2.0)
			if is_muted then
				a_p.set_color (t.ink_muted)
			else
				a_p.set_color (t.accent)
			end
			a_p.rrect_fill (volume_x, cy - 2.0, (volume_w * volume).max (1.0), 4.0, 2.0)
			a_p.circle_fill (volume_x + volume_w * volume, cy, 5.0)
				-- full screen: four corners, pointing in while full screen
			l_fx := full_screen_x + Full_screen_zone / 2.0
			l_s := 7.0
			a_p.set_color (t.ink)
			if is_full_screen then
				a_p.line (l_fx - l_s, cy - 3.0, l_fx - 3.0, cy - 3.0, 2.0)
				a_p.line (l_fx - 3.0, cy - 3.0, l_fx - 3.0, cy - l_s, 2.0)
				a_p.line (l_fx + 3.0, cy - l_s, l_fx + 3.0, cy - 3.0, 2.0)
				a_p.line (l_fx + 3.0, cy - 3.0, l_fx + l_s, cy - 3.0, 2.0)
				a_p.line (l_fx - l_s, cy + 3.0, l_fx - 3.0, cy + 3.0, 2.0)
				a_p.line (l_fx - 3.0, cy + 3.0, l_fx - 3.0, cy + l_s, 2.0)
				a_p.line (l_fx + 3.0, cy + l_s, l_fx + 3.0, cy + 3.0, 2.0)
				a_p.line (l_fx + 3.0, cy + 3.0, l_fx + l_s, cy + 3.0, 2.0)
			else
				a_p.line (l_fx - l_s, cy - l_s, l_fx - 3.0, cy - l_s, 2.0)
				a_p.line (l_fx - l_s, cy - l_s, l_fx - l_s, cy - 3.0, 2.0)
				a_p.line (l_fx + 3.0, cy - l_s, l_fx + l_s, cy - l_s, 2.0)
				a_p.line (l_fx + l_s, cy - l_s, l_fx + l_s, cy - 3.0, 2.0)
				a_p.line (l_fx - l_s, cy + l_s, l_fx - 3.0, cy + l_s, 2.0)
				a_p.line (l_fx - l_s, cy + l_s, l_fx - l_s, cy + 3.0, 2.0)
				a_p.line (l_fx + 3.0, cy + l_s, l_fx + l_s, cy + l_s, 2.0)
				a_p.line (l_fx + l_s, cy + l_s, l_fx + l_s, cy + 3.0, 2.0)
			end
			a_p.set_color (t.outline)
			a_p.hline (x, y, width)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- Play or pause, seek, mute, the volume or full screen, by where it lands.
		do
			if is_enabled then
				if a_px < x + Button_zone then
					toggle_play
				elseif a_px <= bar_x + bar_w then
					seek_to (a_px)
				elseif a_px < mute_x then
						-- the clock: nothing to do
				elseif a_px < mute_x + Mute_zone then
					ask_mute
				elseif a_px < full_screen_x then
					choose_volume (volume_at (a_px))
				else
					ask_full_screen
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
			-- Along the seek bar, seek; along the volume bar, the volume.
		do
			if a_px >= bar_x - 8.0 and then a_px <= bar_x + bar_w + 8.0 then
				seek_to (a_px)
			elseif a_px >= volume_x - 8.0 and then a_px <= volume_x + volume_w + 8.0 then
				choose_volume (volume_at (a_px))
			end
		end

feature -- Accessibility

	accessible_role: INTEGER
			-- A toolbar.
		do
			Result := {SW_ACCESSIBILITY}.Role_tool_bar
		end

	default_accessible_name: STRING_32
		do
			Result := {STRING_32} "Media controls"
		end

	accessible_value: detachable READABLE_STRING_32
			-- "Playing, 0:12 of 1:05, volume 80 percent" and so on.
		local
			l_value: STRING_32
		do
			create l_value.make (48)
			if is_playing then
				l_value.append ({STRING_32} "Playing, ")
			else
				l_value.append ({STRING_32} "Paused, ")
			end
			l_value.append (format_clock (position_s))
			if has_duration then
				l_value.append ({STRING_32} " of ")
				l_value.append (format_clock (duration_s))
			end
			if is_muted then
				l_value.append ({STRING_32} ", muted")
			else
				l_value.append ({STRING_32} ", volume ")
				l_value.append_string_general ((volume * 100.0).rounded.out)
				l_value.append ({STRING_32} " percent")
			end
			Result := l_value
		end

feature {NONE} -- Implementation

	seek_to (a_px: REAL_64)
			-- The user chose the second the seek bar names at `a_px', when a length is known.
		do
			if has_duration then
				set_position (position_at (a_px))
				if attached on_seek as al_seek then
					al_seek.call (position_s)
				end
			end
		end

invariant
	volume_in_unit: volume >= 0.0 and volume <= 1.0

end
