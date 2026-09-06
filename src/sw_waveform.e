note
	description: "[
		A waveform: the amplitude envelope of a sound drawn as one
		vertical bar per pixel column, a playhead, and optional
		markers down the time axis. Codec-agnostic and buffer-agnostic
		like SW_MEDIA_TRANSPORT: the widget never holds the audio.

		HOW THE AUDIO ARRIVES. `set_samples' takes a COUNT, a SAMPLE
		RATE and a SAMPLER agent that answers frame `i' (0-based, the
		convention every PCM buffer already uses - simple_audio's
		`AUDIO_BUFFER.sample_at (?, 0)' passes verbatim). The widget
		reads the samples ONCE, into a summary of `Resolution' columns
		of (low, high) peaks, and never again: a nine-minute essay at
		22 kHz is twelve million samples, and a widget that copied
		them would be a second copy of the recording. At paint time
		the summary is re-bucketed to however many pixel columns the
		widget is wide, which is cheap and needs no audio.

		WHAT IT SHOWS. Bars in `ink_muted' for the part not yet
		played, `accent' for the part already played, the playhead as
		a `danger' line (the caret colour - the one thing the eye
		must find), and markers as `warning' ticks wearing their label
		in the chip font. A silence is a flat centre line, which is
		exactly the gap a pacing gate measures between sentences.

		SEEKING. A click or a drag inside the bars moves `position_s'
		and fires `on_seek' with the second it landed on; the host
		that owns the player decides what to do with it, and reports
		real progress back through `set_position'. `position_at' and
		`x_of' are public so the arithmetic can be assaulted headless.

		NOTHING HERE RAISES on odd audio: out-of-range samples are
		clamped into [-1, 1] at summary time, so a mis-scaled float
		buffer draws as full-scale rather than painting outside the
		box.
	]"
	author: "Larry Rix"

class
	SW_WAVEFORM

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag, wants_hover_point, cursor_kind
		end

create
	make

feature {NONE} -- Initialization

	make (a_height: REAL_64)
			-- An empty waveform `a_height' tall.
		require
			positive: a_height > 0.0
		do
			waveform_height := a_height
			create summary_low.make_filled (0.0, 1, 0)
			create summary_high.make_filled (0.0, 1, 0)
			create markers.make (4)
		ensure
			kept: waveform_height = a_height
			no_audio: not has_audio
		end

