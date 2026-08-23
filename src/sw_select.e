note
	description: "[
		A closed dropdown: shows the selected option, opens a drawn
		SW_MENU of options on click (via the pending-menu handshake -
		the widget declares, the window presents). The change agent
		fires when the selection moves.
	]"

class
	SW_SELECT

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create options.make (8)
		end

feature -- Access

	options: ARRAYED_LIST [STRING_32]

	option_enabled: ARRAYED_LIST [BOOLEAN]
			-- Parallel per-option availability (the underlying
			-- SW_MENU always supported it; now the select does).
		attribute
			create Result.make (8)
		end

	separators_after: ARRAYED_LIST [INTEGER]
			-- Option indices followed by a group separator.
		attribute
			create Result.make (2)
		end

	set_option_enabled (a_index: INTEGER; a_enabled: BOOLEAN)
		require
			known: a_index >= 1 and a_index <= options.count
		do
			option_enabled.put_i_th (a_enabled, a_index)
		ensure
			set: option_enabled.i_th (a_index) = a_enabled
		end

	add_separator_after (a_index: INTEGER)
		require
			known: a_index >= 1 and a_index <= options.count
		do
			separators_after.extend (a_index)
		end

	selected_index: INTEGER
			-- 1-based selection; 0 = nothing selected yet.

	selected_text: STRING_32
		do
			if selected_index >= 1 and selected_index <= options.count then
				Result := options.i_th (selected_index)
			else
				create Result.make_empty
			end
		end

	on_change: detachable PROCEDURE

feature -- Element change

	add_option (a_text: READABLE_STRING_GENERAL)
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			option_enabled.extend (True)
			options.extend (s)
		ensure
			grew: options.count = old options.count + 1
		end

	with_option (a_text: READABLE_STRING_GENERAL): like Current
			-- Fluent option append.
		do
			add_option (a_text)
			Result := Current
		ensure
			chained: Result = Current
		end

	select_index (a_i: INTEGER)
		require
			in_range: a_i >= 1 and a_i <= options.count
		do
			selected_index := a_i
			if attached on_change as a then
				a.call
			end
		ensure
			selected: selected_index = a_i
		end

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		local
			w: REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := 120.0
			across
				options as o
			loop
				w := a_p.advance (o) + 46.0
				if w > Result then
					Result := w
				end
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := a_p.theme.button_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cx, cy: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if is_focused then
				a_p.set_color (t.accent)
			elseif shows_hover then
				a_p.set_color (t.accent)
			else
				a_p.set_color (t.outline)
			end
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			if selected_index = 0 then
				a_p.set_color (t.ink_muted)
				a_p.text (x + 11.0, y + height - 11.0, {STRING_32} "choose%/8230/")
			else
				if is_enabled then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (x + 11.0, y + height - 11.0, selected_text)
			end
				-- chevron
			cx := x + width - 19.0
			cy := y + height / 2.0 - 2.0
			a_p.set_color (t.ink_muted)
			a_p.line (cx, cy, cx + 5.0, cy + 5.0, 1.6)
			a_p.line (cx + 5.0, cy + 5.0, cx + 10.0, cy, 1.6)
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			m: SW_MENU
			i: INTEGER
		do
			if is_enabled and then not options.is_empty then
				create m.make
				from
					i := 1
				until
					i > options.count
				loop
					m.add_item (options.i_th (i), "", option_enabled.i_th (i), agent select_index (i))
					if separators_after.has (i) then
						m.add_separator
					end
					i := i + 1
				end
				pending_menu := m
				Result := True
			end
		end

invariant
	options_attached: options /= Void
	selection_in_range: selected_index >= 0 and selected_index <= options.count

end
