note
	description: "[
		A drawn menu bar: labels across the top; clicking one presents
		its SW_MENU beneath it through the pending-menu handshake. The
		hovered label highlights; everything is theme chrome.

		MNEMONICS (0.6.0). A title given as "&File" draws as "File" with
		the F underlined and answers to Alt+F. The ampersand never
		reaches `labels' - `add_menu' stores the plain reading there and
		keeps the declaration in `raw_labels' - so every existing reader
		of `labels' sees exactly the text it always saw.

		ONE GEOMETRY. `draw', `handle_click' and `open_menu' all ask
		`pad_bounds' where a pad starts and how wide it is; there is no
		second formula that can drift from the first. That is why
		SW_WINDOW can drop a menu under the right pad for a key it never
		saw a pointer land on.
	]"

class
	SW_MENU_BAR

inherit
	SW_WIDGET
		redefine
			handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create labels.make (4)
			create raw_labels.make (4)
			create builders.make (4)
			create conditions.make (4)
		end

feature -- Access

	labels: ARRAYED_LIST [STRING_32]
			-- The pad titles as the user reads them: ampersand-free.

	raw_labels: ARRAYED_LIST [STRING_32]
			-- The pad titles EXACTLY as declared, ampersands and all -
			-- where `menu_for_mnemonic' still finds the Alt-key.

	builders: ARRAYED_LIST [FUNCTION [SW_MENU]]
			-- One menu-builder agent per label: menus are built fresh
			-- on every open, so item enablement reflects live state -
			-- the same rule as context menus.

	conditions: ARRAYED_LIST [detachable FUNCTION [BOOLEAN]]
			-- Per-pad enabling condition; Void = always enabled.
			-- Queried at draw and click time, so pads grey and
			-- deafen the instant state turns against them.

	pad_enabled (i: INTEGER): BOOLEAN
			-- Is pad `i' enabled right now?
		require
			in_range: i >= 1 and i <= labels.count
		do
			Result := not attached conditions.i_th (i) as c or else c.item ([])
		end

feature -- Element change

	add_menu (a_label: READABLE_STRING_GENERAL; a_builder: FUNCTION [SW_MENU])
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			raw_labels.extend (l.twin)
			labels.extend (mnemonics.plain (l))
			builders.extend (a_builder)
			conditions.extend (Void)
		ensure
			grew: labels.count = old labels.count + 1
			parallel: raw_labels.count = labels.count
		end

	add_menu_when (a_label: READABLE_STRING_GENERAL; a_builder: FUNCTION [SW_MENU]; a_when: FUNCTION [BOOLEAN])
			-- A pad whose availability tracks `a_when' - greyed and
			-- deaf whenever the condition says False.
		do
			add_menu (a_label, a_builder)
			conditions [conditions.count] := a_when
		ensure
			grew: labels.count = old labels.count + 1
			conditioned: conditions.i_th (labels.count) = a_when
		end

feature -- Mnemonics

	mnemonics: SW_MNEMONIC
			-- The one ampersand parser; see SW_MNEMONIC.
		once
			create Result
		end

	pad_underline_index (i: INTEGER): INTEGER
			-- 1-based index INTO `labels.i_th (i)' of the character pad
			-- `i' underlines; 0 when it declares no mnemonic.
		require
			in_range: i >= 1 and i <= labels.count
		do
			Result := mnemonics.underline_index (raw_labels.i_th (i))
		ensure
			in_label: Result >= 0 and Result <= labels.i_th (i).count
		end

	last_opened_pad: INTEGER
			-- The 1-based pad whose menu was opened last, by pointer or by
			-- Alt; 0 before any. Left and Right walk from here, so a menu
			-- opened by a CLICK answers the arrow keys exactly as one
			-- opened by a mnemonic - the two doors stay one behaviour.

	neighbour_pad (a_from, a_step: INTEGER): INTEGER
			-- The next ENABLED pad from `a_from' by `a_step', wrapping once
			-- round; `a_from' when it is the only enabled one, and 0 when
			-- none is. Bounded by `labels.count' steps, so a bar of
			-- disabled pads cannot spin here.
		require
			stepping: a_step = 1 or a_step = -1
		local
			i, n, tried: INTEGER
		do
			n := labels.count
			if n > 0 then
				if a_from >= 1 and a_from <= n then
					i := a_from
				else
					i := 1
				end
				if pad_enabled (i) and then a_from < 1 then
					Result := i
				end
				from until Result /= 0 or tried >= n loop
					i := i + a_step
					if i > n then
						i := 1
					elseif i < 1 then
						i := n
					end
					if pad_enabled (i) then
						Result := i
					end
					tried := tried + 1
				end
			end
		ensure
			enabled_or_none: Result = 0 or else pad_enabled (Result)
			in_range: Result >= 0 and Result <= labels.count
		end

	menu_for_mnemonic (a_typed: CHARACTER_32): INTEGER
			-- The 1-based pad Alt+`a_typed' opens (case folded); 0 when
			-- no ENABLED pad answers to that letter.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > labels.count or Result /= 0
			loop
				if pad_enabled (i) and then mnemonics.matches (raw_labels.i_th (i), a_typed) then
					Result := i
				end
				i := i + 1
			end
		ensure
			valid: Result >= 0 and Result <= labels.count
			enabled_only: Result > 0 implies pad_enabled (Result)
		end

	open_menu (a_p: SW_PAINTER; i: INTEGER)
			-- Build pad `i''s menu and offer it through the SAME
			-- pending-menu handshake a click uses, so a keyboard open
			-- and a pointer open are one path, not two.
		require
			in_range: i >= 1 and i <= labels.count
			enabled: pad_enabled (i)
		do
			probe_painter := a_p
			pending_menu := builders.i_th (i).item ([])
			last_opened_pad := i
		ensure
			offered: pending_menu /= Void
			remembered: last_opened_pad = i
		end

