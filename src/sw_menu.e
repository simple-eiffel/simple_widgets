note
	description: "[
		A drawn popup menu - the toolkit's own, after the native
		TrackPopupMenu proved both unexplainable and untestable. Items
		carry a label, an optional shortcut hint, an enabled flag and
		an action agent; separators divide groups.

		A widget DECLARES its menu by returning one from context_menu;
		SW_WINDOW PRESENTS it: draws it above the root on the same
		surface (so tests can see it in the frame), routes hover and
		click to it, closes it on outside-click or Escape, and runs
		the chosen action after closing.
	]"

class
	SW_MENU

create
	make

feature {NONE} -- Initialization

	make
		do
			create items.make (8)
			create raw_labels.make (8)
			hover_index := 0
		end

feature -- Access

	items: ARRAYED_LIST [TUPLE [label: STRING_32; hint: STRING_32; enabled: BOOLEAN; action: detachable PROCEDURE; separator: BOOLEAN]]

	raw_labels: ARRAYED_LIST [STRING_32]
			-- Each item's label EXACTLY as declared, ampersands and all,
			-- parallel to `items'. `items.label' is the plain reading -
			-- what `measure' sizes and `draw' paints - so every existing
			-- caller sees the text it always saw; the "&" survives only
			-- here, where the mnemonic queries can still find it.

	hover_index: INTEGER
			-- 1-based item under the pointer; 0 = none.

	x: REAL_64
	y: REAL_64
	width: REAL_64
	height: REAL_64

feature -- Element change

	add_item (a_label: READABLE_STRING_GENERAL; a_hint: READABLE_STRING_GENERAL; a_enabled: BOOLEAN; a_action: detachable PROCEDURE)
		local
			l, h: STRING_32
		do
			create l.make_from_string_general (a_label)
			create h.make_from_string_general (a_hint)
			raw_labels.extend (l.twin)
			items.extend ([mnemonics.plain (l), h, a_enabled, a_action, False])
		ensure
			grew: items.count = old items.count + 1
			parallel: raw_labels.count = items.count
		end

	add_separator
		do
			raw_labels.extend ({STRING_32} "")
			items.extend ([{STRING_32} "", {STRING_32} "", False, Void, True])
		ensure
			grew: items.count = old items.count + 1
			parallel: raw_labels.count = items.count
		end

