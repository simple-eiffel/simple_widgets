note
	description: "[
		The menu on the shaped path (0.7.2), proven on pixels.

		THE DEFECT THIS BATTERY EXISTS FOR. SW_MENU painted its item
		labels with SW_PAINTER.text - cairo's toy `show_text' - while
		SW_CHAT_THREAD painted with `draw_shaped_layout' whenever the
		painter carried a kit. Only the shaping kit resolves the Noto
		colour-emoji artwork and shapes complex script, so a menu item
		labelled with an emoji drew as an EMPTY BOX in every consumer
		with shaped text on, two inches from a chat bubble drawing the
		same character as a picture. simple_chat's eight-emoji reaction
		picker found it: eight identical squares.

		HOW IT IS MEASURED. Saturation, not a pixel diff. Every colour
		in the toolkit's dark theme is a near-neutral grey - the widest
		channel spread in the whole palette is about 0x0F - while Noto's
		thumbs-up is a saturated yellow. So "how many pixels in the menu
		have a channel spread over `Saturated'" separates ARTWORK from
		CHROME without pinning a single pixel, and it cannot be passed
		by a .notdef box drawn in ink.

		AND THE UNDERLINE. A mnemonic underline used to be placed at
		`advance (label.substring (1, ul - 1))' - the width of the text
		BEFORE the letter. That is a claim that source order and paint
		order are the same, and in a Hebrew title they are opposite: the
		first character paints RIGHTMOST. The Hebrew test below is the
		one that separates a cluster-position underline from a prefix
		advance, because the two answers land at opposite ends of the
		same word.
	]"
	author: "Larry Rix"

class
	SW_MENU_SHAPING_ASSAULT

inherit
	TEST_SET_BASE

feature -- The emoji menu item (the simple_chat defect)

	test_an_emoji_menu_item_paints_artwork_and_not_a_box
			-- Eight emoji items, opened through the shipped right-click
			-- door, painted into the window's own frame - and the ink
			-- counted against the SAME menu drawn on the toy path.
		local
			w: SW_WINDOW
			th: SW_THEME
			probe: SW_EMOJI_MENU_PROBE
			kit: SW_SHAPING
			assets, evidence: STRING_32
			shaped_surf, plain_surf, shot: CAIRO_SURFACE
			shaped_ctx, plain_ctx: CAIRO_CONTEXT
			shaped_p, plain_p: SW_PAINTER
			x0, y0, x1, y1: INTEGER
			shaped_colour, plain_colour, differing, frame_colour: INTEGER
			wrote: BOOLEAN
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)

			create th.make_dark
			th.set_text_scale (2.0)
			create w.make ("emoji-menu", 0, 0, Frame_w, Frame_h, th)
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			w.set_shaping (kit)
			create probe.make
			probe.set_grow (1.0)
			across
				picker_emoji as e
			loop
				probe.add_label (text_of (<<e>>))
			end
			assert_integers_equal ("the picker offers eight", 8, probe.labels.count)
			w.set_root (probe)
			w.request_render

				-- ---- the shipped door, not a hand-built menu ----
			assert_true ("the probe was laid out", probe.width > 40.0 and probe.height > 40.0)
			w.simulate_context_click ((probe.x + 20.0).rounded, (probe.y + 20.0).rounded)
			assert_true ("THE EMOJI MENU IS PRESENTED, not merely built", w.open_popup /= Void)
			if attached w.open_popup as m then
				assert_integers_equal ("with one item per emoji", 8, m.items.count)
				assert_true ("and it was placed on the frame", m.width > 0.0 and m.height > 0.0)

					-- The menu the window measured, re-drawn twice at the
					-- same geometry: once through a painter carrying the
					-- kit, once through one that carries none. The second
					-- is precisely what shipped before 0.7.2.
				create shaped_surf.make (Frame_w, Frame_h)
				create shaped_ctx.make (shaped_surf)
				ground (shaped_ctx)
				create shaped_p.make (shaped_ctx, th)
				shaped_p.set_shaping (kit)
				assert_true ("the shaped painter reports a kit", shaped_p.has_shaping)
				m.draw (shaped_p)
				shaped_surf.flush.do_nothing

				create plain_surf.make (Frame_w, Frame_h)
				create plain_ctx.make (plain_surf)
				ground (plain_ctx)
				create plain_p.make (plain_ctx, th)
				assert_false ("the toy painter carries none", plain_p.has_shaping)
				m.draw (plain_p)
				plain_surf.flush.do_nothing

				x0 := m.x.floor
				y0 := m.y.floor
				x1 := (m.x + m.width).ceiling
				y1 := (m.y + m.height).ceiling

				shaped_colour := colour_in (shaped_surf, x0, y0, x1, y1)
				plain_colour := colour_in (plain_surf, x0, y0, x1, y1)
				differing := differing_in (shaped_surf, plain_surf, x0, y0, x1, y1)

					-- THE ASSERTION THE DEFECT FAILS. Noto's artwork is
					-- saturated; the theme, the ink and a .notdef box are
					-- not. Before 0.7.2 both numbers were the same number,
					-- because both paths were the same path.
				print ("    saturated pixels - shaped " + shaped_colour.out
					+ ", toy " + plain_colour.out + ", differing " + differing.out + "%N")
				assert_greater_than ("the SHAPED menu carries real colour artwork",
					shaped_colour, 400)
				assert_less_than ("the TOY menu carries essentially none - it drew boxes in ink",
					plain_colour, 50)
				assert_greater_than ("and the two renderings are not the same pixels",
					differing, 400)

					-- ---- the evidence, and the frame it was measured on ----
				evidence := evidence_path ("menu-emoji-2x.png")
				if not evidence.is_empty then
					wrote := w.write_frame (evidence)
					print ("    written ")
					print (evidence)
					print (" " + wrote.out + "%N")
					assert_true ("the painted frame is on disk", wrote)

						-- Read back the very PNG a human will look at, so
						-- the assertion and the evidence cannot disagree:
						-- the WINDOW's frame carries the artwork too, not
						-- just an isolated re-draw.
					create shot.make_from_png (evidence)
					if shot.is_valid then
						frame_colour := colour_in (shot, x0, y0, x1, y1)
						assert_greater_than ("the presented frame carries the artwork",
							frame_colour, 400)
						shot.destroy
					end
				end

				shaped_ctx.destroy
				shaped_surf.destroy
				plain_ctx.destroy
				plain_surf.destroy
			end
		end

feature -- The mnemonic underline, where the character actually painted

	test_a_hebrew_pad_underlines_the_glyph_it_names
			-- The pad title is RTL, so its FIRST character paints at the
			-- RIGHT end. A cluster-position underline lands there; the
			-- prefix advance the toy path uses lands at zero - the other
			-- end of the same word. Both answers are read from the same
			-- bar, one painter apart.
		local
			th: SW_THEME
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			shaped_p, plain_p: SW_PAINTER
			bar: SW_MENU_BAR
			assets: STRING_32
			shaped_ub, plain_ub, latin_ub: TUPLE [left, width: REAL_64]
			title_w, latin_w: REAL_64
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)

			create th.make_dark
			th.set_text_scale (2.0)
			create surf.make (Frame_w, 120)
			create ctx.make (surf)
			ground (ctx)
			create shaped_p.make (ctx, th)
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			shaped_p.set_shaping (kit)
			create plain_p.make (ctx, th)

			create bar.make
			bar.add_menu (hebrew_pad_title, agent empty_menu)
			bar.add_menu ("E&xit", agent empty_menu)
			bar.set_bounds (0.0, 0.0, Frame_w.to_double, 36.0)

			assert_integers_equal ("the ampersand named the first Hebrew letter",
				1, bar.pad_underline_index (1))

			title_w := bar.title_width (shaped_p, bar.labels.i_th (1))
			assert_real_greater_than ("the Hebrew title has a shaped width", title_w, 1.0)

			shaped_ub := bar.pad_underline_bounds (shaped_p, 1)
			plain_ub := bar.pad_underline_bounds (plain_p, 1)

				-- THE WHOLE POINT, IN TWO NUMBERS.
			assert_real_greater_than ("the shaped underline sits in the RIGHT half, where an RTL first character paints",
				shaped_ub.left, title_w / 2.0)
			assert_true ("while the prefix advance names the LEFT edge - the other end of the word",
				plain_ub.left < 1.0)
			assert_real_greater_than ("and it is one glyph wide, not the whole title",
				shaped_ub.width, 1.0)
			assert_true ("one glyph, not the word", shaped_ub.width < title_w)
			assert_true ("and it stays inside the title it belongs to",
				shaped_ub.left + shaped_ub.width <= title_w + 1.0)

				-- The LTR control, so the RTL answer cannot be a constant:
				-- "E&xit" underlines its SECOND character, which paints to
				-- the right of the first and left of the rest.
			latin_w := bar.title_width (shaped_p, bar.labels.i_th (2))
			latin_ub := bar.pad_underline_bounds (shaped_p, 2)
			assert_integers_equal ("the ampersand named the x", 2, bar.pad_underline_index (2))
			assert_real_greater_than ("an LTR mnemonic starts past the first letter",
				latin_ub.left, 0.5)
			assert_true ("and well before the end of the word",
				latin_ub.left + latin_ub.width < latin_w)

				-- It also has to DRAW, at both settings, without raising.
			bar.draw (shaped_p)
			bar.draw (plain_p)
			surf.flush.do_nothing
			ctx.destroy
			surf.destroy
		end

feature -- The measure the width comes from

	test_the_menu_measures_what_it_paints
			-- An emoji-only item is as wide as its picture, a shortcut
			-- column is measured in the same font it draws in, and a
			-- Hebrew item underlines from its clusters too - the item-level
			-- twins of the pad-level proofs above.
		local
			th: SW_THEME
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			shaped_p, plain_p: SW_PAINTER
			m: SW_MENU
			assets: STRING_32
			emoji_label, hebrew_label: STRING_32
			shaped_w, plain_w, lw, hw: REAL_64
			ub: TUPLE [left, width: REAL_64]
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)

			create th.make_dark
			th.set_text_scale (2.0)
			create surf.make (Frame_w, 300)
			create ctx.make (surf)
			ground (ctx)
			create shaped_p.make (ctx, th)
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			shaped_p.set_shaping (kit)
			create plain_p.make (ctx, th)

			emoji_label := text_of (picker_emoji)
			hebrew_label := hebrew_item_label
			create m.make
			m.add_item (emoji_label, "", True, Void)
			m.add_item (hebrew_label, "Ctrl+C", True, Void)
			m.add_separator
			m.add_item ("&Close", "Esc", False, Void)

			lw := m.label_width (shaped_p, emoji_label)
			assert_real_greater_than ("eight emoji measure as eight pictures", lw, 100.0)

			hw := m.hint_width (shaped_p, "Ctrl+C")
			assert_real_greater_than ("the shortcut column is measured too", hw, 1.0)

			m.measure (shaped_p)
			shaped_w := m.width
			assert_true ("the menu is wide enough for what its widest item paints",
				shaped_w >= lw + 24.0 + 2.0 * {SW_MENU}.Pad)

			m.measure (plain_p)
			plain_w := m.width
			assert_true ("and the toy measure is a different number - the two paths are not one",
				(shaped_w - plain_w).abs > 1.0)

				-- The item-level underline, from the clusters.
			assert_integers_equal ("the Hebrew item names its first letter",
				1, m.item_underline_index (2))
			ub := m.item_underline_bounds (shaped_p, 2)
			assert_real_greater_than ("which paints in the right half of an RTL label",
				ub.left, m.label_width (shaped_p, hebrew_label) / 2.0)

				-- A disabled item still measures, still underlines, and
				-- still draws - in `ink_muted', which is what it always did.
			assert_integers_equal ("the disabled item names its C", 1, m.item_underline_index (4))
			assert_real_greater_than ("and still has an underline to draw",
				m.item_underline_bounds (shaped_p, 4).width, 0.5)
			assert_false ("it is disabled", m.items.i_th (4).enabled)

			m.measure (shaped_p)
			m.place (10.0, 10.0, Frame_w.to_double, 300.0)
			m.draw (shaped_p)
			m.draw (plain_p)
			surf.flush.do_nothing
			ctx.destroy
			surf.destroy
		end

	test_an_item_with_no_mnemonic_underlines_nothing
			-- The total answer: every query holds for a label that
			-- declares no ampersand, on both paths, with no raise.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			m: SW_MENU
		do
			create th.make_light
			create surf.make (200, 100)
			create ctx.make (surf)
			create p.make (ctx, th)
			create m.make
			m.add_item ("Copy", "", True, Void)
			assert_integers_equal ("no ampersand, no mnemonic", 0, m.item_underline_index (1))
			assert_true ("and so nothing to underline",
				m.item_underline_bounds (p, 1).width = 0.0)
			ctx.destroy
			surf.destroy
		end