feature -- Access

	waveform_height: REAL_64
			-- The height this widget asks for.

	sample_count: INTEGER
			-- Frames the summary was built from; 0 before `set_samples'.

	sample_rate: INTEGER
			-- Frames per second; 0 before `set_samples'.

	position_s: REAL_64
			-- The playhead, in seconds, 0 .. `duration_s'.

	markers: ARRAYED_LIST [TUPLE [at_s: REAL_64; label: STRING_32]]
			-- Ticks down the time axis: sentence boundaries, gate
			-- findings, whatever the host wants the eye to find.

	on_seek: detachable PROCEDURE [REAL_64]
			-- Fired with the second a click or drag landed on.

	has_audio: BOOLEAN
			-- Has `set_samples' delivered anything?
		do
			Result := sample_count > 0 and sample_rate > 0
		ensure
			definition: Result = (sample_count > 0 and sample_rate > 0)
		end

	duration_s: REAL_64
			-- How long the audio runs; 0 without audio.
		do
			if has_audio then
				Result := sample_count / sample_rate
			end
		ensure
			non_negative: Result >= 0.0
			nothing_without_audio: not has_audio implies Result = 0.0
		end

	summary_count: INTEGER
			-- Columns in the summary: `Resolution', or fewer for a
			-- sound shorter than that many frames.
		do
			Result := summary_low.count
		ensure
			parallel: Result = summary_high.count
			bounded: Result <= Resolution
		end

	summary_low_at (a_i: INTEGER): REAL_64
			-- The lowest sample in summary column `a_i'.
		require
			in_range: a_i >= 1 and a_i <= summary_count
		do
			Result := summary_low [a_i]
		ensure
			in_unit: Result >= -1.0 and Result <= 1.0
		end

	summary_high_at (a_i: INTEGER): REAL_64
			-- The highest sample in summary column `a_i'.
		require
			in_range: a_i >= 1 and a_i <= summary_count
		do
			Result := summary_high [a_i]
		ensure
			in_unit: Result >= -1.0 and Result <= 1.0
			above_low: Result >= summary_low_at (a_i)
		end

	fraction: REAL_64
			-- The playhead as 0 .. 1 of the duration; 0 without audio.
		do
			if has_audio then
				Result := (position_s / duration_s).max (0.0).min (1.0)
			end
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

feature -- Geometry

	Pad_x: REAL_64 = 4.0
			-- Inset from the widget's left and right edges to the bars.

	bars_x: REAL_64
			-- Where the first bar column stands.
		do
			Result := x + Pad_x
		end

	bars_w: REAL_64
			-- How wide the bar field is; never less than one column.
		do
			Result := (width - 2.0 * Pad_x).max (1.0)
		ensure
			positive: Result >= 1.0
		end

	position_at (a_px: REAL_64): REAL_64
			-- The second a surface x names, clamped into the audio.
		do
			if has_audio then
				Result := ((a_px - bars_x) / bars_w).max (0.0).min (1.0) * duration_s
			end
		ensure
			held: Result >= 0.0 and Result <= duration_s
		end

	x_of (a_seconds: REAL_64): REAL_64
			-- The surface x where second `a_seconds' stands, clamped
			-- to the bar field.
		do
			if has_audio then
				Result := bars_x + (a_seconds / duration_s).max (0.0).min (1.0) * bars_w
			else
				Result := bars_x
			end
		ensure
			inside: Result >= bars_x and Result <= bars_x + bars_w
		end

	column_peaks (a_columns: INTEGER): TUPLE [lows, highs: ARRAY [REAL_64]]
			-- The summary re-bucketed to `a_columns' equal spans: for
			-- each column the lowest low and highest high of the
			-- summary columns it covers. Silence answers zeros.
		require
			positive: a_columns >= 1
		local
			l_lows, l_highs: ARRAY [REAL_64]
			c, s, s_from, s_to: INTEGER
			lo, hi: REAL_64
		do
			create l_lows.make_filled (0.0, 1, a_columns)
			create l_highs.make_filled (0.0, 1, a_columns)
			if summary_count > 0 then
				from
					c := 1
				until
					c > a_columns
				loop
					s_from := ((c - 1) * summary_count) // a_columns + 1
					s_to := ((c * summary_count) // a_columns).max (s_from)
					lo := summary_low [s_from]
					hi := summary_high [s_from]
					from
						s := s_from + 1
					until
						s > s_to
					loop
						lo := lo.min (summary_low [s])
						hi := hi.max (summary_high [s])
						s := s + 1
					end
					l_lows [c] := lo
					l_highs [c] := hi
					c := c + 1
				end
			end
			Result := [l_lows, l_highs]
		ensure
			one_per_column: Result.lows.count = a_columns and Result.highs.count = a_columns
			ordered_and_bounded: across 1 |..| a_columns as i all
				Result.lows [i] >= -1.0 and Result.lows [i] <= Result.highs [i]
				and Result.highs [i] <= 1.0 end
		end

feature -- Element change

	set_samples (a_count, a_rate: INTEGER; a_sampler: FUNCTION [INTEGER, REAL_64])
			-- Read frames 0 .. `a_count' - 1 through `a_sampler' once,
			-- into the summary. Out-of-range values are clamped, not
			-- refused: a mis-scaled buffer draws full-scale.
		require
			count_non_negative: a_count >= 0
			rate_positive: a_rate > 0
		local
			n, c, f, f_from, f_to: INTEGER
			v, lo, hi: REAL_64
		do
			sample_count := a_count
			sample_rate := a_rate
			n := a_count.min (Resolution)
			create summary_low.make_filled (0.0, 1, n)
			create summary_high.make_filled (0.0, 1, n)
			from
				c := 1
			until
				c > n
			loop
				f_from := ((c - 1) * a_count) // n
				f_to := ((c * a_count) // n - 1).max (f_from)
				lo := 1.0
				hi := -1.0
				from
					f := f_from
				until
					f > f_to
				loop
					v := a_sampler.item ([f]).max (-1.0).min (1.0)
					lo := lo.min (v)
					hi := hi.max (v)
					f := f + 1
				end
				summary_low [c] := lo
				summary_high [c] := hi
				c := c + 1
			end
			position_s := position_s.min (duration_s)
		ensure
			count_kept: sample_count = a_count
			rate_kept: sample_rate = a_rate
			summarised: summary_count = a_count.min (Resolution)
			playhead_held: position_s <= duration_s
		end

	set_samples_array (a_samples: ARRAY [REAL_64]; a_rate: INTEGER)
			-- The same through an array the host already holds.
		require
			rate_positive: a_rate > 0
		do
			set_samples (a_samples.count, a_rate, agent array_sample (a_samples, ?))
		ensure
			count_kept: sample_count = a_samples.count
		end

	clear_samples
			-- Forget the audio; the playhead returns to zero.
		do
			sample_count := 0
			sample_rate := 0
			create summary_low.make_filled (0.0, 1, 0)
			create summary_high.make_filled (0.0, 1, 0)
			position_s := 0.0
		ensure
			no_audio: not has_audio
			rewound: position_s = 0.0
		end

	set_position (a_seconds: REAL_64)
			-- The host reports playback progress here; clamped.
		do
			position_s := a_seconds.max (0.0).min (duration_s)
		ensure
			held: position_s >= 0.0 and position_s <= duration_s
		end

	set_on_seek (a_action: PROCEDURE [REAL_64])
		do
			on_seek := a_action
		ensure
			set: on_seek = a_action
		end

	add_marker (a_at_s: REAL_64; a_label: READABLE_STRING_GENERAL)
			-- A tick at `a_at_s' seconds wearing `a_label'.
		require
			inside: a_at_s >= 0.0 and a_at_s <= duration_s
		local
			l_label: STRING_32
		do
			create l_label.make_from_string_general (a_label)
			markers.extend ([a_at_s, l_label])
		ensure
			one_more: markers.count = old markers.count + 1
		end

	clear_markers
		do
			markers.wipe_out
		ensure
			none: markers.is_empty
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	cursor_kind: INTEGER
			-- The hand: this surface is seekable.
		do
			Result := 2
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := waveform_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- Bars, then markers, then the playhead on top.
		local
			t: SW_THEME
			peaks: TUPLE [lows, highs: ARRAY [REAL_64]]
			cols, c: INTEGER
			mid, half, bx, top, bot, px: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			mid := y + height / 2.0
			half := (height / 2.0 - 3.0).max (1.0)
			a_p.set_color (t.outline)
			a_p.hline (bars_x, mid, bars_w)
			if has_audio then
				cols := bars_w.floor.max (1)
				peaks := column_peaks (cols)
				px := x_of (position_s)
				from
					c := 1
				until
					c > cols
				loop
					bx := bars_x + (c - 1)
					if bx < px then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.ink_muted)
					end
					top := mid - peaks.highs [c] * half
					bot := mid - peaks.lows [c] * half
					if bot - top < 1.0 then
						bot := top + 1.0
					end
					a_p.fill_rect (bx, top, 1.0, bot - top)
					c := c + 1
				end
				across
					markers as m
				loop
					bx := x_of (m.at_s)
					a_p.set_color (t.warning)
					a_p.fill_rect (bx, y + 2.0, 1.0, height - 4.0)
					if not m.label.is_empty then
						a_p.font ({SW_PAINTER}.Role_mono, t.size_chip, False)
						a_p.text (bx + 3.0, y + 2.0 + a_p.font_ascent, m.label)
					end
				end
				a_p.set_color (t.danger)
				a_p.fill_rect (px - 1.0, y + 1.0, 2.0, height - 2.0)
			end
			a_p.pop_clip
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A click seeks; the host hears the second.
		do
			if is_enabled and has_audio then
				seek_to_x (a_px)
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if is_enabled and has_audio then
				seek_to_x (a_px)
			end
		end

