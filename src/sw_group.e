note
	description: "[
		A titled border around content: the classic group box, drawn -
		hairline frame, the title carved into its top edge, content
		a padded column.
	]"

class
	SW_GROUP

inherit
	SW_COLUMN
		redefine
			draw, arrange, preferred_height, default_padding, shows_style,
			accessible_role, default_accessible_name
		end

create
	make_titled

feature {NONE} -- Initialization

	make_titled (a_title: READABLE_STRING_GENERAL)
		do
			make
			create title.make_from_string_general (a_title)
		ensure
			titled: title.same_string_general (a_title)
		end

feature -- Access

	title: STRING_32

	Top_inset: REAL_64 = 12.0

feature -- Element change

	set_title (a_title: READABLE_STRING_GENERAL)
		do
			create title.make_from_string_general (a_title)
		ensure
			set: title.same_string_general (a_title)
		end


feature -- Spacing (theme defaults; an explicit value still wins)

	default_padding (a_p: SW_PAINTER): REAL_64
			-- A titled group is a framed surface: it owns a border, the same
			-- one the window gives its root (12 px at 1x, was a fixed 14).
		do
			Result := a_p.theme.border_width
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Precursor (a_p, a_width) + Top_inset
		end

	arrange (a_p: SW_PAINTER)
		local
			keep_y, keep_h: REAL_64
		do
			keep_y := y
			keep_h := height
			y := keep_y + Top_inset
			height := (keep_h - Top_inset).max (0.0)
			Precursor (a_p)
			y := keep_y
			height := keep_h
		end

feature -- Drawing

	shows_style (a_part: INTEGER): BOOLEAN
			-- The frame, on the box under the title, and the title's color and font.
		do
			Result := Precursor (a_part) or is_text_style_part (a_part)
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tw, keep_y, keep_h: REAL_64
		do
			t := a_p.theme
			if attached style then
					-- the style's frame goes on the box under the title, where `arrange' insets
				keep_y := y
				keep_h := height
				y := keep_y + Top_inset
				height := (keep_h - Top_inset).max (0.0)
				draw_style_frame (a_p)
				y := keep_y
				height := keep_h
			end
			if not attached shown_style ({SW_WIDGET_STYLE}.Part_border) then
					-- its own outline, unless the style draws the border
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 0.5, y + Top_inset + 0.5, width - 1.0, height - Top_inset - 1.0,
					(if attached shown_style ({SW_WIDGET_STYLE}.Part_radius) as al_style then al_style.radius else t.radius end))
			end
			use_font (a_p, {SW_PAINTER}.Role_ui, t.size_chip + 1.0, True)
			tw := a_p.advance (title) + 16.0
			a_p.set_color (styled_ground (t.background))
			a_p.fill_rect (x + 14.0, y + Top_inset - 7.0, tw, 15.0)
			a_p.set_color (styled_ink (t.ink_muted))
			a_p.text (x + 22.0, y + Top_inset + 5.0, title)
			across
				children as c
			loop
				c.paint (a_p)
			end
		end


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_group
		end

	default_accessible_name: STRING_32
		do
			Result := title.twin
		end

invariant
	title_attached: title /= Void

end