feature {NONE} -- Fixtures

	Frame_w: INTEGER = 640

	Frame_h: INTEGER = 420

	picker_emoji: ARRAY [INTEGER]
			-- simple_chat's eight-emoji reaction picker, as code points.
		once
			Result := <<0x1F44D, 0x2764, 0x1F602, 0x1F62E,
				0x1F622, 0x1F64F, 0x1F389, 0x1F44F>>
		ensure
			eight: Result.count = 8
		end

	hebrew_pad_title: STRING_32
			-- "&" then qof-vav-bet-final-tsadi - a pad declaring its
			-- FIRST Hebrew letter as its mnemonic. Code points, not a
			-- literal: a source literal would put this file's encoding
			-- on trial instead of the shaping.
		do
			Result := text_of (<<0x0026, 0x05E7, 0x05D5, 0x05D1, 0x05E5>>)
		ensure
			five_code_points: Result.count = 5
		end

	hebrew_item_label: STRING_32
			-- "&" then he-ayin-tav-qof - an item declaring its first
			-- Hebrew letter.
		do
			Result := text_of (<<0x0026, 0x05D4, 0x05E2, 0x05EA, 0x05E7>>)
		ensure
			five_code_points: Result.count = 5
		end

	empty_menu: SW_MENU
			-- A menu builder for a pad nothing opens in these tests.
		do
			create Result.make
			Result.add_item ("Nothing", "", True, Void)
		end

	text_of (a_codes: ARRAY [INTEGER]): STRING_32
			-- `a_codes' as one STRING_32 code point per entry.
		local
			i: INTEGER
		do
			create Result.make (a_codes.count)
			from i := a_codes.lower until i > a_codes.upper loop
				Result.append_code (a_codes [i].to_natural_32)
				i := i + 1
			end
		ensure
			one_per_code_point: Result.count = a_codes.count
		end

	ground (a_ctx: CAIRO_CONTEXT)
			-- Paint `a_ctx' opaque white, so an unpainted pixel is a
			-- known pixel rather than whatever the allocation held.
		do
			a_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
		end

