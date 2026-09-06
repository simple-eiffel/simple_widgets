note
	description: "[
		Assault on SW_WAVEFORM: the summary built once from a sampler
		(silence flat, a sine full-scale, out-of-range clamped, a
		short sound not padded), re-bucketing to any column count,
		the seek arithmetic both ways, click firing on_seek, marker
		bounds, and a headless paint through a real painter.
	]"

class
	SW_WAVEFORM_ASSAULT

inherit
	TEST_SET_BASE

feature -- Summary

	test_silence_is_flat
		local
			w: SW_WAVEFORM
			i: INTEGER
		do
			create w.make (60.0)
			w.set_samples (22050, 22050, agent silence)
			assert ("has audio", w.has_audio)
			assert_reals_equal ("one second", 1.0, w.duration_s, 1.0e-9)
			assert_integers_equal ("full summary", 4096, w.summary_count)
			from i := 1 until i > w.summary_count loop
				assert ("flat low", w.summary_low_at (i) = 0.0)
				assert ("flat high", w.summary_high_at (i) = 0.0)
				i := i + 1
			end
		end

	test_sine_reaches_full_scale
		local
			w: SW_WAVEFORM
			i: INTEGER
			top, bottom: REAL_64
		do
			create w.make (60.0)
			w.set_samples (44100, 44100, agent sine_440)
			top := -2.0
			bottom := 2.0
			from i := 1 until i > w.summary_count loop
				top := top.max (w.summary_high_at (i))
				bottom := bottom.min (w.summary_low_at (i))
				i := i + 1
			end
			assert ("peaks near +1", top > 0.95 and top <= 1.0)
			assert ("troughs near -1", bottom < -0.95 and bottom >= -1.0)
		end

	test_out_of_range_samples_are_clamped
		local
			w: SW_WAVEFORM
		do
			create w.make (60.0)
			w.set_samples (100, 100, agent loud)
				-- one frame per column here: frame 0 is +3, frame 1 is -3
			assert_reals_equal ("clamped to +1", 1.0, w.summary_high_at (1), 1.0e-12)
			assert_reals_equal ("a lone loud frame is its own low", 1.0, w.summary_low_at (1), 1.0e-12)
			assert_reals_equal ("clamped to -1", -1.0, w.summary_low_at (2), 1.0e-12)
			assert_reals_equal ("a lone quiet frame is its own high", -1.0, w.summary_high_at (2), 1.0e-12)
		end

	test_short_sound_is_not_padded
		local
			w: SW_WAVEFORM
		do
			create w.make (60.0)
			w.set_samples (100, 8000, agent silence)
			assert_integers_equal ("one column per frame", 100, w.summary_count)
			w.clear_samples
			assert ("cleared", not w.has_audio)
			assert_integers_equal ("empty summary", 0, w.summary_count)
			assert ("no duration", w.duration_s = 0.0)
		end

feature -- Re-bucketing

	test_column_peaks_any_width
		local
			w: SW_WAVEFORM
			p: TUPLE [lows, highs: ARRAY [REAL_64]]
			i: INTEGER
		do
			create w.make (60.0)
			w.set_samples (44100, 44100, agent sine_440)
			p := w.column_peaks (10)
			assert_integers_equal ("ten columns", 10, p.lows.count)
			from i := 1 until i > 10 loop
				assert ("ten-wide ordered", p.lows [i] <= p.highs [i])
				assert ("ten-wide full", p.highs [i] > 0.9)
				i := i + 1
			end
			p := w.column_peaks (7000)
			assert_integers_equal ("more columns than summary", 7000, p.highs.count)
			p := w.column_peaks (1)
			assert_integers_equal ("one column", 1, p.highs.count)
			assert ("one column is the whole sound", p.highs [1] > 0.95 and p.lows [1] < -0.95)
		end

	test_column_peaks_without_audio_are_zero
		local
			w: SW_WAVEFORM
			p: TUPLE [lows, highs: ARRAY [REAL_64]]
		do
			create w.make (60.0)
			p := w.column_peaks (50)
			assert_integers_equal ("fifty", 50, p.lows.count)
			assert ("silent", p.highs [25] = 0.0 and p.lows [25] = 0.0)
		end