feature -- Mnemonics

	mnemonics: SW_MNEMONIC
			-- The one ampersand parser; see SW_MNEMONIC.
		once
			create Result
		end

	item_underline_index (i: INTEGER): INTEGER
			-- 1-based index INTO `items.i_th (i).label' of the character
			-- item `i' underlines; 0 when it declares no mnemonic.
		require
			in_range: i >= 1 and i <= items.count
		do
			Result := mnemonics.underline_index (raw_labels.i_th (i))
		ensure
			in_label: Result >= 0 and Result <= items.i_th (i).label.count
		end

	item_for_mnemonic (a_typed: CHARACTER_32): INTEGER
			-- The 1-based index of the first ENABLED, non-separator item
			-- whose mnemonic is `a_typed' (case folded); 0 when none
			-- answers. This is what a bare letter does while the menu is
			-- open - the second half of the Alt+F, then N gesture.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > items.count or Result /= 0
			loop
				if not items.i_th (i).separator and then items.i_th (i).enabled
					and then mnemonics.matches (raw_labels.i_th (i), a_typed)
				then
					Result := i
				end
				i := i + 1
			end
		ensure
			valid: Result >= 0 and Result <= items.count
			enabled_only: Result > 0 implies items.i_th (Result).enabled
		end

feature -- Geometry

	Item_h: REAL_64 = 30.0
	Sep_h: REAL_64 = 9.0
	Pad: REAL_64 = 5.0

	measure (a_p: SW_PAINTER)
			-- Compute width/height from the items.
		local
			w, lw: REAL_64
		do
			w := 160.0
			across
				items as it
			loop
				if not it.separator then
					a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
					lw := a_p.advance (it.label) + 24.0
					if not it.hint.is_empty then
						a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip, False)
						lw := lw + a_p.advance (it.hint) + 28.0
					end
					if lw > w then
						w := lw
					end
				end
			end
			width := w + 2.0 * Pad
			height := 2.0 * Pad
			across
				items as it
			loop
				if it.separator then
					height := height + Sep_h
				else
					height := height + Item_h
				end
			end
		ensure
			sized: width > 0.0 and height > 0.0
		end

	place (a_x, a_y, a_win_w, a_win_h: REAL_64)
			-- Position at the point, clamped inside the window.
		do
			x := a_x.min (a_win_w - width - 4.0).max (4.0)
			y := a_y.min (a_win_h - height - 4.0).max (4.0)
		ensure
			on_screen: x >= 0.0 and y >= 0.0
		end

	contains (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := a_px >= x and then a_px <= x + width
				and then a_py >= y and then a_py <= y + height
		end

	item_at (a_px, a_py: REAL_64): INTEGER
			-- 1-based index of the enabled item under the point; 0 = none.
		local
			cy: REAL_64
			i: INTEGER
		do
			if contains (a_px, a_py) then
				cy := y + Pad
				from
					i := 1
				until
					i > items.count or Result /= 0
				loop
					if items.i_th (i).separator then
						cy := cy + Sep_h
					else
						if a_py >= cy and then a_py < cy + Item_h
							and then items.i_th (i).enabled
						then
							Result := i
						end
						cy := cy + Item_h
					end
					i := i + 1
				end
			end
		ensure
			valid: Result >= 0 and Result <= items.count
			enabled_only: Result > 0 implies items.i_th (Result).enabled
		end

	set_hover_at (a_px, a_py: REAL_64)
		do
			hover_index := item_at (a_px, a_py)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cy: REAL_64
			i, ul: INTEGER
			it: TUPLE [label: STRING_32; hint: STRING_32; enabled: BOOLEAN; action: detachable PROCEDURE; separator: BOOLEAN]
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius + 2.0)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius + 2.0)
			cy := y + Pad
			from
				i := 1
			until
				i > items.count
			loop
				it := items.i_th (i)
				if it.separator then
					a_p.hline (x + Pad + 4.0, cy + Sep_h / 2.0, width - 2.0 * Pad - 8.0)
					cy := cy + Sep_h
				else
					if i = hover_index then
						a_p.set_color (t.surface_variant)
						a_p.rrect_fill (x + Pad, cy, width - 2.0 * Pad, Item_h, t.radius)
					end
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
					if it.enabled then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.text (x + Pad + 10.0, cy + Item_h - 10.0, it.label)
					ul := item_underline_index (i)
					if ul > 0 then
							-- Under exactly the one character, measured in
							-- the SAME font the label just drew in, and in
							-- the item's OWN INK - `hline' would draw the
							-- theme's outline colour instead, which under a
							-- label reads as nothing at all.
						a_p.fill_rect (x + Pad + 10.0 + a_p.advance (it.label.substring (1, ul - 1)),
							cy + Item_h - 8.0,
							a_p.advance (it.label.substring (ul, ul)),
							(1.0 * t.text_scale).max (1.0))
					end
					if not it.hint.is_empty then
						a_p.font ({SW_PAINTER}.Role_mono, t.size_chip, False)
						a_p.set_color (t.ink_muted)
						a_p.text (x + width - Pad - 10.0 - a_p.advance (it.hint), cy + Item_h - 11.0, it.hint)
					end
					cy := cy + Item_h
				end
				i := i + 1
			end
		end

invariant
	items_attached: items /= Void
	raw_labels_attached: raw_labels /= Void
	parallel: raw_labels.count = items.count
	hover_in_range: hover_index >= 0 and hover_index <= items.count

end
