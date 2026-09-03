note
	description: "[
		Drawer furniture: a titled column with a drawn close X, made
		to ride the window's drawer presentation
		(window.show_drawer). The X fires on_close - the host wires
		it to window.close_sheet.
	]"

class
	SW_DRAWER

inherit
	SW_COLUMN
		redefine
			draw, arrange, preferred_height, widget_at, handle_click,
			default_gap
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


feature -- Spacing (theme defaults; an explicit value still wins)

	default_gap (a_p: SW_PAINTER): REAL_64
			-- 10 px at 1x, as before, now scaled with the text.
		do
			Result := a_p.theme.padding * 1.25
		end

feature -- Access

	title: STRING_32

	on_close: detachable PROCEDURE

	Header_h: REAL_64 = 38.0

feature -- Element change

	set_on_close (a_action: PROCEDURE)
		do
			on_close := a_action
		ensure
			set: on_close = a_action
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Precursor (a_p, a_width) + Header_h
		end

	arrange (a_p: SW_PAINTER)
		local
			keep_y, keep_h: REAL_64
		do
			keep_y := y
			keep_h := height
			y := keep_y + Header_h
			height := (keep_h - Header_h).max (0.0)
			Precursor (a_p)
			y := keep_y
			height := keep_h
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			xx, xy: REAL_64
		do
			t := a_p.theme
			a_p.font ({SW_PAINTER}.Role_ui, t.size_body, True)
			a_p.set_color (t.ink)
			a_p.text (x, y + 22.0, title)
				-- the close X, top right
			xx := x + width - 14.0
			xy := y + 14.0
			if shows_hover and then hover_px >= xx - 10.0 and then hover_py <= y + Header_h then
				a_p.set_color (t.danger)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.line (xx - 6.0, xy - 6.0, xx + 6.0, xy + 6.0, 1.8)
			a_p.line (xx - 6.0, xy + 6.0, xx + 6.0, xy - 6.0, 1.8)
			a_p.set_color (t.outline)
			a_p.hline (x, y + Header_h - 6.0, width)
			across
				children as c
			loop
				c.draw (a_p)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if a_py < y + Header_h then
					Result := Current
				else
					Result := Precursor (a_px, a_py)
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled and then a_py < y + Header_h then
				if a_px >= x + width - 26.0 and then attached on_close as a then
					a.call
				end
				Result := True
			end
		end

invariant
	title_attached: title /= Void

end
