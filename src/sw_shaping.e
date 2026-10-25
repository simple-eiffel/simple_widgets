note
	description: "[
		The toolkit's text-shaping kit: ONE simple_shaping facade and ONE
		cairo paint bridge, owned together so the layout cache and the
		decoded emoji surfaces outlive any single SW_PAINTER.

		WHY A HOLDER AND NOT A PAINTER ATTRIBUTE. simple_shaping is
		confined: one SIMPLE_SHAPING per SCOOP processor, with its font
		registry, its native handles and its layout cache. SW_WINDOW,
		however, REBUILDS its SW_PAINTER whenever the theme is swapped or
		the offscreen surface outgrows its allocation - so a facade living
		on the painter would be thrown away mid-session, taking the cache
		(and every decoded 128x128 emoji surface) with it. The window owns
		one SW_SHAPING for its whole life and hands it to each painter it
		builds; the painter owns the USE, this class owns the IDENTITY.

		ASSETS (AC-9). `make' asks the library itself where the runnable
		folder's emoji live - `assets\noto-emoji\png\128' beside the
		RUNNING EXECUTABLE - rather than restating that rule here, so the
		toolkit can never drift from simple_shaping's own answer.
		`make_with_assets' is for tests and for a host that stages the
		artwork somewhere else.

		FONTS. simple_shaping's default policy is deliberately ignorant of
		any theme: its general list is the Win10/11 anchors and its Hebrew
		and Greek buckets are scholar-grade faces. A theme face is
		LATIN-ONLY by design (Archivo has no Hebrew and no polytonic
		Greek), so `set_theme_faces' prepends it for the LATIN class only
		and leaves every other script to the library. That is the whole
		Q1 contract: the theme face is theme-owned, not library-known.

		NOTHING HERE RAISES. `SIMPLE_SHAPING.layout' is a total function
		and `SHAPING_CAIRO_BRIDGE.draw_layout' degrades to a counter; this
		class adds no failure mode of its own.
	]"
	author: "Larry Rix"
	contract_cost: "[
		NOTE TO WHOEVER EDITS THIS NEXT (2026-10-25, simple_widgets 0.28.0 to
		0.28.2). `layout_styled' is on every widget's draw path, every frame.

		THE MEMO. It keeps two generations of layouts so a string drawn again
		is one hash lookup. It must never serve a layout made under other
		fonts: the font setters here call `forget_layouts', and any change on
		`facade' moves `facade.policy_revision', which `layout_styled' checks
		first. A new way to change fonts must do one or the other. Labels
		and menus (SW_SHAPED_TEXT) come through here too, so they get the
		same faces and the same forgetting.

		CONTRACTS HERE stay O(1) or O(text): this runs per string per frame.
		simple_shaping's `contract_cost' note says why (27 s for a paragraph
		under assertions, from model clauses). Frame-budget tests time their
		steps inside simple_testing's `without_contracts'
		(SW_VIRTUAL_GRID_ASSAULT); Larry: "Timing needs trump contracts",
		and keep the critical contracts that get you under the budget.
		Measured 2026-10-25 with every contract on: a wheel frame of the
		100,000-row grid 14.8 ms (budget 16.7), a page jump 42.6 ms (every
		row shaped fresh) - the next contract trim belongs on that path.
	]"

class
	SW_SHAPING

create
	make, make_with_assets

feature {NONE} -- Initialization

	make
			-- Shaping over the AC-9 runnable folder: the emoji artwork at
			-- `assets\noto-emoji\png\128' beside the running executable.
			--
			-- The two-step is deliberate: `default_asset_directory' is a
			-- QUERY ON THE FACADE, so a facade has to exist before the
			-- toolkit can ask where the assets belong. Restating the rule
			-- here instead would be a second copy of it, free to drift.
		local
			l_facade: SIMPLE_SHAPING
		do
			create l_facade.make ({STRING_32} "assets")
			facade := l_facade.set_asset_directory (l_facade.default_asset_directory)
			create bridge.make
		ensure
			assets_are_the_runnable_folder: not facade.asset_directory.is_empty
			nothing_painted: bridge.painted_runs = 0 and bridge.skipped_runs = 0
		end

	make_with_assets (a_directory: READABLE_STRING_32)
			-- Shaping with the emoji artwork at `a_directory' - a staged
			-- runnable folder, or (in this library's own tests) the
			-- simple_shaping repository's own `assets' tree.
		require
			directory_not_empty: not a_directory.is_empty
		do
			create facade.make (a_directory)
			create bridge.make
		ensure
			assets_set: facade.asset_directory.same_string_general (a_directory)
			nothing_painted: bridge.painted_runs = 0 and bridge.skipped_runs = 0
		end

