note
	description: "[
		Honest nothing: a drawn glyph, a title, a wrapped message,
		and optionally one action - what a blank region says instead
		of staying blank.
	]"

class
	SW_EMPTY_STATE

inherit
	SW_WIDGET
		redefine
			handle_click
		end

create
	make

feature {NONE} -- Initialization

	make (a_title, a_message: READABLE_STRING_GENERAL)
		do
			create title.make_from_string_general (a_title)
			create message.make_from_string_general (a_message)
			create action_label.make_empty
		ensure
			titled: title.same_string_general (a_title)
		end

feature -- Access

	title: STRING_32

	message: STRING_32

	action_label: STRING_32

	on_action: detachable PROCEDURE

	has_action: BOOLEAN
		do
			Result := not action_label.is_empty
		end

	glyph_kind: INTEGER
			-- The pictogram drawn above the title (0 = the tray).
			-- Any kind from SW_PAINTER's drawn-glyph set.

	set_glyph_kind (a_glyph: INTEGER)
		require
			known: a_glyph >= 0 and a_glyph <= {SW_PAINTER}.Glyph_error
		do
			glyph_kind := a_glyph
		ensure
			set: glyph_kind = a_glyph
		end

feature -- Element change

	set_action (a_label: READABLE_STRING_GENERAL; a_action: PROCEDURE)
		do
			create action_label.make_from_string_general (a_label)
			on_action := a_action
		ensure
			armed: has_action
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 150.0
			if has_action then
				Result := Result + 30.0
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cx, ty: REAL_64
		do
			t := a_p.theme
			cx := x + width / 2.0
				-- the pictogram: the open tray by default, or the
				-- host's chosen kind (search, error, offline...)
			a_p.set_color (t.outline)
			a_p.set_line_width (2.0)
			if glyph_kind > 0 then
				a_p.glyph (glyph_kind, cx, y + 33.0, 52.0)
			else
				a_p.glyph ({SW_PAINTER}.Glyph_tray, cx, y + 33.0, 52.0)
			end
			a_p.set_line_width (1.0)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_body, True)
			a_p.set_color (t.ink)
			a_p.text (cx - a_p.advance (title) / 2.0, y + 84.0, title)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			a_p.set_color (t.ink_muted)
			a_p.text (cx - a_p.advance (message) / 2.0, y + 108.0, message)
			if has_action then
				ty := y + 138.0
				if shows_hover then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (cx - a_p.advance (action_label) / 2.0, ty, action_label)
				a_p.hline (cx - a_p.advance (action_label) / 2.0, ty + 3.0, a_p.advance (action_label))
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled and then has_action and then a_py > y + 120.0 then
				if attached on_action as a then
					a.call
				end
				Result := True
			end
		end

invariant
	texts_attached: title /= Void and message /= Void and action_label /= Void
	action_pairing: has_action implies on_action /= Void

end
