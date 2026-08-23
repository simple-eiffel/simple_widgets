note
	description: "[
		A notebook: a drawn tab bar over one visible page. Pages are
		(label, widget) pairs; selecting a tab swaps which page is
		laid out, drawn and hit-tested. The change agent fires with
		the new index.
	]"

class
	SW_TABS

inherit
	SW_WIDGET
		redefine
			sub_widgets,
			arrange, widget_at, handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create labels.make (4)
			create pages.make (4)
			selected_index := 0
		end

feature -- Access

	labels: ARRAYED_LIST [STRING_32]
	pages: ARRAYED_LIST [SW_WIDGET]

	selected_index: INTEGER
			-- 1-based selected page; 0 only while empty.

	on_change: detachable PROCEDURE [INTEGER]

	Bar_h: REAL_64 = 40.0

	selected_page: detachable SW_WIDGET
		do
			if selected_index >= 1 and selected_index <= pages.count then
				Result := pages.i_th (selected_index)
			end
		end

feature -- Element change

	add_page (a_label: READABLE_STRING_GENERAL; a_page: SW_WIDGET)
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			labels.extend (l)
			pages.extend (a_page)
			builders.extend (Void)
			a_page.set_parent (Current)
			if selected_index = 0 then
				selected_index := 1
			end
		ensure
			grew: pages.count = old pages.count + 1
			adopted: a_page.parent = Current
			something_selected: selected_index >= 1
		end

	add_lazy_page (a_label: READABLE_STRING_GENERAL; a_builder: FUNCTION [SW_WIDGET])
			-- The page is BUILT on first selection (menus-style):
			-- until then a weightless spacer stands in. Ten heavy
			-- tabs cost one page's construction at startup.
		local
			l: STRING_32
			stub: SW_SPACER
		do
			create l.make_from_string_general (a_label)
			labels.extend (l)
			create stub.make
			stub.set_parent (Current)
			pages.extend (stub)
			builders.extend (a_builder)
			if selected_index = 0 then
				selected_index := 1
			end
		ensure
			grew: pages.count = old pages.count + 1
			armed: builders.last = a_builder
			something_selected: selected_index >= 1
		end

	builders: ARRAYED_LIST [detachable FUNCTION [SW_WIDGET]]
			-- Parallel to `pages': the pending constructor, consumed
			-- by `ensure_built' on first selection; Void = eager.
		attribute
			create Result.make (4)
		end

	ensure_built (a_i: INTEGER)
			-- Materialize page `a_i' if a builder is still pending.
		require
			in_range: a_i >= 1 and a_i <= pages.count
		local
			pg: SW_WIDGET
		do
			if attached builders.i_th (a_i) as b then
				pg := b.item ([])
				pg.set_parent (Current)
				pages.put_i_th (pg, a_i)
				builders.put_i_th (Void, a_i)
			end
		ensure
			built: builders.i_th (a_i) = Void
		end

	select_tab (a_i: INTEGER)
		require
			in_range: a_i >= 1 and a_i <= pages.count
		do
			ensure_built (a_i)
			if a_i /= selected_index then
				selected_index := a_i
				if attached on_change as a then
					a.call (a_i)
				end
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

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (pages.count)
			across
				pages as pg
			loop
				Result.extend (pg)
			end
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Bar_h + 8.0
			if attached selected_page as pg then
				Result := Result + pg.clamped_height (pg.preferred_height (a_p, a_width))
			end
		end

	arrange (a_p: SW_PAINTER)
		do
			if attached selected_page as pg then
				pg.set_bounds (x, y + Bar_h + 8.0, width,
					(height - Bar_h - 8.0).max (0.0))
				pg.arrange (a_p)
			end
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
			a_p.hline (x, y + Bar_h - 1.0, width)
			tx := x
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			from
				i := 1
			until
				i > labels.count
			loop
				tw := a_p.advance (labels.i_th (i)) + 30.0
				if i = selected_index then
					a_p.set_color (t.surface)
					a_p.rrect_fill (tx, y + 4.0, tw, Bar_h - 5.0, t.radius)
					a_p.set_color (t.accent)
					a_p.fill_rect (tx + 4.0, y + Bar_h - 3.0, tw - 8.0, 3.0)
					a_p.set_color (t.ink)
				elseif shows_hover and then hover_py < y + Bar_h
					and then hover_px >= tx and then hover_px <= tx + tw
				then
					a_p.set_color (t.surface_variant)
					a_p.rrect_fill (tx, y + 4.0, tw, Bar_h - 5.0, t.radius)
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (tx + 15.0, y + Bar_h / 2.0 + t.size_label / 2.0 - 1.0, labels.i_th (i))
				tx := tx + tw + 4.0
				i := i + 1
			end
			if attached selected_page as pg then
				pg.draw (a_p)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if a_py < y + Bar_h then
					Result := Current
				elseif attached selected_page as pg then
					Result := pg.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			tx, tw: REAL_64
			i: INTEGER
			pp: detachable SW_PAINTER
		do
			pp := probe_painter
			if is_enabled and then a_py < y + Bar_h and then attached pp as p then
				tx := x
				p.font ({SW_PAINTER}.Role_ui, p.theme.size_label, False)
				from
					i := 1
				until
					i > labels.count or Result
				loop
					tw := p.advance (labels.i_th (i)) + 30.0
					if a_px >= tx and a_px <= tx + tw then
						select_tab (i)
						Result := True
					end
					tx := tx + tw + 4.0
					i := i + 1
				end
				Result := True
			end
		end

feature {NONE} -- Measurement support

	probe_painter: detachable SW_PAINTER

invariant
	parallel_pages: labels.count = pages.count
	selection_in_range: selected_index >= 0 and selected_index <= pages.count
	selected_when_populated: pages.count > 0 implies selected_index >= 1

end