feature -- Access

	facade: SIMPLE_SHAPING
			-- Text in, cached SHAPED_LAYOUTs out. Bidi, itemization,
			-- shaping and font fallback live behind it.

	bridge: SHAPING_CAIRO_BRIDGE
			-- The paint half, holding the decoded emoji surfaces. Shared
			-- by every painter this kit is handed to, which is the point.

	fonts: detachable FONT_LIST
			-- The policy `layout_for' uses; Void means the facade's own
			-- defaults (no theme face prepended yet).

feature -- Measurement and layout

	layout_for (a_text: READABLE_STRING_GENERAL; a_width_pixels, a_pixel_size: INTEGER): SHAPED_LAYOUT
			-- `a_text' laid out to `a_width_pixels' (0 = one unbounded
			-- line) at `a_pixel_size', under this kit's policy. Cached by
			-- value: an unchanged bubble repaints without shaping again.
		require
			width_non_negative: a_width_pixels >= 0
			size_positive: a_pixel_size > 0
		do
			if attached fonts as al_fonts then
				Result := facade.layout (a_text.to_string_32, a_width_pixels, a_pixel_size, al_fonts)
			else
				Result := facade.layout_default (a_text.to_string_32, a_width_pixels, a_pixel_size)
			end
		ensure
			parameters_kept: Result.width_pixels = a_width_pixels
				and Result.pixel_size = a_pixel_size
		end

	layout_with_styles (a_text: READABLE_STRING_GENERAL; a_width_pixels, a_pixel_size: INTEGER;
			a_styles: SHAPING_STYLES): SHAPED_LAYOUT
			-- `layout_for', with stretches set smaller, raised or in small
			-- capitals as `a_styles' says (GW-08: Strong's numbers, LORD).
			-- No spans: the very layout `layout_for' gives.
		require
			width_non_negative: a_width_pixels >= 0
			size_positive: a_pixel_size > 0
		do
			if attached fonts as al_fonts then
				Result := facade.layout_styled (a_text.to_string_32, a_width_pixels, a_pixel_size,
					al_fonts, a_styles)
			else
				Result := facade.layout_styled (a_text.to_string_32, a_width_pixels, a_pixel_size,
					facade.default_fonts, a_styles)
			end
		ensure
			parameters_kept: Result.width_pixels = a_width_pixels
				and Result.pixel_size = a_pixel_size
		end

	layout_styled (a_text: READABLE_STRING_GENERAL; a_width_pixels, a_pixel_size, a_role: INTEGER;
			a_bold: BOOLEAN): SHAPED_LAYOUT
			-- `a_text' laid out like `layout_for', but in the theme face of
			-- `a_role' (SW_PAINTER.Role_ui, Role_body, Role_mono) at regular
			-- or bold weight - the policy SW_PAINTER.text and `advance' use
			-- (GW-04). Hebrew, Greek and every other script still fall
			-- through to simple_shaping's own scholar lists.
		require
			width_non_negative: a_width_pixels >= 0
			size_positive: a_pixel_size > 0
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
			--
			-- GW-29: remembered. Every widget's `SW_PAINTER.text' comes here
			-- every frame, so a string drawn again is one hash lookup - not a
			-- trip through the facade's cache key and contracts. Two
			-- generations of `Memo_generation' layouts each: when the newer
			-- fills it becomes the older and the oldest goes, so scrolling a
			-- long list never empties the memo at once.
			--
			-- A change made on `facade' directly (a font file loaded, the
			-- default fonts or asset directory set, its cache cleared) moves
			-- its `policy_revision', and the memo forgets on the next call.
		local
			l_key: STRING_32
		do
			if facade.policy_revision /= memo_revision then
				forget_layouts
			end
			l_key := memo_key (a_text, a_width_pixels, a_pixel_size, a_role, a_bold)
			if attached memo.item (l_key) as al_layout then
				Result := al_layout
			elseif attached older_memo.item (l_key) as al_older then
				Result := al_older
				remember (l_key, al_older)
			else
				if a_pixel_size < small_size_below and then not small_script_faces.is_empty then
					Result := facade.layout (a_text.to_string_32, a_width_pixels, a_pixel_size,
						small_styled_fonts (a_role, a_bold))
				else
					Result := facade.layout (a_text.to_string_32, a_width_pixels, a_pixel_size,
						styled_fonts (a_role, a_bold))
				end
				remember (l_key, Result)
			end
		ensure
			parameters_kept: Result.width_pixels = a_width_pixels
				and Result.pixel_size = a_pixel_size
			remembered: memo.has (memo_key (a_text, a_width_pixels, a_pixel_size, a_role, a_bold))
		end

	memo_count: INTEGER
			-- Layouts `layout_styled' remembers now.
		do
			Result := memo.count + older_memo.count
		end

	Memo_generation: INTEGER = 1024
			-- Layouts in one generation of the memo: a screenful of grid
			-- cells many times over.

	forget_layouts
			-- Drop what `layout_styled' remembers. The font setters here and
			-- any policy change on `facade' (its `policy_revision') do it
			-- without being asked.
		do
			memo.wipe_out
			older_memo.wipe_out
			memo_revision := facade.policy_revision
		ensure
			forgotten: memo_count = 0
			in_step: memo_revision = facade.policy_revision
		end

	memo_revision: INTEGER
			-- The facade's `policy_revision' the memo's layouts were made under.

	styled_fonts (a_role: INTEGER; a_bold: BOOLEAN): FONT_LIST
			-- The policy for `a_role' at regular or bold weight: the role's
			-- theme face leading the general list (once `set_theme_faces'
			-- has run), so it carries Latin, digits and punctuation, and
			-- simple_shaping's Hebrew and Greek lists for those scripts.
		require
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
		local
			l_index: INTEGER
		do
			l_index := (a_role - 1) * 2 + (if a_bold then 2 else 1 end)
			if attached role_fonts [l_index] as al_fonts then
				Result := al_fonts
			else
				create Result.make_default
				if attached role_family (a_role) as al_family then
						-- Leading, not a Latin prepend: the role's face must
						-- also carry digits and punctuation (a mono label's
						-- "4171" otherwise came from Segoe UI).
					Result := Result.with_leading_family (al_family)
				end
					-- GW-03: the app's own faces for Hebrew, Greek, ...
				across script_faces as f loop
					Result := Result.with_family_for_script (@ f.key, f)
				end
				Result := Result.with_style (if a_bold then {SHAPING_FONT}.Weight_bold else {SHAPING_FONT}.Weight_regular end, False)
				role_fonts [l_index] := Result
			end
		ensure
			styled: Result.weight = (if a_bold then {SHAPING_FONT}.Weight_bold else {SHAPING_FONT}.Weight_regular end)
			usable: not Result.is_empty
		end

	fonts_for_role (a_role, a_pixel_size: INTEGER; a_bold: BOOLEAN): FONT_LIST
			-- The policy `layout_styled' uses for `a_role' at `a_pixel_size'
			-- (the small script faces below `small_size_below'), for a host
			-- that lays text out through SW_TEXT_GEOMETRY.set_fonts (GW-13:
			-- a document's body in the reading face, its headings in the UI
			-- face). Shared and cached: never restyle it.
		require
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
			size_positive: a_pixel_size > 0
		do
			if a_pixel_size < small_size_below and then not small_script_faces.is_empty then
				Result := small_styled_fonts (a_role, a_bold)
			else
				Result := styled_fonts (a_role, a_bold)
			end
		ensure
			usable: not Result.is_empty
		end

	line_height (a_pixel_size: INTEGER): REAL_64
			-- One line of this kit's primary face at `a_pixel_size': the
			-- facade's `line_height' under this kit's policy. It is the row
			-- a line of plain body text occupies, and what an EMPTY line must
			-- be given: the facade lays an empty line out at the bare pixel
			-- size and leaves the primary-face floor to its consumers (R10,
			-- FR-N01), so a host that stacks lines takes it from here.
		require
			size_positive: a_pixel_size > 0
		do
			if attached fonts as al_fonts then
				Result := facade.line_height (a_pixel_size, al_fonts)
			else
				Result := facade.line_height (a_pixel_size, facade.default_fonts)
			end
		ensure
			positive: Result > 0.0
		end

feature -- Element change

	set_theme_faces (a_theme: SW_THEME)
			-- Prefer `a_theme''s UI face for LATIN text, and leave Hebrew,
			-- Greek and every other script to simple_shaping's own policy
			-- (Q1: a theme face is Latin-only; asking it to carry niqqud
			-- is how tofu gets on the screen).
		local
			l_fonts: FONT_LIST
		do
			create l_fonts.make_default
			fonts := l_fonts
				.with_family_for_script ({SHAPING_CONSTANTS}.Script_class_latin, a_theme.family_ui)
				-- GW-04: the per-role policies follow the theme too.
			create ui_family.make_from_string_general (a_theme.family_ui)
			create body_family.make_from_string_general (a_theme.family_body)
			create mono_family.make_from_string_general (a_theme.family_mono)
			role_fonts.fill_with (Void)
			small_role_fonts.fill_with (Void)
			forget_layouts
		ensure
			policy_present: attached fonts
			role_faces_follow: attached ui_family as al_ui and then al_ui.same_string_general (a_theme.family_ui)
		end

	set_fonts (a_fonts: detachable FONT_LIST)
			-- Use `a_fonts' (Void restores the facade's own defaults).
		require
			usable_when_given: attached a_fonts as al implies not al.is_empty
		do
			fonts := a_fonts
			forget_layouts
		ensure
			set: fonts = a_fonts
		end

