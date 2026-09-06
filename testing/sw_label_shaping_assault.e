note
	description: "[
		The label on the shaped path (0.8.1), proven on the layout and
		on pixels.

		THE DEFECT THIS BATTERY EXISTS FOR. SW_LABEL painted with
		SW_PAINTER.text - cairo's toy `show_text' - while the menu bar
		beside it painted through the window's shaping kit. So a window
		with shaped text ON drew its Hebrew menu titles right-to-left
		and its Hebrew LABELS left-to-right, and an emoji in a label was
		a box two inches from the same emoji drawn as a picture in a
		menu. simple_narrate's Studio frame found it: the breadcrumb is
		a label, and an essay's title is the author's, in whatever
		script the author writes.

		HOW IT IS PROVEN. Direction is read from the layout the label
		itself builds: a Hebrew word's base direction is RTL and its
		FIRST source character paints in the RIGHT half of the width.
		Artwork is counted by saturation, as the menu battery counts it:
		the light theme is near-neutral, Noto's thumbs-up is not. And a
		mono label is proven to stay where it was - on the toy path -
		because that is a promise too.
	]"
	author: "Larry Rix"

class
	SW_LABEL_SHAPING_ASSAULT

inherit
	TEST_SET_BASE

feature -- Right-to-left

	test_a_hebrew_label_paints_its_first_letter_rightmost
			-- A ui label in Hebrew, one painter with a kit and one
			-- without. The shaped layout is RTL and its first character
			-- sits in the right half; the toy painter measures the same
			-- text differently and paints different pixels.
		local
			th: SW_THEME
			kit: SW_SHAPING
			shaped_surf, plain_surf: CAIRO_SURFACE
			shaped_ctx, plain_ctx: CAIRO_CONTEXT
			shaped_p, plain_p: SW_PAINTER
			lb: SW_LABEL
			geometry: SW_SHAPED_TEXT
			assets, evidence: STRING_32
			span: TUPLE [left, width: REAL_64]
			shaped_w, plain_w: REAL_64
			x0, y0, x1, y1, shaped_ink, plain_ink, differing: INTEGER
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)

			create th.make_light
			th.set_text_scale (2.0)
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)

			create shaped_surf.make (Frame_w, Frame_h)
			create shaped_ctx.make (shaped_surf)
			ground (shaped_ctx)
			create shaped_p.make (shaped_ctx, th)
			shaped_p.set_shaping (kit)
			create plain_surf.make (Frame_w, Frame_h)
			create plain_ctx.make (plain_surf)
			ground (plain_ctx)
			create plain_p.make (plain_ctx, th)

			create lb.make_ui (hebrew_word)
			lb.set_bounds (10.0, 10.0, 600.0, 60.0)
			assert_true ("a ui label takes the shaped path when the painter carries a kit", lb.takes_shaped_path (shaped_p))
			assert_false ("and the toy path when it carries none", lb.takes_shaped_path (plain_p))
			assert_integers_equal ("shaped at the theme size through the scale", 26, lb.pixel_size (shaped_p))

			shaped_w := lb.preferred_width (shaped_p)
			plain_w := lb.preferred_width (plain_p)
			assert_real_greater_than ("the Hebrew label has a shaped width", shaped_w, 1.0)

			assert_true ("the label builds a layout on the shaped path", attached lb.shaped_layout (shaped_p, 0.0))
			assert_true ("and none on the toy path", lb.shaped_layout (plain_p, 0.0) = Void)
			if attached lb.shaped_layout (shaped_p, 0.0) as l_layout then
				assert_integers_equal ("first-strong is Hebrew, so the paragraph is RTL",
					{SHAPING_CONSTANTS}.Direction_rtl, l_layout.base_direction)
				assert_true ("one line", l_layout.lines.count = 1)
				assert_true ("whose run is RTL", l_layout.lines.first.runs.first.is_rtl)
				assert_true ("the measure IS the layout", (shaped_w - l_layout.total_width).abs < 0.001)
				create geometry.make
				span := geometry.character_span (l_layout, 1)
					-- THE WHOLE POINT. The first source character paints
					-- at the RIGHT end of a right-to-left word.
				assert_real_greater_than ("the first Hebrew letter paints in the RIGHT half",
					span.left, shaped_w / 2.0)
				assert_real_greater_than ("and it is one glyph wide", span.width, 1.0)
				assert_true ("not the whole word", span.width < shaped_w)
			end

				-- It also has to DRAW, on both paths, and not the same pixels.
			lb.draw (shaped_p)
			shaped_surf.flush.do_nothing
			lb.draw (plain_p)
			plain_surf.flush.do_nothing
			x0 := lb.x.floor
			y0 := lb.y.floor
			x1 := (lb.x + shaped_w.max (plain_w)).ceiling + 4
			y1 := (lb.y + lb.height).ceiling
			shaped_ink := ink_in (shaped_surf, x0, y0, x1, y1)
			plain_ink := ink_in (plain_surf, x0, y0, x1, y1)
			differing := differing_in (shaped_surf, plain_surf, x0, y0, x1, y1)
			print ("    ink - shaped " + shaped_ink.out + ", toy " + plain_ink.out
				+ ", differing " + differing.out + "; width shaped " + shaped_w.out + " toy " + plain_w.out + "%N")
			assert_greater_than ("the shaped label put ink on the frame", shaped_ink, 50)
			assert_greater_than ("and the two paths are not the same pixels", differing, 50)

			evidence := evidence_path ("label-hebrew-2x.png")
			if not evidence.is_empty then
				assert_true ("the evidence frame is on disk", shaped_surf.write_png (evidence))
				print ("    written ")
				print (evidence)
				print ("%N")
			end
		end

