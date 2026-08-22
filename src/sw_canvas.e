note
	description: "[
		A delegate-drawn surface: the host paints through an agent
		and hears about pointer activity through agents. The escape
		valve for custom drawing that stays inside the painter
		monopoly - the host receives an SW_PAINTER, never a context.
	]"

class
	SW_CANVAS

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag, context_menu, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make (a_height: REAL_64)
		require
			positive: a_height > 0.0
		do
			canvas_height := a_height
		ensure
			kept: canvas_height = a_height
		end

feature -- Access

	canvas_height: REAL_64

	on_paint: detachable PROCEDURE [SW_PAINTER, REAL_64, REAL_64, REAL_64, REAL_64]
			-- (painter, x, y, width, height) - clipped to the canvas.

	on_press: detachable PROCEDURE [REAL_64, REAL_64]
			-- Left click at canvas-relative (x, y).

	on_sweep: detachable PROCEDURE [REAL_64, REAL_64]
			-- Drag at canvas-relative (x, y).

	menu_provider: detachable FUNCTION [REAL_64, REAL_64, detachable SW_MENU]
			-- Builds the right-click menu for canvas-relative (x, y).

feature -- Element change

	set_on_paint (a_agent: PROCEDURE [SW_PAINTER, REAL_64, REAL_64, REAL_64, REAL_64])
		do
			on_paint := a_agent
		ensure
			set: on_paint = a_agent
		end

	set_on_press (a_agent: PROCEDURE [REAL_64, REAL_64])
		do
			on_press := a_agent
		ensure
			set: on_press = a_agent
		end

	set_on_sweep (a_agent: PROCEDURE [REAL_64, REAL_64])
		do
			on_sweep := a_agent
		ensure
			set: on_sweep = a_agent
		end

	set_menu_provider (a_agent: FUNCTION [REAL_64, REAL_64, detachable SW_MENU])
		do
			menu_provider := a_agent
		ensure
			set: menu_provider = a_agent
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := canvas_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.push_clip (x, y, width, height)
			if attached on_paint as pa then
				pa.call (a_p, x, y, width, height)
			end
			a_p.pop_clip
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if attached on_press as pr then
					pr.call (a_px - x, a_py - y)
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if attached on_sweep as sw then
				sw.call (a_px - x, a_py - y)
			end
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
		do
			if attached menu_provider as mp then
				Result := mp.item ([a_px - x, a_py - y])
			end
		end

invariant
	height_positive: canvas_height > 0.0

end