feature -- Script faces (GW-03)

	set_script_face (a_script_class: INTEGER; a_family: READABLE_STRING_GENERAL)
			-- Shape `a_script_class' (SHAPING_CONSTANTS Script_class_hebrew,
			-- Script_class_greek, ...) in `a_family' first, in every role:
			-- how an app puts its own reading faces in front of
			-- simple_shaping's defaults. Ship the face with
			-- `SIMPLE_SHAPING.load_font_file' if readers may not have it.
		require
			class_valid: facade.default_fonts.is_valid_script_class (a_script_class)
			family_not_empty: not a_family.is_empty
		do
			script_faces.force (create {STRING_32}.make_from_string_general (a_family), a_script_class)
			role_fonts.fill_with (Void)
			small_role_fonts.fill_with (Void)
			forget_layouts
		ensure
			recorded: attached script_face (a_script_class) as al_face
				and then al_face.same_string_general (a_family)
		end

	script_face (a_script_class: INTEGER): detachable STRING_32
			-- The face `set_script_face' put first for `a_script_class'.
		do
			Result := script_faces.item (a_script_class)
		end

	set_small_script_face (a_script_class: INTEGER; a_family: READABLE_STRING_GENERAL; a_below_px: INTEGER)
			-- Below `a_below_px' pixels, shape `a_script_class' in `a_family'
			-- instead. GW-03 measured why: at 14 px a regular face's vowel
			-- points and cantillation antialias to grey (light theme: 24% of
			-- the mark ink at 3:1); the same family's true Medium design
			-- keeps them crisp. A static Medium file is its own GDI family
			-- ("Noto Serif Hebrew Medium"), so asking weight 500 of the
			-- regular family does NOT reach it - name the face here.
		require
			class_valid: facade.default_fonts.is_valid_script_class (a_script_class)
			family_not_empty: not a_family.is_empty
			threshold_positive: a_below_px > 0
		do
			small_script_faces.force (create {STRING_32}.make_from_string_general (a_family), a_script_class)
			small_size_below := a_below_px
			small_role_fonts.fill_with (Void)
			forget_layouts
		ensure
			recorded: attached small_script_faces.item (a_script_class) as al_face
				and then al_face.same_string_general (a_family)
			threshold_set: small_size_below = a_below_px
		end

	small_size_below: INTEGER
			-- Pixel size below which the small script faces apply (0: never).

