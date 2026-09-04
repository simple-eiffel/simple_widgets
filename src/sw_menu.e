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
			create item_heights.make (8)
			create shaped.make
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

	shaped: SW_SHAPED_TEXT
			-- This menu's own one-line layout cache. Per MENU, not per
			-- application: a menu is built fresh on every open (so item
			-- enablement reflects live state), which makes the cache's
			-- life exactly the life of one presentation - and a
			-- presentation is repainted on every frame it is up, which
			-- is what there is to save.

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
			item_heights.wipe_out
		ensure
			grew: items.count = old items.count + 1
			parallel: raw_labels.count = items.count
		end

	add_separator
		do
			raw_labels.extend ({STRING_32} "")
			items.extend ([{STRING_32} "", {STRING_32} "", False, Void, True])
			item_heights.wipe_out
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

feature -- Keyboard navigation

	is_selectable (i: INTEGER): BOOLEAN
			-- Can the highlight land on item `i'? A separator cannot be
			-- chosen and neither can a disabled item, which is why the arrow
			-- keys must STEP OVER both rather than stopping on them - the
			-- behaviour every Windows menu has.
		do
			Result := i >= 1 and then i <= items.count
				and then not items.i_th (i).separator and then items.i_th (i).enabled
		end

	has_selectable: BOOLEAN
			-- Is there anything the highlight can land on at all?
		do
			Result := across 1 |..| items.count as i some is_selectable (i) end
		end

	hovered_action: detachable PROCEDURE
			-- What Enter would run; Void when nothing is highlighted.
		do
			if is_selectable (hover_index) then
				Result := items.i_th (hover_index).action
			end
		end

feature -- Keyboard navigation: moving the highlight

	hover_first
			-- The first item the highlight can land on; nothing when there is none.
		do
			hover_index := next_selectable_from (1, 1)
		ensure
			landed_or_none: hover_index = 0 or else is_selectable (hover_index)
			found_when_any: has_selectable implies hover_index > 0
		end

	hover_last
		do
			hover_index := next_selectable_from (items.count, -1)
		ensure
			landed_or_none: hover_index = 0 or else is_selectable (hover_index)
			found_when_any: has_selectable implies hover_index > 0
		end

	hover_next
			-- Down: the next selectable item, WRAPPING to the top - and from
			-- nothing at all it lands on the first, which is what Down does
			-- to a menu just opened by Alt.
		do
			if hover_index = 0 then
				hover_first
			else
				hover_index := wrapped_selectable (hover_index, 1)
			end
		ensure
			landed_or_none: hover_index = 0 or else is_selectable (hover_index)
			found_when_any: has_selectable implies hover_index > 0
		end

	hover_previous
			-- Up: the previous selectable item, wrapping to the BOTTOM - and
			-- from nothing it lands on the last, so Up on a freshly opened
			-- menu reaches Exit in one keystroke.
		do
			if hover_index = 0 then
				hover_last
			else
				hover_index := wrapped_selectable (hover_index, -1)
			end
		ensure
			landed_or_none: hover_index = 0 or else is_selectable (hover_index)
			found_when_any: has_selectable implies hover_index > 0
		end

	clear_hover
		do
			hover_index := 0
		ensure
			nothing_highlighted: hover_index = 0
		end

feature {NONE} -- Keyboard navigation: implementation

	next_selectable_from (a_start, a_step: INTEGER): INTEGER
			-- Walking from `a_start' by `a_step' WITHOUT wrapping, the first
			-- selectable index; 0 when the walk runs off the end.
		require
			stepping: a_step = 1 or a_step = -1
		local
			i: INTEGER
		do
			from i := a_start until Result /= 0 or i < 1 or i > items.count loop
				if is_selectable (i) then
					Result := i
				end
				i := i + a_step
			end
		ensure
			selectable_or_none: Result = 0 or else is_selectable (Result)
		end

	wrapped_selectable (a_from, a_step: INTEGER): INTEGER
			-- The next selectable index from `a_from' by `a_step', wrapping
			-- once round; `a_from' itself when it is the only one, and 0
			-- when nothing at all can be chosen. Bounded by `items.count'
			-- steps, so a menu of nothing but separators cannot spin here.
		require
			stepping: a_step = 1 or a_step = -1
		local
			i, n, tried: INTEGER
		do
			n := items.count
			if n > 0 then
				from
					i := a_from
				until
					Result /= 0 or tried >= n
				loop
					i := i + a_step
					if i > n then
						i := 1
					elseif i < 1 then
						i := n
					end
					if is_selectable (i) then
						Result := i
					end
					tried := tried + 1
				end
			end
		ensure
			selectable_or_none: Result = 0 or else is_selectable (Result)
		end

