note
	description: "[
		Assault on Wave 6's buildable heart: carousel paging wraps
		both ways, gallery flow arithmetic, the transport's honest
		clock and seek math, crop normalization from any drag
		direction, the chat thread's roles and streaming append,
		and the prompt view's submit round trip - all headless.
	]"

class
	SW_MEDIA_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Fixture

	fixture_png: STRING_32
			-- A real 8x8 PNG on disk, generated once - SW_IMAGE loads
			-- through cairo, and cairo wants a real file.
		local
			surf: CAIRO_SURFACE
		once
			create Result.make_from_string_general ("sw_media_fixture.png")
			create surf.make (8, 8)
			if surf.write_png (Result) then
			end
		end

feature {NONE} -- Capture

	last_prompt: STRING_32
		attribute
			create Result.make_empty
		end

	grab_prompt (a_text: STRING_32)
		do
			create last_prompt.make_from_string (a_text)
		end

feature -- Media

	test_carousel_pages_wrap
		local
			c: SW_CAROUSEL
		do
			create c.make
			c.add_image (fixture_png)
			c.add_image (fixture_png)
			c.add_image (fixture_png)
			assert_integers_equal ("starts on the first", 1, c.current_index)
			c.next
			c.next
			assert_integers_equal ("two steps forward", 3, c.current_index)
			c.next
			assert_integers_equal ("forward wraps home", 1, c.current_index)
			c.previous
			assert_integers_equal ("backward wraps to the end", 3, c.current_index)
			c.go_to (99)
			assert_integers_equal ("go_to clamps high", 3, c.current_index)
			c.go_to (-2)
			assert_integers_equal ("go_to clamps low", 1, c.current_index)
		end

	test_gallery_flow_math
		local
			g: SW_GALLERY
			i: INTEGER
		do
			create g.make
			from
				i := 1
			until
				i > 5
			loop
				g.add_image (fixture_png)
				i := i + 1
			end
			g.set_bounds (0.0, 0.0, 400.0, 300.0)
			assert_integers_equal ("three columns at 400 wide", 3, g.columns_now)
			assert_integers_equal ("five thumbs need two rows", 2, g.rows_needed)
			assert_integers_equal ("the first cell answers", 1,
				g.cell_at (g.x + g.Gap + 2.0, g.y + g.Gap + 2.0))
			assert_integers_equal ("the fourth starts row two", 4,
				g.cell_at (g.x + g.Gap + 2.0, g.y + g.Gap + g.Thumb_h + g.Gap + 2.0))
			assert_integers_equal ("beyond the last is nobody", 0,
				g.cell_at (g.x + g.Gap + 2.0 * (g.Thumb_w + g.Gap) + 2.0,
					g.y + g.Gap + g.Thumb_h + g.Gap + 2.0))
		end

	test_transport_clock_and_seek
		local
			tr: SW_MEDIA_TRANSPORT
		do
			create tr.make (245.0)
			assert_strings_equal ("m:ss with a leading zero", "1:15", tr.format_clock (75.0))
			assert_strings_equal ("zero is honest", "0:00", tr.format_clock (0.0))
			assert_strings_equal ("hours do not wrap into lies", "75:00", tr.format_clock (4500.0))
			tr.set_bounds (0.0, 0.0, 400.0, 44.0)
			tr.set_position (tr.position_at (tr.bar_x + tr.bar_w))
			assert_reals_equal ("the bar's end is the whole song", 245.0, tr.position_s, 0.000_1)
			tr.set_position (tr.position_at (tr.bar_x - 50.0))
			assert_reals_equal ("before the bar clamps to zero", 0.0, tr.position_s, 0.000_1)
			assert ("play state flips", not tr.is_playing)
			tr.toggle_play
			assert ("now playing", tr.is_playing)
		end

	test_crop_normalizes_any_direction
		local
			cb: SW_CROP_BOX
			r: TUPLE [fx, fy, fw, fh: REAL_64]
		do
			create cb.make (fixture_png)
			cb.set_bounds (0.0, 0.0, 200.0, 100.0)
				-- drag from bottom-right to top-left: corners sort
			if cb.handle_click (150.0, 80.0) then end
			cb.handle_drag (50.0, 20.0)
			r := cb.crop_rect
			assert_reals_equal ("left sorts", 0.25, r.fx, 0.000_1)
			assert_reals_equal ("top sorts", 0.2, r.fy, 0.000_1)
			assert_reals_equal ("width normalizes", 0.5, r.fw, 0.000_1)
			assert_reals_equal ("height normalizes", 0.6, r.fh, 0.000_1)
			cb.handle_drag (-40.0, 500.0)
			r := cb.crop_rect
			assert ("wild drags clamp inside the unit box",
				r.fx >= 0.0 and r.fy >= 0.0 and r.fx + r.fw <= 1.000_1 and r.fy + r.fh <= 1.000_1)
			cb.clear_selection
			r := cb.crop_rect
			assert_reals_equal ("cleared is zero-extent", 0.0, r.fw, 0.000_1)
		end

feature -- Conversational

	test_chat_thread_roles_and_streaming
		local
			th: SW_CHAT_THREAD
		do
			create th.make
			th.add_message (th.Role_mine, "hello")
			th.add_message (th.Role_theirs, "")
			th.append_to_last ("wor")
			th.append_to_last ("ld")
			assert_integers_equal ("two bubbles", 2, th.count)
			assert_integers_equal ("the first is mine", th.Role_mine, th.messages.first.role)
			assert_strings_equal ("streaming grew one bubble in place", "world", th.last_text)
			assert ("the thread follows its tail by default", th.is_sticky)
		end

	test_prompt_view_round_trip
		local
			pv: SW_PROMPT_VIEW
		do
			create pv.make
			pv.set_on_submit (agent grab_prompt)
			pv.prompt_box.set_text ("why is the sky")
			pv.submit_now
			assert_strings_equal ("the host received the prompt", "why is the sky", last_prompt)
			assert_integers_equal ("and the thread shows it as mine", 1, pv.thread.count)
			assert ("the box cleared", pv.prompt_box.text.is_empty)
			pv.begin_reply
			pv.append_token ("Rayleigh")
			pv.append_token (" scattering")
			pv.end_reply
			assert_integers_equal ("the reply is one bubble", 2, pv.thread.count)
			assert_strings_equal ("streamed whole", "Rayleigh scattering", pv.thread.last_text)
			assert ("reply closed", not pv.is_replying)
			pv.submit_now
			assert_integers_equal ("an empty box submits nothing", 2, pv.thread.count)
		end

feature -- Dictation

	test_dictation_honest_absence
		local
			d: SW_DICTATION
		do
			create d.make ("no_such_model_anywhere.bin")
			assert ("a missing model leaves the service unready", not d.is_ready)
			assert ("and quiet", not d.is_listening)
			assert ("and empty-handed", d.last_transcript.is_empty)
		end

	test_dictation_transcribes_a_real_wav
			-- The crown's proof: whisper through the ecosystem, on a
			-- real sample. Skipped honestly (still passing) when the
			-- model is not on this machine.
		local
			d: SW_DICTATION
			words: STRING_32
		do
			create d.make ("D:\prod\simple_speech\models\ggml-base.en.bin")
			if d.is_ready then
				words := d.transcribe_wav ("D:\prod\simple_speech\sherpa-onnx\test_audio_short.wav")
				assert ("real speech became real words", not words.is_empty)
			else
				assert ("model absent on this machine - honest skip", not d.is_ready)
			end
		end

end
