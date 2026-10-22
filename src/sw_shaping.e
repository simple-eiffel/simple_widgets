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
		do
			Result := facade.layout (a_text.to_string_32, a_width_pixels, a_pixel_size,
				styled_fonts (a_role, a_bold))
		ensure
			parameters_kept: Result.width_pixels = a_width_pixels
				and Result.pixel_size = a_pixel_size
		end

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
				Result := Result.with_style (if a_bold then {SHAPING_FONT}.Weight_bold else {SHAPING_FONT}.Weight_regular end, False)
				role_fonts [l_index] := Result
			end
		ensure
			styled: Result.weight = (if a_bold then {SHAPING_FONT}.Weight_bold else {SHAPING_FONT}.Weight_regular end)
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
		ensure
			set: fonts = a_fonts
		end

feature {NONE} -- Per-role policies (GW-04)

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
	fonts_usable: attached fonts as al_fonts implies not al_fonts.is_empty

end