feature -- Shaped labels

	label_pixel_size (a_p: SW_PAINTER): INTEGER
			-- The size an item label is SHAPED at: the theme's label
			-- size run through `text_scale', which is exactly what
			-- `SW_PAINTER.font' hands cairo on the toy path. One number,
			-- so a measure and a paint cannot disagree.
		do
			Result := (a_p.theme.size_label * a_p.theme.text_scale).rounded.max (1)
		ensure
			positive: Result >= 1
		end

	hint_pixel_size (a_p: SW_PAINTER): INTEGER
			-- The size a shortcut hint is shaped at.
		do
			Result := (a_p.theme.size_chip * a_p.theme.text_scale).rounded.max (1)
		ensure
			positive: Result >= 1
		end

	label_width (a_p: SW_PAINTER; a_text: READABLE_STRING_32): REAL_64
			-- How wide `a_text' PAINTS as an item label - the shaped
			-- measure when the painter carries a kit, cairo's advance
			-- when it does not.
			--
			-- The two must be the same query, because `measure' sizes
			-- the menu with it and `draw' places the type with it. When
			-- `measure' asked cairo and `draw' asked the shaper, an
			-- emoji-only item measured NOTHING and painted a 128-pixel
			-- picture over its neighbour.
		do
			if attached a_p.shaping as al_kit then
				Result := shaped.width_of (al_kit, a_text, label_pixel_size (a_p))
			else
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
				Result := a_p.advance (a_text)
			end
		ensure
			non_negative: Result >= 0.0
		end

	hint_width (a_p: SW_PAINTER; a_text: READABLE_STRING_32): REAL_64
			-- How wide `a_text' paints in the shortcut column.
		do
			if attached a_p.shaping as al_kit then
				Result := shaped.width_of (al_kit, a_text, hint_pixel_size (a_p))
			else
				a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip, False)
				Result := a_p.advance (a_text)
			end
		ensure
			non_negative: Result >= 0.0
		end

	item_underline_bounds (a_p: SW_PAINTER; i: INTEGER): TUPLE [left, width: REAL_64]
			-- Where item `i''s mnemonic underline goes, measured from
			-- the LEFT EDGE OF ITS LABEL; a zero width when the item
			-- declares no mnemonic.
			--
			-- THE one formula: `draw' paints with it, and a test can ask
			-- it without reading pixels. On the shaped path it comes from
			-- the layout's CLUSTER POSITIONS, which is the only way it
			-- can be right for a script whose source order and paint
			-- order differ - a prefix advance underlines the wrong end
			-- of a Hebrew label every time.
		require
			in_range: i >= 1 and i <= items.count
		local
			ul: INTEGER
			lb: STRING_32
		do
			Result := [0.0, 0.0]
			ul := item_underline_index (i)
			if ul > 0 then
				lb := items.i_th (i).label
				if attached a_p.shaping as al_kit then
					Result := shaped.character_span (
						shaped.layout_of (al_kit, lb, label_pixel_size (a_p)), ul)
				else
					a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
					Result := [a_p.advance (lb.substring (1, ul - 1)),
						a_p.advance (lb.substring (ul, ul))]
				end
			end
		ensure
			nothing_to_underline: item_underline_index (i) = 0 implies Result.width = 0.0
			non_negative: Result.width >= 0.0
		end

feature -- Geometry

	Item_h: REAL_64 = 30.0
			-- The FLOOR an item row occupies, not the whole answer: see
			-- `row_height'.

	Sep_h: REAL_64 = 9.0
	Pad: REAL_64 = 5.0

	item_heights: ARRAYED_LIST [REAL_64]
			-- One row height per item, as `measure' last computed them;
			-- empty before the first measure.
			--
			-- CACHED AND NOT RE-ASKED, because `item_at' has no painter
			-- and must not grow one: SW_WINDOW hit-tests a popup on the
			-- pointer path, where there is a menu and a point and nothing
			-- else. `show_popup' measures before it places, so by the
			-- time anything can be hit these are current.

	row_height (i: INTEGER): REAL_64
			-- How tall row `i' is: what `measure' worked out, or the flat
			-- constants before anything has been measured.
		require
			in_range: i >= 1 and i <= items.count
		do
			if i <= item_heights.count then
				Result := item_heights.i_th (i)
			elseif items.i_th (i).separator then
				Result := Sep_h
			else
				Result := Item_h
			end
		ensure
			positive: Result > 0.0
		end

	measure (a_p: SW_PAINTER)
			-- Compute width/height from the items.
		local
			w, lw, rh: REAL_64
		do
			w := 160.0
			item_heights.wipe_out
			across
				items as it
			loop
				if it.separator then
					item_heights.extend (Sep_h)
				else
					lw := label_width (a_p, it.label) + 24.0
					if not it.hint.is_empty then
						lw := lw + hint_width (a_p, it.hint) + 28.0
					end
					if lw > w then
						w := lw
					end
						-- THE ROW IS AS TALL AS WHAT IT PAINTS - on the
						-- shaped path, and ONLY there. `Item_h' is a flat
						-- 30 that never scaled with the theme, which stays
						-- invisible while every label is one line of type:
						-- cairo's toy glyphs at 2x are cramped in it and
						-- always were, and growing the row for them would
						-- move every menu that has ever shipped. A colour
						-- emoji is a different matter - a Noto picture laid
						-- out at the label's pixel size is taller than the
						-- type, and on a flat row it drew over the item
						-- below and out through the menu's own top border.
						-- So the row grows for what the SHAPER measured and
						-- for nothing else; the toy path keeps the constant
						-- it always had, to the pixel.
					rh := Item_h
					if attached a_p.shaping as al_kit then
						rh := rh.max (
							shaped.layout_of (al_kit, it.label, label_pixel_size (a_p)).total_height + 6.0)
					end
					item_heights.extend (rh)
				end
			end
			width := w + 2.0 * Pad
			height := 2.0 * Pad
			across
				item_heights as h
			loop
				height := height + h
			end
		ensure
			sized: width > 0.0 and height > 0.0
			one_height_per_item: item_heights.count = items.count
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
					if not items.i_th (i).separator
						and then a_py >= cy and then a_py < cy + row_height (i)
						and then items.i_th (i).enabled
					then
						Result := i
					end
					cy := cy + row_height (i)
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
			cy, base, lx, hw, hx, hbase: REAL_64
			i, ul: INTEGER
			it: TUPLE [label: STRING_32; hint: STRING_32; enabled: BOOLEAN; action: detachable PROCEDURE; separator: BOOLEAN]
			ub: TUPLE [left, width: REAL_64]
			lay: SHAPED_LAYOUT
			rh, top: REAL_64
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
				rh := row_height (i)
				if it.separator then
					a_p.hline (x + Pad + 4.0, cy + rh / 2.0, width - 2.0 * Pad - 8.0)
					cy := cy + rh
				else
					if i = hover_index then
						a_p.set_color (t.surface_variant)
						a_p.rrect_fill (x + Pad, cy, width - 2.0 * Pad, rh, t.radius)
					end
					if it.enabled then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink_muted)
					end
					base := cy + rh - 10.0
					lx := x + Pad + 10.0
						-- THE SHAPED PATH WHEN THERE IS ONE. `text' is
						-- cairo's toy `show_text': it resolves no colour
						-- emoji artwork and shapes no complex script, so a
						-- menu item labelled with an emoji drew an empty
						-- box in every consumer that had shaped text on -
						-- while the very same string in a chat bubble two
						-- inches away drew the picture.
						--
						-- CENTRED IN ITS ROW, not hung off a baseline
						-- measured from the bottom: `measure' already grew
						-- the row to hold this layout, and a picture that
						-- is taller than the type has to sit INSIDE the
						-- row it made. The baseline then comes back OUT of
						-- the placement, because the underline needs it.
					if attached a_p.shaping as al_kit then
						lay := shaped.layout_of (al_kit, it.label, label_pixel_size (a_p))
						top := cy + ((rh - lay.total_height) / 2.0).max (0.0)
						a_p.draw_shaped_layout (lay, lx, top)
						base := shaped.baseline_for_top (lay, top)
					else
						a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
						a_p.text (lx, base, it.label)
					end
					ul := item_underline_index (i)
					if ul > 0 then
							-- Under exactly the one character, where that
							-- character actually PAINTED, and in the item's
							-- OWN INK - `hline' would draw the theme's
							-- outline colour instead, which under a label
							-- reads as nothing at all.
						ub := item_underline_bounds (a_p, i)
						a_p.fill_rect (lx + ub.left, base + 2.0, ub.width,
							(1.0 * t.text_scale).max (1.0))
					end
					if not it.hint.is_empty then
						a_p.set_color (t.ink_muted)
						hw := hint_width (a_p, it.hint)
						hx := x + width - Pad - 10.0 - hw
						hbase := base - 1.0
						if attached a_p.shaping as al_hint_kit then
							lay := shaped.layout_of (al_hint_kit, it.hint, hint_pixel_size (a_p))
							a_p.draw_shaped_layout (lay, hx, shaped.top_for_baseline (lay, hbase))
						else
							a_p.font ({SW_PAINTER}.Role_mono, t.size_chip, False)
							a_p.text (hx, hbase, it.hint)
						end
					end
					cy := cy + rh
				end
				i := i + 1
			end
		end

invariant
	items_attached: items /= Void
	raw_labels_attached: raw_labels /= Void
	shaped_attached: shaped /= Void
	item_heights_attached: item_heights /= Void
	parallel: raw_labels.count = items.count
	hover_in_range: hover_index >= 0 and hover_index <= items.count

end