feature -- Seeking

	test_seek_math_both_ways
		local
			w: SW_WAVEFORM
			lx, rx, px: REAL_64
		do
			create w.make (60.0)
			w.set_samples (22050 * 10, 22050, agent silence)
			w.set_bounds (100.0, 20.0, 408.0, 60.0)
			lx := w.bars_x
			rx := w.bars_x + w.bars_w
			assert_reals_equal ("left edge is zero", 0.0, w.position_at (lx), 1.0e-9)
			assert_reals_equal ("right edge is the end", 10.0, w.position_at (rx), 1.0e-9)
			assert_reals_equal ("before the field clamps", 0.0, w.position_at (0.0), 1.0e-9)
			assert_reals_equal ("after the field clamps", 10.0, w.position_at (9999.0), 1.0e-9)
			px := lx + w.bars_w * 0.25
			assert_reals_equal ("quarter across", 2.5, w.position_at (px), 1.0e-9)
			assert_reals_equal ("x_of inverts position_at", px, w.x_of (w.position_at (px)), 1.0e-9)
			assert_reals_equal ("x_of clamps", rx, w.x_of (500.0), 1.0e-9)
		end

	test_click_seeks_and_reports
		local
			w: SW_WAVEFORM
		do
			create w.make (60.0)
			w.set_samples (22050 * 4, 22050, agent silence)
			w.set_bounds (0.0, 0.0, 208.0, 60.0)
			w.set_on_seek (agent record_seek)
			assert ("click taken", w.handle_click (w.bars_x + w.bars_w / 2.0, 30.0))
			assert_reals_equal ("playhead moved", 2.0, w.position_s, 1.0e-9)
			assert_reals_equal ("host told", 2.0, heard_s, 1.0e-9)
			w.handle_drag (w.bars_x, 30.0)
			assert_reals_equal ("drag rewinds", 0.0, w.position_s, 1.0e-9)
			w.set_position (99.0)
			assert_reals_equal ("set_position clamps", 4.0, w.position_s, 1.0e-9)
			assert_reals_equal ("fraction at the end", 1.0, w.fraction, 1.0e-9)
		end

	test_click_without_audio_is_refused
		local
			w: SW_WAVEFORM
		do
			create w.make (60.0)
			w.set_bounds (0.0, 0.0, 208.0, 60.0)
			w.set_on_seek (agent record_seek)
			heard_s := -1.0
			assert ("not taken", not w.handle_click (50.0, 30.0))
			assert ("host not told", heard_s = -1.0)
		end

feature -- Markers

	test_markers_within_the_audio
		local
			w: SW_WAVEFORM
		do
			create w.make (60.0)
			w.set_samples (22050 * 3, 22050, agent silence)
			w.add_marker (0.0, "start")
			w.add_marker (1.5, "sentence")
			w.add_marker (3.0, "")
			assert_integers_equal ("three", 3, w.markers.count)
			assert ("label kept", w.markers.i_th (2).label.same_string ("sentence"))
			w.clear_markers
			assert ("gone", w.markers.is_empty)
		end

feature -- Paint

	test_headless_paint
			-- A real painter over an offscreen surface: the bars, the
			-- markers and the playhead all draw without raising.
		local
			w: SW_WAVEFORM
		do
			create w.make (60.0)
			w.set_samples (44100, 44100, agent sine_440)
			w.add_marker (0.5, "mid")
			w.set_position (0.25)
			w.set_bounds (10.0, 10.0, 300.0, 60.0)
			w.draw (headless_painter)
			w.clear_samples
			w.draw (headless_painter)
			assert ("painted twice", True)
		end

feature {NONE} -- Samplers

	silence (a_frame: INTEGER): REAL_64
		do
			Result := 0.0
		end

	sine_440 (a_frame: INTEGER): REAL_64
			-- A 440 Hz sine at 44.1 kHz, full scale.
		local
			m: DOUBLE_MATH
		do
			create m
			Result := m.sine (2.0 * m.Pi * 440.0 * a_frame / 44100.0)
		end

	loud (a_frame: INTEGER): REAL_64
			-- A buffer scaled wrong: alternating +3 and -3.
		do
			if a_frame \\ 2 = 0 then
				Result := 3.0
			else
				Result := -3.0
			end
		end

feature {NONE} -- Capture

	heard_s: REAL_64

	record_seek (a_s: REAL_64)
		do
			heard_s := a_s
		end

feature {NONE} -- Fixture

	headless_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (400, 100)
			create ctx.make (surf)
			create th.make_light
			create Result.make (ctx, th)
		end

end
