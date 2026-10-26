note
	description: "[
		GW-22: one widget tree in a floating window of its own - a framed
		simple_shell panel (caption, sizing border, the focus when clicked)
		owned by an SW_WINDOW, for a study pane torn off onto a second
		monitor. It draws in the owner's theme and shaping kit and takes the
		pointer and the keyboard as the owner does (SW_POINTER_ROUTING); a
		key the owner's accelerator table claims (Ctrl+W, F5) still runs it.
		Every handled input goes through the owner's one itinerary, so the
		main window and every floating window repaint together.

		The owner routes the panel's events here by slot (`handle_event').
		While the owner shows a modal dialog, input here is ignored. Not
		yet: popups, sheets and hover cards inside a floating window, a
		per-widget pointer shape, publishing to screen readers.
	]"

class
	SW_FLOATING_WINDOW

inherit
	SW_POINTER_ROUTING

	SHELL_EVENTS
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (a_owner: SW_WINDOW; a_content: SW_WIDGET; a_title: READABLE_STRING_GENERAL; a_x, a_y, a_width, a_height: INTEGER)
			-- A floating window titled `a_title' around `a_content', hidden,
			-- at the given outer geometry. Stays closed when no panel slot is
			-- free.
		require
			content_free: a_content.parent = Void
			sane_size: a_width > 0 and a_height > 0
		do
			owner := a_owner
			content := a_content
			create panel.make
			panel.open_framed (a_x, a_y, a_width, a_height, a_title)
			create cairo.make
			if panel.is_open then
				client_width := panel.client_width.max (1)
				client_height := panel.client_height.max (1)
			else
				client_width := 1
				client_height := 1
			end
			alloc_w := ((client_width // 256) + 1) * 256
			alloc_h := ((client_height // 256) + 1) * 256
			offscreen := cairo.create_surface (alloc_w, alloc_h)
			create ctx.make (offscreen)
			create painter.make (ctx, a_owner.theme)
			painter.set_shaping (a_owner.shaping)
		ensure
			owned: owner = a_owner
			holding: content = a_content
			framed_when_open: is_open implies panel.is_framed
		end

feature -- Access

	owner: SW_WINDOW
			-- The window this one floats above.

	content: SW_WIDGET
			-- The tree it shows.

	panel: SHELL_PANEL
			-- The framed native window.

	is_open: BOOLEAN
			-- Is the native window there?
		do
			Result := panel.is_open
		end

	slot: INTEGER
			-- The panel slot its events carry.
		do
			Result := panel.slot
		end

	client_width, client_height: INTEGER
			-- The drawable size, as last told.

	focused: detachable SW_WIDGET
			-- The widget the keyboard reaches.

	hovered: detachable SW_WIDGET
			-- The widget under the pointer.

	is_active: BOOLEAN
			-- Does the floating window have the focus?

	render_count: INTEGER
			-- Frames drawn.

	on_close_request: detachable PROCEDURE
			-- Run when the user asks the window to close (its close box, Alt+F4).

feature -- Element change

	set_on_close_request (a_action: PROCEDURE)
		do
			on_close_request := a_action
		ensure
			set: on_close_request = a_action
		end

	show
			-- Put it on screen where it was opened, without taking the focus.
		require
			open: is_open
		do
			panel.show (panel.x, panel.y, panel.width, panel.height)
			render
			blit
		ensure
			shown: panel.is_visible
		end

	close
			-- Destroy the native window; `content' is left for its next home.
		do
			if panel.is_open then
				panel.close
			end
			if attached focused as al_f then
				al_f.set_focused (False)
			end
			if attached hovered as al_h then
				al_h.set_hovered (False)
			end
			focused := Void
			hovered := Void
			capture := Void
		ensure
			closed: not is_open
		end

feature -- Input

	handle_event (a_type, a_x, a_y: INTEGER)
			-- One event of this window's panel.
		require
			open: is_open
		do
			if a_type = Event_panel_expose then
				blit
			elseif a_type = Event_panel_resized then
				resize (a_x, a_y)
				owner.after_floating_input
			elseif a_type = Event_panel_close_request then
				if attached on_close_request as al_close then
					al_close.call
				end
			elseif a_type = Event_panel_activated then
				is_active := a_x = 1
			elseif owner.dialog = Void then
					-- a modal dialog in the owner holds every window
				handle_input (a_type, a_x, a_y)
			end
		end

feature -- Drawing

	render
			-- Lay `content' out over the client area, inside the theme's
			-- padding, and draw it.
		local
			l_inset: REAL_64
		do
			if painter.theme /= owner.theme then
				create painter.make (ctx, owner.theme)
			end
			painter.set_shaping (owner.shaping)
			painter.set_color (owner.theme.background)
			ctx.paint.do_nothing
			l_inset := content_inset
			content.set_bounds (l_inset, l_inset, (client_width - 2.0 * l_inset).max (0.0), (client_height - 2.0 * l_inset).max (0.0))
			content.arrange (painter)
			content.draw (painter)
			render_count := render_count + 1
		ensure
			counted: render_count = old render_count + 1
		end

	content_inset: REAL_64
			-- The margin round `content': the theme's padding.
		do
			Result := owner.theme.padding
		end

	blit
			-- Copy the frame to the panel.
		local
			l_dc: POINTER
			l_target: CAIRO_SURFACE
			l_copy: CAIRO_CONTEXT
		do
			if panel.is_open then
				l_dc := panel.dc
				if l_dc /= default_pointer then
					create l_target.make_for_dc (l_dc)
					if l_target.is_valid then
						create l_copy.make (l_target)
						l_copy.set_source_surface (offscreen, 0.0, 0.0).paint.do_nothing
						l_copy.destroy
					end
					l_target.destroy
					panel.release_dc (l_dc)
				end
			end
		end

	export_frame_png (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Write the last frame's client area to `a_path' as a PNG. True
			-- when the file was written.
		require
			path_given: not a_path.is_empty
		local
			l_image: CAIRO_SURFACE
			l_copy: CAIRO_CONTEXT
		do
			l_image := cairo.create_surface (client_width, client_height)
			create l_copy.make (l_image)
			l_copy.set_source_surface (offscreen, 0.0, 0.0).paint.do_nothing
			l_copy.destroy
			Result := l_image.write_png (a_path.to_string_32)
			l_image.destroy
		end

feature {NONE} -- Input internals

	handle_input (a_type, a_x, a_y: INTEGER)
		local
			l_keys: SW_KEYS
			l_code: INTEGER
			l_taker: detachable SW_WIDGET
		do
			if a_type = Event_panel_press then
				last_x := a_x
				last_y := a_y
				if attached content.widget_at (a_x, a_y) as al_target then
					if al_target.accepts_focus and then al_target /= focused then
						move_focus (al_target)
					end
					capture := spine_click (al_target, a_x, a_y, False)
					if attached capture as al_c then
						al_c.set_pressed (True)
					end
				end
				owner.after_floating_input
			elseif a_type = Event_panel_double then
				if attached content.widget_at (a_x, a_y) as al_target then
					l_taker := spine_click (al_target, a_x, a_y, True)
				end
				owner.after_floating_input
			elseif a_type = Event_panel_move then
				last_x := a_x
				last_y := a_y
				if attached capture as al_c then
						-- the pointer belongs to whoever accepted the press
					al_c.handle_drag (a_x, a_y)
					owner.after_floating_input
				else
					update_hover (a_x, a_y)
				end
			elseif a_type = Event_panel_release then
				if attached capture as al_c then
					if al_c.is_pressed then
						al_c.set_pressed (False)
					end
					al_c.handle_release (a_x, a_y)
					capture := Void
					owner.after_floating_input
				end
			elseif a_type = Event_panel_wheel then
				if attached content.widget_at (last_x, last_y) as al_target then
					spine_wheel (al_target, a_x)
					owner.after_floating_input
				end
			elseif a_type = Event_panel_leave then
				if attached hovered as al_h then
					al_h.set_hovered (False)
					hovered := Void
					owner.after_floating_input
				end
			elseif a_type = Event_panel_key then
				create l_keys
				if owner.fire_accelerator (a_x, l_keys.control_down, l_keys.alt_down, l_keys.shift_down) then
					owner.after_floating_input
				elseif attached focused as al_f then
					al_f.handle_key (a_x, l_keys.shift_down)
					owner.after_floating_input
				end
			elseif a_type = Event_panel_char then
				l_code := paired_code_point (a_x)
				if l_code < 0 then
						-- the high half of a pair: the low half follows
				elseif l_code = 9 and then not (attached focused as al_tf and then al_tf.wants_tab) then
					create l_keys
					step_focus (if l_keys.shift_down then -1 else 1 end)
					owner.after_floating_input
				elseif l_code < 32 and then l_code /= 8 and then l_code /= 13 and then l_code /= 27
					and then owner.claims_char_accelerator (l_code)
				then
						-- Ctrl+letter arrives as a control code: the owner's table
					owner.after_floating_input
				elseif attached focused as al_f then
					al_f.handle_char (l_code)
					owner.after_floating_input
				end
			end
		end

	move_focus (a_to: detachable SW_WIDGET)
		do
			if attached focused as al_prev then
				al_prev.set_focused (False)
			end
			focused := a_to
			if attached a_to as al_to then
				al_to.set_focused (True)
			end
		ensure
			moved: focused = a_to
		end

	step_focus (a_dir: INTEGER)
			-- Tab within this window's tree.
		require
			unit_step: a_dir = 1 or a_dir = -1
		local
			l_ring: ARRAYED_LIST [SW_WIDGET]
		do
			create l_ring.make (8)
			content.focusables (l_ring)
			if not l_ring.is_empty then
				move_focus (ring_neighbour (l_ring, focused, a_dir))
			end
		end

	update_hover (a_x, a_y: INTEGER)
		local
			w: detachable SW_WIDGET
		do
			w := content.widget_at (a_x, a_y)
			if attached w as al_w then
				al_w.set_hover_point (a_x, a_y)
			end
			if w /= hovered then
				if attached hovered as al_h then
					al_h.set_hovered (False)
				end
				hovered := w
				if attached w as al_w then
					al_w.set_hovered (True)
				end
				owner.after_floating_input
			elseif attached w as al_w and then al_w.wants_hover_point then
				owner.after_floating_input
			end
		end

	resize (a_w, a_h: INTEGER)
			-- The client area is now `a_w' x `a_h'; a NEW offscreen only when
			-- it outgrows the allocation, in 256-pixel steps.
		do
			if a_w > 0 and a_h > 0 then
				client_width := a_w
				client_height := a_h
				if a_w > alloc_w or a_h > alloc_h then
					alloc_w := ((a_w // 256) + 1) * 256
					alloc_h := ((a_h // 256) + 1) * 256
					ctx.destroy
					offscreen.destroy
					offscreen := cairo.create_surface (alloc_w, alloc_h)
					create ctx.make (offscreen)
					create painter.make (ctx, owner.theme)
					painter.set_shaping (owner.shaping)
				end
			end
		ensure
			fits: client_width <= alloc_w and client_height <= alloc_h
		end

feature {NONE} -- State

	capture: detachable SW_WIDGET
			-- The widget that took the press.

	last_x, last_y: INTEGER
			-- Where the pointer last was.

	cairo: SIMPLE_CAIRO
	offscreen: CAIRO_SURFACE
	ctx: CAIRO_CONTEXT
	painter: SW_PAINTER
	alloc_w, alloc_h: INTEGER

invariant
	fits: client_width <= alloc_w and client_height <= alloc_h

end