feature -- Geometry

	pad_bounds (a_p: SW_PAINTER; i: INTEGER): TUPLE [left, width: REAL_64]
			-- Where pad `i' starts and how wide it is, in window
			-- coordinates. THE one formula: `draw' paints with it,
			-- `handle_click' hit-tests with it, and SW_WINDOW drops an
			-- Alt-opened menu under it.
		require
			in_range: i >= 1 and i <= labels.count
		local
			tx, tw: REAL_64
			k: INTEGER
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			tx := x + 6.0
			from
				k := 1
			until
				k >= i
			loop
				tx := tx + a_p.advance (labels.i_th (k)) + 24.0 + 2.0
				k := k + 1
			end
			tw := a_p.advance (labels.i_th (i)) + 24.0
			Result := [tx, tw]
		ensure
			positive_width: Result.width > 0.0
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 36.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tx, tw, base: REAL_64
			i, ul: INTEGER
			b: TUPLE [left, width: REAL_64]
		do
			probe_painter := a_p
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, height)
			a_p.hline (x, y + height - 1.0, width)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			from
				i := 1
			until
				i > labels.count
			loop
				b := pad_bounds (a_p, i)
				tx := b.left
				tw := b.width
				if pad_enabled (i) and then shows_hover and then hover_px >= tx and then hover_px <= tx + tw then
					a_p.set_color (t.surface)
					a_p.rrect_fill (tx, y + 4.0, tw, height - 9.0, t.radius)
				end
				if pad_enabled (i) then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				base := y + height / 2.0 + t.size_label / 2.0 - 2.0
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.text (tx + 12.0, base, labels.i_th (i))
				ul := pad_underline_index (i)
				if ul > 0 then
						-- The underline is drawn in the pad's OWN INK with
						-- `fill_rect', not with `hline': `hline' is a
						-- theme-OUTLINE hairline (it sets that colour
						-- itself), which on a dark theme is all but
						-- invisible under a label. It scales with the
						-- theme the way the type does.
					a_p.fill_rect (tx + 12.0 + a_p.advance (labels.i_th (i).substring (1, ul - 1)),
						base + 2.0 * t.text_scale,
						a_p.advance (labels.i_th (i).substring (ul, ul)),
						(1.0 * t.text_scale).max (1.0))
				end
				i := i + 1
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
			b: TUPLE [left, width: REAL_64]
		do
			if is_enabled and then attached probe_painter as p then
				from
					i := 1
				until
					i > labels.count or Result
				loop
					b := pad_bounds (p, i)
					if a_px >= b.left and a_px <= b.left + b.width then
						if pad_enabled (i) then
							pending_menu := builders.i_th (i).item ([])
							last_opened_pad := i
						end
						Result := True
					end
					i := i + 1
				end
				Result := True
			end
		end

feature {NONE} -- Measurement support

	probe_painter: detachable SW_PAINTER

invariant
	parallel: labels.count = builders.count
	raw_parallel: raw_labels.count = labels.count

end