feature {NONE} -- The layout memo (GW-29)

	memo: HASH_TABLE [SHAPED_LAYOUT, STRING_32]
			-- The newer generation.
		attribute
			create Result.make (Memo_generation)
		end

	older_memo: HASH_TABLE [SHAPED_LAYOUT, STRING_32]
			-- The older generation; a hit here moves into `memo'.
		attribute
			create Result.make (0)
		end

	remember (a_key: STRING_32; a_layout: SHAPED_LAYOUT)
			-- `a_layout' under `a_key' in the newer generation, starting a
			-- new one first when it is full.
		do
			if memo.count >= Memo_generation then
				older_memo := memo
				create memo.make (Memo_generation)
			end
			memo.force (a_layout, a_key)
		ensure
			kept: memo.has (a_key)
		end

	memo_key (a_text: READABLE_STRING_GENERAL; a_width_pixels, a_pixel_size, a_role: INTEGER;
			a_bold: BOOLEAN): STRING_32
			-- Size, width, role and weight first, then a separator no number
			-- makes, then the text: no text can forge another call's key.
		do
			create Result.make (a_text.count + 16)
			Result.append_integer (a_pixel_size)
			Result.append_character (',')
			Result.append_integer (a_width_pixels)
			Result.append_character (',')
			Result.append_integer (a_role)
			Result.append_character (if a_bold then 'b' else 'r' end)
			Result.append_character ('|')
			Result.append_string_general (a_text)
		end