feature -- Artwork

	test_an_emoji_label_paints_artwork_and_not_a_box
			-- One thumbs-up as a ui label: saturated on the shaped path,
			-- a box in ink on the toy path.
		local
			th: SW_THEME
			kit: SW_SHAPING
			shaped_surf, plain_surf: CAIRO_SURFACE
			shaped_ctx, plain_ctx: CAIRO_CONTEXT
			shaped_p, plain_p: SW_PAINTER
			lb: SW_LABEL
			assets: STRING_32
			x0, y0, x1, y1, shaped_colour, plain_colour: INTEGER
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)
			create th.make_light
			th.set_text_scale (2.0)
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			create shaped_surf.make (Frame_w, Frame_h)
			create shaped_ctx.make (shaped_surf)
			ground (shaped_ctx)
			create shaped_p.make (shaped_ctx, th)
			shaped_p.set_shaping (kit)
			create plain_surf.make (Frame_w, Frame_h)
			create plain_ctx.make (plain_surf)
			ground (plain_ctx)
			create plain_p.make (plain_ctx, th)

			create lb.make_ui (text_of (<<0x1F44D>>))
			lb.set_bounds (10.0, 10.0, 200.0, 60.0)
			lb.draw (shaped_p)
			shaped_surf.flush.do_nothing
			lb.draw (plain_p)
			plain_surf.flush.do_nothing
			x0 := lb.x.floor
			y0 := lb.y.floor
			x1 := (lb.x + lb.width).ceiling
			y1 := (lb.y + lb.height).ceiling
			shaped_colour := colour_in (shaped_surf, x0, y0, x1, y1)
			plain_colour := colour_in (plain_surf, x0, y0, x1, y1)
			print ("    saturated pixels - shaped " + shaped_colour.out + ", toy " + plain_colour.out + "%N")
			assert_greater_than ("the SHAPED label carries real colour artwork", shaped_colour, 100)
			assert_less_than ("the TOY label carries essentially none", plain_colour, 10)
		end

