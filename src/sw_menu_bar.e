note
	description: "[
		A drawn menu bar: labels across the top; clicking one presents
		its SW_MENU beneath it through the pending-menu handshake. The
		hovered label highlights; everything is theme chrome.
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
			create builders.make (4)
			create conditions.make (4)
		end

feature -- Access

	labels: ARRAYED_LIST [STRING_32]

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
			labels.extend (l)
			builders.extend (a_builder)
			conditions.extend (Void)
		ensure
			grew: labels.count = old labels.count + 1
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
			tx, tw: REAL_64
			i: INTEGER
		do
			probe_painter := a_p
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, height)
			a_p.hline (x, y + height - 1.0, width)
			tx := x + 6.0
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			from
				i := 1
			until
				i > labels.count
			loop
				tw := a_p.advance (labels.i_th (i)) + 24.0
				if pad_enabled (i) and then shows_hover and then hover_px >= tx and then hover_px <= tx + tw then
					a_p.set_color (t.surface)
					a_p.rrect_fill (tx, y + 4.0, tw, height - 9.0, t.radius)
				end
				if pad_enabled (i) then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (tx + 12.0, y + height / 2.0 + t.size_label / 2.0 - 2.0, labels.i_th (i))
				tx := tx + tw + 2.0
				i := i + 1
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			tx, tw: REAL_64
			i: INTEGER
		do
			if is_enabled and then attached probe_painter as p then
				tx := x + 6.0
				p.font ({SW_PAINTER}.Role_ui, p.theme.size_label, False)
				from
					i := 1
				until
					i > labels.count or Result
				loop
					tw := p.advance (labels.i_th (i)) + 24.0
					if a_px >= tx and a_px <= tx + tw then
						if pad_enabled (i) then
							pending_menu := builders.i_th (i).item ([])
						end
						Result := True
					end
					tx := tx + tw + 2.0
					i := i + 1
				end
				Result := True
			end
		end

feature {NONE} -- Measurement support

	probe_painter: detachable SW_PAINTER

invariant
	parallel: labels.count = builders.count

end