feature {NONE} -- Ink

	Saturated: INTEGER = 100
			-- How far a pixel's widest channel must sit from its
			-- narrowest before it counts as ARTWORK rather than chrome.
			-- The dark theme's widest spread is 0x0F and cairo's own
			-- sub-pixel smoothing fringes a grey glyph by well under
			-- this; Noto's thumbs-up spreads over 0xC0. The gap is wide
			-- enough that the number is a choice, not a tuning.

	Byte_mask: NATURAL_32 = 0xFF
			-- One channel out of an ARGB32 word. A manifest `0xFF' is an
			-- INTEGER, which `&' on a NATURAL_32 will not take.

	pixel_at (a_surface: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
			-- ARGB32 pixel at (`a_x', `a_y'). `flush' first.
		require
			valid: a_surface.is_valid
			in_range: a_x >= 0 and a_y >= 0
				and a_x < a_surface.width and a_y < a_surface.height
		local
			mp: MANAGED_POINTER
		do
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			Result := mp.read_natural_32 (a_y * a_surface.stride + a_x * 4)
		end

	is_saturated (a_pixel: NATURAL_32): BOOLEAN
			-- Do this pixel's colour channels spread wider than a grey?
		local
			r, g, b, lo, hi: INTEGER
		do
			r := ((a_pixel |>> 16) & Byte_mask).to_integer_32
			g := ((a_pixel |>> 8) & Byte_mask).to_integer_32
			b := (a_pixel & Byte_mask).to_integer_32
			hi := r.max (g).max (b)
			lo := r.min (g).min (b)
			Result := hi - lo > Saturated
		end

	colour_in (a_surface: CAIRO_SURFACE; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Saturated pixels inside [`a_x0', `a_x1') x [`a_y0', `a_y1').
		require
			valid: a_surface.is_valid
		local
			px, py: INTEGER
		do
			from py := a_y0.max (0) until py >= a_y1.min (a_surface.height) loop
				from px := a_x0.max (0) until px >= a_x1.min (a_surface.width) loop
					if is_saturated (pixel_at (a_surface, px, py)) then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		ensure
			non_negative: Result >= 0
		end

	differing_in (a_left, a_right: CAIRO_SURFACE; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Pixels the two surfaces disagree about in the region.
		require
			valid: a_left.is_valid and a_right.is_valid
			same_size: a_left.width = a_right.width and a_left.height = a_right.height
		local
			px, py: INTEGER
		do
			from py := a_y0.max (0) until py >= a_y1.min (a_left.height) loop
				from px := a_x0.max (0) until px >= a_x1.min (a_left.width) loop
					if pixel_at (a_left, px, py) /= pixel_at (a_right, px, py) then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Locating things on disk

	shaping_assets: STRING_32
			-- The Noto png/128 tree, or empty. FIRST the AC-9 runnable
			-- folder (what a shipped app has), THEN the simple_shaping
			-- repository under $SIMPLE_EIFFEL - this library's test
			-- target deliberately does not copy 3,768 files into F_code.
		local
			env: EXECUTION_ENVIRONMENT
			exe, candidate: PATH
		do
			create Result.make_empty
			create env
			create exe.make_from_string (env.arguments.command_name)
			candidate := exe.parent.extended ("assets").extended ("noto-emoji").extended ("png").extended ("128")
			if directory_exists (candidate.name) then
				Result := candidate.name.to_string_32
			elseif attached env.item ("SIMPLE_EIFFEL") as al_root and then not al_root.is_empty then
				candidate := (create {PATH}.make_from_string (al_root)).extended ("simple_shaping")
					.extended ("assets").extended ("noto-emoji").extended ("png").extended ("128")
				if directory_exists (candidate.name) then
					Result := candidate.name.to_string_32
				end
			end
		end

	evidence_path (a_name: STRING): STRING_32
			-- `<repo>/evidence/<a_name>', where `<repo>' is the first
			-- ancestor of the working directory or of the exe's own folder
			-- that holds `simple_widgets.ecf'. Empty when the repository is
			-- not underfoot, which simply means no evidence file is written.
		require
			name_not_empty: not a_name.is_empty
		local
			env: EXECUTION_ENVIRONMENT
			starts: ARRAYED_LIST [PATH]
			base, marker, dir: PATH
			d: DIRECTORY
			i, step: INTEGER
			found: BOOLEAN
		do
			create Result.make_empty
			create env
			create starts.make (2)
			starts.extend (env.current_working_path)
			starts.extend ((create {PATH}.make_from_string (env.arguments.command_name)).parent)
			from i := 1 until i > starts.count or found loop
				base := starts [i]
				from step := 0 until step > 6 or found loop
					marker := base.extended ("simple_widgets.ecf")
					if file_exists (marker.name) then
						dir := base.extended ("evidence")
						if not directory_exists (dir.name) then
							create d.make_with_path (dir)
							d.recursive_create_dir
						end
						if directory_exists (dir.name) then
							Result := dir.extended (a_name).name.to_string_32
						end
						found := True
					else
						base := base.parent
					end
					step := step + 1
				end
				i := i + 1
			end
		end

	directory_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			d: DIRECTORY
		do
			create d.make_with_name (a_path)
			Result := d.exists
		end

	file_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			f: RAW_FILE
		do
			create f.make_with_name (a_path)
			Result := f.exists
		end

end