feature {NONE} -- Implementation

	Resolution: INTEGER = 4096
			-- Summary columns read from the audio, once.

	summary_low: ARRAY [REAL_64]
			-- Per summary column, the lowest sample; parallel to `summary_high'.

	summary_high: ARRAY [REAL_64]
			-- Per summary column, the highest sample.

	seek_to_x (a_px: REAL_64)
			-- Move the playhead to the second under `a_px' and say so.
		require
			audio: has_audio
		do
			position_s := position_at (a_px)
			if attached on_seek as al_seek then
				al_seek.call ([position_s])
			end
		ensure
			landed: position_s = position_at (a_px)
		end

	array_sample (a_samples: ARRAY [REAL_64]; a_frame: INTEGER): REAL_64
			-- Frame `a_frame' (0-based) of `a_samples'.
		require
			in_range: a_frame >= 0 and a_frame < a_samples.count
		do
			Result := a_samples [a_samples.lower + a_frame]
		end

invariant
	height_positive: waveform_height > 0.0
	counts_non_negative: sample_count >= 0 and sample_rate >= 0
	summary_parallel: summary_low.count = summary_high.count
	summary_bounded: summary_low.count <= Resolution
	summary_ordered: across 1 |..| summary_low.count as i all
		summary_low [i] >= -1.0 and summary_low [i] <= summary_high [i]
		and summary_high [i] <= 1.0 end
	playhead_held: position_s >= 0.0 and position_s <= duration_s
	markers_attached: markers /= Void

end
