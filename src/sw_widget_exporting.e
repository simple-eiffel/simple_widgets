note
	description: "[
		A widget region to PNG and to the clipboard (GW-21): one widget
		drawn alone at a scale, light by default, no hover, a margin so
		overhanging marks stay in. Pushed up 2026-10-25 out of SW_WINDOW
		(3,000 lines) into this ancestor; the window supplies the four
		things an export needs - the screen theme, the screen painter, the
		shaping kit and the hovered widget.
	]"

deferred class
	SW_WIDGET_EXPORTING

feature -- What the window supplies

	theme: SW_THEME
			-- The screen theme.
		deferred
		end

	painter: SW_PAINTER
			-- The screen painter, to lay the widget out again afterwards.
		deferred
		end

	shaping: detachable SW_SHAPING
			-- The shaping kit an export draws its text with.
		deferred
		end

feature {NONE} -- What the window supplies

	hovered: detachable SW_WIDGET
			-- The widget under the pointer, whose hover an export silences.
		deferred
		end

feature -- Export (GW-21)

	widget_image (a_widget: SW_WIDGET; a_theme: detachable SW_THEME; a_scale: REAL_64): CAIRO_SURFACE
			-- `a_widget' drawn alone onto a new surface `a_scale' times its
			-- size plus `export_margin' all round, in `a_theme' (Void:
			-- `export_theme'), on that theme's background, with no hover
			-- showing. The margin keeps glyphs that overhang the widget's box
			-- (a Greek breathing before a capital) in the picture. The caller
			-- owns the image and destroys it (cairo objects have no dispose;
			-- scan 11 found every export leaking about 11 megabytes). The widget keeps its place
			-- and size and is laid out again in the screen theme afterwards,
			-- so hit testing stays right. A focused widget still shows its
			-- focus: clearing it would fire focus events (a text box commits
			-- on losing focus).
		require
			exportable: can_export (a_widget, a_scale)
		local
			l_theme: SW_THEME
			l_ctx: CAIRO_CONTEXT
			l_painter: SW_PAINTER
			l_hover: detachable SW_WIDGET
			l_was_silenced: BOOLEAN
			m: REAL_64
		do
			if attached a_theme as al_theme then
				l_theme := al_theme
			else
				l_theme := export_theme
			end
			m := export_margin (l_theme)
			create Result.make (((a_widget.width + 2.0 * m) * a_scale).ceiling, ((a_widget.height + 2.0 * m) * a_scale).ceiling)
			create l_ctx.make (Result)
			l_ctx.scale (a_scale, a_scale).translate (m - a_widget.x, m - a_widget.y).do_nothing
			create l_painter.make (l_ctx, l_theme)
			l_painter.set_shaping (shaping)
				-- the whole image, so fractional edges are opaque too
			l_painter.set_color (l_theme.background)
			l_ctx.paint.do_nothing
				-- hover is silenced quietly (no hover event fires) and restored
			l_hover := hovered
			if attached l_hover as al_hover then
				l_was_silenced := al_hover.is_hover_silenced
				al_hover.set_hover_signal (False)
			end
			a_widget.arrange (l_painter)
			a_widget.draw (l_painter)
			if attached l_hover as al_hover then
				al_hover.set_hover_signal (not l_was_silenced)
			end
			a_widget.arrange (painter)
			Result.flush.do_nothing
				-- the context holds a reference to the image: let it go
			l_ctx.destroy
		ensure
			sized: Result.width = ((a_widget.width + 2.0 * export_margin (if attached a_theme as al_t then al_t else export_theme end)) * a_scale).ceiling
			stays_put: a_widget.x = old a_widget.x and a_widget.y = old a_widget.y
				and a_widget.width = old a_widget.width and a_widget.height = old a_widget.height
		end

	export_widget_png (a_widget: SW_WIDGET; a_path: READABLE_STRING_GENERAL; a_scale: REAL_64): BOOLEAN
			-- Write `a_widget' as a PNG at `a_path', `a_scale' times its size,
			-- in `export_theme'. True when the file was written.
		require
			exportable: can_export (a_widget, a_scale)
			path_given: not a_path.is_empty
		local
			l_image: CAIRO_SURFACE
		do
			l_image := widget_image (a_widget, Void, a_scale)
			Result := l_image.write_png (a_path)
			l_image.destroy
		end

	copy_widget_image (a_widget: SW_WIDGET; a_scale: REAL_64)
			-- Put `a_widget' on the clipboard as an image, `a_scale' times its
			-- size, in `export_theme' (copy-as-image).
		require
			exportable: can_export (a_widget, a_scale)
		local
			l_image: CAIRO_SURFACE
			l_clipboard: SW_CLIPBOARD
		do
			l_image := widget_image (a_widget, Void, a_scale)
			create l_clipboard
			l_clipboard.set_image (l_image.data, l_image.width, l_image.height, l_image.stride)
			l_image.destroy
		end

	export_theme: SW_THEME
			-- The theme images are exported in: light, with the screen
			-- theme's sizes and faces, because exports get pasted into other
			-- people's documents - or the screen theme itself when
			-- `exports_in_screen_theme'.
		do
			if exports_in_screen_theme then
				Result := theme
			else
				create Result.make_light
				Result.adopt_metrics_from (theme)
			end
		ensure
			light_by_default: not exports_in_screen_theme implies not Result.is_dark
			screen_when_asked: exports_in_screen_theme implies Result = theme
		end

	can_export (a_widget: SW_WIDGET; a_scale: REAL_64): BOOLEAN
			-- Can `a_widget' be exported at `a_scale'? It must be laid out,
			-- the scale 1 to 4, and the image (margin included) no more than
			-- `Max_export_side' pixels a side - cairo cannot make larger.
		local
			m: REAL_64
		do
			m := export_margin (export_theme)
			Result := a_widget.width >= 1.0 and a_widget.height >= 1.0
				and a_scale >= 1.0 and a_scale <= 4.0
				and (a_widget.width + 2.0 * m) * a_scale <= Max_export_side
				and (a_widget.height + 2.0 * m) * a_scale <= Max_export_side
		end

	Max_export_side: REAL_64 = 16384.0
			-- The largest exported image side, in pixels (cairo's own limit is
			-- 32767; this keeps one image under a gigabyte).

	export_margin (a_theme: SW_THEME): REAL_64
			-- The frame of background around an exported widget: the theme's
			-- `border_width', as a framed surface has.
		do
			Result := a_theme.border_width
		ensure
			non_negative: Result >= 0.0
		end

	exports_in_screen_theme: BOOLEAN
			-- Do exports keep the screen theme instead of light?

	set_exports_in_screen_theme (a_on: BOOLEAN)
		do
			exports_in_screen_theme := a_on
		ensure
			set: exports_in_screen_theme = a_on
		end

end
