note
	description: "[
		Mutually exclusive choices drawn as a row of radio dots with
		labels. One widget owns the whole group - exclusivity is a
		class invariant, not a fragile sibling protocol.
	]"

class
	SW_RADIO_GROUP

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create options.make (4)
		end

feature -- Hover

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

feature -- Access

	options: ARRAYED_LIST [STRING_32]

	is_vertical: BOOLEAN
			-- Stack options downward instead of across.

	option_enabled: ARRAYED_LIST [BOOLEAN]
		attribute
			create Result.make (4)
		end

	set_vertical (a_vertical: BOOLEAN)
		do
			is_vertical := a_vertical
		ensure
			set: is_vertical = a_vertical
		end

	set_option_enabled (a_index: INTEGER; a_enabled: BOOLEAN)
		require
			known: a_index >= 1 and a_index <= options.count
		do
			option_enabled.put_i_th (a_enabled, a_index)
		ensure
			set: option_enabled.i_th (a_index) = a_enabled
		end

	selected_index: INTEGER
			-- 1-based choice; 0 = none yet.

	on_change: detachable PROCEDURE [INTEGER]

feature -- Element change

	add_option (a_text: READABLE_STRING_GENERAL)
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			option_enabled.extend (True)
			options.extend (s)
			if selected_index = 0 then
					-- a radio group always has exactly one choice; the
					-- first option starts as it, silently.
				selected_index := 1
			end
		ensure
			grew: options.count = old options.count + 1
			something_chosen: selected_index >= 1
		end

	with_option (a_text: READABLE_STRING_GENERAL): like Current
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
				a.call (a_i)
			end
		ensure
			selected: selected_index = a_i
		end

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	Dot_s: REAL_64 = 18.0
	Gap_between: REAL_64 = 22.0

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			if is_vertical then
				across
					options as o
				loop
					Result := Result.max (Dot_s + 7.0 + a_p.advance (o))
				end
			else
				across
					options as o
				loop
					Result := Result + Dot_s + 7.0 + a_p.advance (o) + Gap_between
				end
				Result := (Result - Gap_between).max (0.0)
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 28.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cx, cy: REAL_64
			i: INTEGER
		do
			probe_painter := a_p
			t := a_p.theme
			cx := x
			cy := y + height / 2.0
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			if is_vertical then
				cy := y + 13.0
			end
			from
				i := 1
			until
				i > options.count
			loop
				if i = selected_index and is_enabled and option_enabled.i_th (i) then
					a_p.set_color (t.accent)
					a_p.set_line_width (2.0)
				elseif not option_enabled.i_th (i) then
					a_p.set_color (t.outline)
					a_p.set_line_width (1.0)
				elseif shows_hover
					and then hover_px >= cx
					and then hover_px <= cx + Dot_s + 7.0 + a_p.advance (options.i_th (i))
				then
					a_p.set_color (t.accent)
					a_p.set_line_width (1.5)
				else
					a_p.set_color (t.outline)
					a_p.set_line_width (1.5)
				end
				a_p.circle_stroke (cx + Dot_s / 2.0, cy, Dot_s / 2.0 - 1.0)
				a_p.set_line_width (1.0)
				if i = selected_index then
					if is_enabled then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.circle_fill (cx + Dot_s / 2.0, cy, Dot_s / 2.0 - 6.0)
				end
				if is_enabled and option_enabled.i_th (i) then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (cx + Dot_s + 7.0, cy + t.size_label / 2.0 - 2.0, options.i_th (i))
				if is_vertical then
					cy := cy + Row_h
				else
					cx := cx + Dot_s + 7.0 + a_p.advance (options.i_th (i)) + Gap_between
				end
				i := i + 1
			end
		end

	Row_h: REAL_64 = 26.0

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			p: SW_PAINTER
			cx: REAL_64
			i: INTEGER
		do
			if is_enabled and then attached probe_painter as pp then
				if is_vertical then
					i := ((a_py - y) / Row_h).truncated_to_integer + 1
					if i >= 1 and then i <= options.count
						and then option_enabled.i_th (i)
					then
						select_index (i)
					end
				else
					cx := x
					from
						i := 1
					until
						i > options.count or Result
					loop
						pp.font ({SW_PAINTER}.Role_ui, pp.theme.size_label, False)
						if a_px >= cx and then a_px <= cx + Dot_s + 7.0 + pp.advance (options.i_th (i)) then
							if option_enabled.i_th (i) then
								select_index (i)
							end
							Result := True
						end
						cx := cx + Dot_s + 7.0 + pp.advance (options.i_th (i)) + Gap_between
						i := i + 1
					end
				end
				Result := True
			else
				Result := is_enabled
			end
		end

feature -- Measurement support

	probe_painter: detachable SW_PAINTER
			-- Painter for hit-test measurement; the window's painter,
			-- remembered at draw time.

invariant
	options_attached: options /= Void
	selection_in_range: selected_index >= 0 and selected_index <= options.count

end