feature {NONE} -- Per-role policies (GW-04)

	script_faces: HASH_TABLE [STRING_32, INTEGER]
			-- Script class -> the app's face for it (GW-03).
		once ("OBJECT")
			create Result.make (4)
		end

	small_script_faces: HASH_TABLE [STRING_32, INTEGER]
			-- Script class -> the face used below `small_size_below' (GW-03).
		once ("OBJECT")
			create Result.make (4)
		end

	small_role_fonts: ARRAY [detachable FONT_LIST]
			-- Cached small-size policies, indexed as `role_fonts'.
		once ("OBJECT")
			create Result.make_filled (Void, 1, 6)
		end

	small_styled_fonts (a_role: INTEGER; a_bold: BOOLEAN): FONT_LIST
			-- `styled_fonts' with the small script faces put in front.
		require
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
		local
			l_index: INTEGER
		do
			l_index := (a_role - 1) * 2 + (if a_bold then 2 else 1 end)
			if attached small_role_fonts [l_index] as al_fonts then
				Result := al_fonts
			else
				Result := styled_fonts (a_role, a_bold).twin
				across small_script_faces as f loop
					Result := Result.with_family_for_script (@ f.key, f)
				end
				small_role_fonts [l_index] := Result
			end
		ensure
			usable: not Result.is_empty
		end


	role_fonts: ARRAY [detachable FONT_LIST]
			-- Cached policies: index (role - 1) * 2 + 1 regular, + 2 bold.
		once ("OBJECT")
			create Result.make_filled (Void, 1, 6)
		end

	ui_family, body_family, mono_family: detachable STRING_32
			-- The theme's faces, once `set_theme_faces' has run.

	role_family (a_role: INTEGER): detachable STRING_32
			-- The theme face for `a_role', or Void before `set_theme_faces'.
		do
			inspect a_role
			when 2 then Result := body_family
			when 3 then Result := mono_family
			else Result := ui_family
			end
		end

feature -- Removal

	dispose_surfaces
			-- Give the decoded emoji artwork back. The one release point;
			-- a context still using a surface as its source must be done
			-- with it first.
		do
			bridge.surfaces.dispose_all
		ensure
			released: bridge.surfaces.count = 0
		end

invariant
	facade_attached: facade /= Void
	bridge_attached: bridge /= Void
	memo_bounded: memo.count <= Memo_generation and older_memo.count <= Memo_generation
	fonts_usable: attached fonts as al_fonts implies not al_fonts.is_empty

end
