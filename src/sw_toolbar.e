note
	description: "[
		A strip of compact drawn tool buttons: plain tools fire on
		click, toggle tools latch and show their state, gaps carve
		clusters. Hovering a tool surfaces its hint as the tooltip.
		Toggle state is queried by label - no index bookkeeping.
	]"

class
	SW_TOOLBAR

inherit
	SW_WIDGET
		redefine
			handle_click, wants_hover_point,
			accessible_role, preferred_width
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create items.make (8)
		end

feature -- Access

	items: ARRAYED_LIST [TUPLE [label: STRING_32; hint: STRING_32; enabled: BOOLEAN; action: detachable PROCEDURE; gap: BOOLEAN; can_toggle: BOOLEAN; is_on: BOOLEAN; glyph: INTEGER]]

	is_tool_on (a_label: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the toggle named `a_label' latched on?
		do
			across
				items as it
			loop
				if it.can_toggle and then it.label.same_string_general (a_label) then
					Result := it.is_on
				end
			end
		end

feature -- Element change

	add_tool (a_label, a_hint: READABLE_STRING_GENERAL; a_enabled: BOOLEAN; a_action: detachable PROCEDURE)
		local
			l, h: STRING_32
		do
			create l.make_from_string_general (a_label)
			create h.make_from_string_general (a_hint)
			items.extend ([l, h, a_enabled, a_action, False, False, False, 0])
		ensure
			grew: items.count = old items.count + 1
		end

	add_toggle (a_label, a_hint: READABLE_STRING_GENERAL; a_on: BOOLEAN; a_action: detachable PROCEDURE)
			-- A latching tool; `a_action' fires after each flip - read
			-- the new state with `is_tool_on'.
		local
			l, h: STRING_32
		do
			create l.make_from_string_general (a_label)
			create h.make_from_string_general (a_hint)
			items.extend ([l, h, True, a_action, False, True, a_on, 0])
		ensure
			grew: items.count = old items.count + 1
		end

	add_gap
		local
			e: STRING_32
		do
			create e.make_empty
			items.extend ([e, e, False, Void, True, False, False, 0])
		ensure
			grew: items.count = old items.count + 1
		end

	add_icon_item (a_glyph: INTEGER; a_hint: READABLE_STRING_GENERAL; a_action: detachable PROCEDURE)
			-- A drawn-glyph button: the icon IS the face, the label
			-- demoted to its tooltip (the toolbar's destiny).
		require
			glyph_known: a_glyph >= 1 and a_glyph <= {SW_PAINTER}.Glyph_error
		local
			l, h: STRING_32
		do
			create l.make_empty
			create h.make_from_string_general (a_hint)
			items.extend ([l, h, True, a_action, False, False, False, a_glyph])
		ensure
			grew: items.count = old items.count + 1
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- The width its tools are drawn in (0.44.1: in a row it had none, so clicks missed).
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label - 1.0, False)
			Result := 2.0 * Tool_inset
			across items as ic loop
				Result := Result + tool_advance (a_p, ic)
			end
			if probe_painter = Void then
				probe_painter := a_p
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 34.0
		end

	tool_width (a_p: SW_PAINTER; a_item: like items.item): REAL_64
			-- The room tool `a_item' is drawn in, the spacing after it not counted; the tool font must be
			-- set. THE one formula (scan 35): `preferred_width', `draw' and `handle_click' each had a copy.
		do
			if a_item.gap then
				Result := Separator_width
			elseif a_item.glyph > 0 then
				Result := Glyph_tool_width
			else
				Result := a_p.advance (a_item.label) + Label_tool_padding
			end
		ensure
			positive: Result > 0.0
		end

	tool_advance (a_p: SW_PAINTER; a_item: like items.item): REAL_64
			-- How far the next tool starts after `a_item'.
		do
			Result := tool_width (a_p, a_item)
			if not a_item.gap then
				Result := Result + Tool_spacing
			end
		ensure
			past_the_tool: Result >= tool_width (a_p, a_item)
		end

	Tool_inset: REAL_64 = 6.0
			-- Before the first tool and after the last.
	Separator_width: REAL_64 = 13.0
	Glyph_tool_width: REAL_64 = 28.0
	Label_tool_padding: REAL_64 = 22.0
			-- A labelled tool is its text plus this.
	Tool_spacing: REAL_64 = 3.0
			-- Between a tool and the next.

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tx, tw: REAL_64
			i: INTEGER
			it: like items.item
		do
			probe_painter := a_p
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.rrect_fill (x, y, width, height, t.radius)
			tx := x + Tool_inset
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label - 1.0, False)
			from
				i := 1
			until
				i > items.count
			loop
				it := items.i_th (i)
				if it.gap then
					a_p.set_color (t.outline)
					a_p.vline (tx + 5.0, y + 7.0, height - 14.0)
					tx := tx + Separator_width
				else
					tw := tool_width (a_p, it)
					if it.can_toggle and then it.is_on then
						a_p.set_color (t.wash_accent)
						a_p.rrect_fill (tx, y + 5.0, tw, height - 10.0, t.radius)
						a_p.set_color (t.accent)
						a_p.rrect_stroke (tx + 0.5, y + 5.5, tw - 1.0, height - 11.0, t.radius)
					elseif shows_hover and then it.enabled and then hover_px >= tx and then hover_px <= tx + tw then
						a_p.set_color (t.surface)
						a_p.rrect_fill (tx, y + 5.0, tw, height - 10.0, t.radius)
						if not it.hint.is_empty then
							set_tooltip (it.hint)
						end
					end
					if not it.enabled then
						a_p.set_color (t.ink_muted)
					elseif it.can_toggle and then it.is_on then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.ink)
					end
					if it.glyph > 0 then
						a_p.glyph (it.glyph, tx + tw / 2.0, y + height / 2.0, 14.0)
					else
						a_p.text (tx + 11.0, y + height / 2.0 + t.size_label / 2.0 - 3.0, it.label)
					end
					tx := tx + tw + Tool_spacing
				end
				i := i + 1
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			tx, tw: REAL_64
			i: INTEGER
			it: like items.item
			hit: BOOLEAN
		do
			if is_enabled and then attached probe_painter as p then
				p.font ({SW_PAINTER}.Role_ui, p.theme.size_label - 1.0, False)
				tx := x + Tool_inset
				from
					i := 1
				until
					i > items.count or hit
				loop
					it := items.i_th (i)
					if it.gap then
						tx := tx + Separator_width
					else
						tw := tool_width (p, it)
						if a_px >= tx and a_px <= tx + tw and it.enabled then
							if it.can_toggle then
								it.is_on := not it.is_on
							end
							if attached it.action as act then
								act.call
							end
							hit := True
						end
						tx := tx + tw + Tool_spacing
					end
					i := i + 1
				end
				Result := True
			end
		end

feature {NONE} -- Measurement support

	probe_painter: detachable SW_PAINTER


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_tool_bar
		end

invariant
	items_attached: items /= Void

end