feature -- What stays on the toy path

	test_a_mono_label_keeps_the_toy_path_whatever_the_painter_carries
			-- Machine-produced values keep their monospace: a mono label
			-- measures the same with a kit as without one.
		local
			th: SW_THEME
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			shaped_p, plain_p: SW_PAINTER
			lb: SW_LABEL
			assets: STRING_32
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)
			create th.make_light
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			create surf.make (Frame_w, 80)
			create ctx.make (surf)
			ground (ctx)
			create shaped_p.make (ctx, th)
			shaped_p.set_shaping (kit)
			create plain_p.make (ctx, th)

			create lb.make_mono ("seed 4171")
			assert_false ("a mono role is not a shaped role", lb.is_shaped_role)
			assert_false ("so a mono label never takes the shaped path", lb.takes_shaped_path (shaped_p))
			assert_true ("and builds no layout", lb.shaped_layout (shaped_p, 0.0) = Void)
			assert_true ("it measures the same with a kit as without",
				(lb.preferred_width (shaped_p) - lb.preferred_width (plain_p)).abs < 0.001)
			lb.set_bounds (0.0, 0.0, 300.0, 40.0)
			lb.draw (shaped_p)
			lb.draw (plain_p)
			surf.flush.do_nothing
		end

	test_an_empty_label_shapes_nothing
			-- Nothing to shape is the toy path too - a blank label
			-- measures zero and builds no layout.
		local
			th: SW_THEME
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			shaped_p: SW_PAINTER
			lb: SW_LABEL
			assets: STRING_32
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)
			create th.make_light
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			create surf.make (Frame_w, 80)
			create ctx.make (surf)
			ground (ctx)
			create shaped_p.make (ctx, th)
			shaped_p.set_shaping (kit)

			create lb.make_ui ("")
			assert_true ("a ui role is a shaped role", lb.is_shaped_role)
			assert_false ("but an empty label takes no path at all", lb.takes_shaped_path (shaped_p))
			assert_true ("no layout", lb.shaped_layout (shaped_p, 0.0) = Void)
			assert_true ("zero wide", lb.preferred_width (shaped_p) < 0.001)
			assert_real_greater_than ("but still one step tall", lb.preferred_height (shaped_p, 100.0), 1.0)
			lb.set_bounds (0.0, 0.0, 300.0, 40.0)
			lb.draw (shaped_p)
		end

feature -- Wrapping

	test_a_wrapping_body_label_breaks_where_the_kit_breaks_it
			-- A body label wraps through the kit: narrower is taller,
			-- the layout has more than one line, and it paints.
		local
			th: SW_THEME
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			shaped_p: SW_PAINTER
			lb: SW_LABEL
			assets: STRING_32
			narrow, wide: REAL_64
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)
			create th.make_light
			create kit.make_with_assets (assets)
			kit.set_theme_faces (th)
			create surf.make (Frame_w, Frame_h)
			create ctx.make (surf)
			ground (ctx)
			create shaped_p.make (ctx, th)
			shaped_p.set_shaping (kit)

			create lb.make_body ("In one-twelve CE a Roman governor sat down to write to his emperor about a problem he did not know how to handle.")
			assert_true ("a body label wraps", lb.is_wrapping)
			assert_true ("and takes the shaped path", lb.takes_shaped_path (shaped_p))
			narrow := lb.preferred_height (shaped_p, 220.0)
			wide := lb.preferred_height (shaped_p, 3000.0)
			assert_real_greater_than ("narrower is taller", narrow, wide + 1.0)
			if attached lb.shaped_layout (shaped_p, 220.0) as l_layout then
				assert_greater_than ("the kit broke it into lines", l_layout.lines.count, 1)
			else
				assert_true ("a wrapped shaped layout exists", False)
			end
			if attached lb.shaped_layout (shaped_p, 3000.0) as l_layout then
				assert_integers_equal ("and left it whole when the width allows", 1, l_layout.lines.count)
			end
			lb.set_bounds (10.0, 10.0, 220.0, narrow)
			lb.draw (shaped_p)
			surf.flush.do_nothing
			assert_greater_than ("it painted", ink_in (surf, 10, 10, 230, (10.0 + narrow).ceiling), 200)
		end

feature {NONE} -- Fixtures

	Frame_w: INTEGER = 640

	Frame_h: INTEGER = 200

	hebrew_word: STRING_32
			-- qof-vav-bet-final-tsadi, as code points: a source literal
			-- would put this file's encoding on trial instead of the
			-- shaping.
		do
			Result := text_of (<<0x05E7, 0x05D5, 0x05D1, 0x05E5>>)
		ensure
			four_code_points: Result.count = 4
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
			-- narrowest before it counts as artwork rather than chrome.

	Byte_mask: NATURAL_32 = 0xFF

	Rgb_mask: NATURAL_32 = 0xFFFFFF

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

	ink_in (a_surface: CAIRO_SURFACE; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Pixels that are not the white ground inside the region.
		require
			valid: a_surface.is_valid
		local
			px, py: INTEGER
		do
			from py := a_y0.max (0) until py >= a_y1.min (a_surface.height) loop
				from px := a_x0.max (0) until px >= a_x1.min (a_surface.width) loop
					if (pixel_at (a_surface, px, py) & Rgb_mask) /= Rgb_mask then
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
			-- The Noto png/128 tree, or empty: the runnable folder first,
			-- then the simple_shaping repository under $SIMPLE_EIFFEL.
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
			-- ancestor of the working directory or of the exe's folder
			-- that holds `simple_widgets.ecf'; empty when the repository
			-- is not underfoot.
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
