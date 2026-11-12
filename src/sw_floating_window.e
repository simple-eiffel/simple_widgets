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
		While the owner shows a modal dialog, input here is ignored. Popups
		open here too (1c): a menu bar's drop-downs and a widget's context
		menu, drawn over the content and owning the pointer and the keys until
		they close. It publishes its own widget tree to screen readers, served
		under its own native window (SW_ACCESSIBLE_TREE, simple_shell#48).
		Not yet: sheets and hover cards inside a floating window, a
		per-widget pointer shape, a popup menu's items in the published tree.
	]"

class
	SW_FLOATING_WINDOW

inherit
	SW_POINTER_ROUTING

	SW_ACCESSIBLE_TREE

	SHELL_EVENTS
		export
			{NONE} all
		end

create
	make, make_document

feature {NONE} -- Initialization

	make_document (a_owner: SW_WINDOW; a_content: SW_WIDGET; a_title: READABLE_STRING_GENERAL; a_x, a_y, a_width, a_height: INTEGER)
			-- As `make', but a DOCUMENT window (simple_shell's open_document, W3): its own taskbar
			-- button and Alt+Tab entry, minimize and maximize boxes, no owner - simple_gui's second
			-- and later windows.
		require
			content_free: a_content.parent = Void
			sane_size: a_width > 0 and a_height > 0
		do
			is_document := True
			make (a_owner, a_content, a_title, a_x, a_y, a_width, a_height)
		ensure
			document: is_document
		end

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
			if is_document then
				panel.open_document (a_x, a_y, a_width, a_height, a_title)
			else
				panel.open_framed (a_x, a_y, a_width, a_height, a_title)
			end
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

	is_frame_released: BOOLEAN
			-- Has the offscreen frame been given back (after `close')?
		do
			Result := not offscreen.is_valid
		end

	is_document: BOOLEAN
			-- Was it opened as a document window (`make_document')?

	on_close_request: detachable PROCEDURE
			-- Run when the user asks the window to close (its close box, Alt+F4).

feature -- Element change

	give_focus (a_w: SW_WIDGET)
			-- Hand the keyboard focus to `a_w', as SW_WINDOW's `give_focus' does: the
			-- programmatic twin of the click-to-focus path, so keys reach `a_w' before any
			-- pointer lands (a print preview's canvas takes Escape and Page Up as it opens).
		require
			focusable: a_w.accepts_focus
		do
			move_focus (a_w)
		ensure
			holds: focused = a_w
		end

	set_on_close_request (a_action: PROCEDURE)
		do
			on_close_request := a_action
		ensure
			set: on_close_request = a_action
		end

	handle_accessibility_request (a_type, a_x: INTEGER)
			-- A UI Automation client's request for this window (simple_shell#48):
			-- to move the focus to node `a_x' (event 58; never while a popup is
			-- open), or for the tree (event 59).
		require
			open: is_open
		do
			if a_type = Event_focus_request then
				if popup = Void and then attached accessible_widget_with_id (a_x) as al_target
					and then al_target.accepts_focus and then al_target.is_enabled
				then
					give_focus (al_target)
					owner.after_floating_input
				end
			elseif a_type = Event_refresh_request and then is_accessible then
				publish_accessibility
			end
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
				-- screen readers stop seeing it first (#48)
			accessibility.disable
			accessible_widgets.wipe_out
			if panel.is_open then
				panel.close
			end
			if attached focused as al_f then
				al_f.set_focused (False)
			end
			if attached hovered as al_h then
				al_h.set_hovered (False)
			end
			if attached capture as al_c and then al_c.is_pressed then
				al_c.set_pressed (False)
			end
			focused := Void
			hovered := Void
			capture := Void
			if offscreen.is_valid then
					-- scan 19: every float/unfloat leaked a client-sized frame
				ctx.destroy
				offscreen.destroy
			end
		ensure
			closed: not is_open
			released: is_frame_released
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

feature -- Popups (1c)

	popup: detachable SW_MENU
			-- The menu open in this window - a menu bar's drop-down or a
			-- context menu - drawn over the content; it owns the pointer and
			-- the keys until it closes.

	popup_bar: detachable SW_MENU_BAR
			-- The menu bar `popup' dropped from, so Left and Right step along it.

	show_popup (a_m: SW_MENU; a_x, a_y: INTEGER)
			-- Open `a_m' at (`a_x', `a_y'), kept inside the client area.
		require
			open: is_open
		do
			a_m.measure (painter)
			a_m.place (a_x, a_y, client_width, client_height)
			popup := a_m
		ensure
			shown: popup = a_m
		end

	close_popup
			-- Close `popup' (nothing happens when none is open).
		do
			popup := Void
			popup_bar := Void
		ensure
			closed: popup = Void and popup_bar = Void
		end

feature -- Drawing

	render
			-- Lay `content' out over the client area, inside the theme's
			-- padding, and draw it.
		require
			open: is_open
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
			if attached popup as al_m then
				al_m.draw (painter)
			end
			render_count := render_count + 1
				-- screen readers (#48): as the main window does, publish when
				-- first drawn, when the window changed, and on frames while a
				-- client listens; otherwise the tree is marked stale
			if is_accessible then
				if not is_accessibility_published or else accessibility.served_window /= panel.handle
					or else accessibility.clients_listening
				then
					publish_accessibility
				else
					accessibility_is_stale := True
					tell_accessible_focus
				end
			end
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
			open: is_open
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

feature {NONE} -- What it publishes (simple_shell#48)

	is_accessible: BOOLEAN
			-- As its owner: on unless the program turned it off.
		do
			Result := owner.is_accessible
		end

	accessible_roots: ARRAYED_LIST [SW_WIDGET]
			-- Its content.
		do
			create Result.make (1)
			Result.extend (content)
		end

	accessible_title: READABLE_STRING_GENERAL
			-- Its title.
		do
			Result := panel.title
		end

	accessible_width: REAL_64
		do
			Result := client_width
		end

	accessible_height: REAL_64
		do
			Result := client_height
		end

	accessible_window_handle: POINTER
			-- Its own native window.
		do
			if panel.is_open then
				Result := panel.handle
			end
		end

feature {NONE} -- Input internals

	handle_input (a_type, a_x, a_y: INTEGER)
		local
			l_keys: SW_KEYS
			l_code: INTEGER
			l_taker: detachable SW_WIDGET
			l_swallow: BOOLEAN
		do
			if attached popup as al_m then
				handle_popup_input (al_m, a_type, a_x, a_y)
			elseif a_type = Event_panel_press then
				last_x := a_x
				last_y := a_y
				if attached content.widget_at (a_x, a_y) as al_target then
					if al_target.accepts_focus and then al_target /= focused then
						move_focus (al_target)
					end
					capture := spine_click (al_target, a_x, a_y, False)
					if attached capture as al_c then
						al_c.set_pressed (True)
						if attached al_c.take_pending_menu as al_pm then
								-- a menu bar's pad, or any widget that drops a menu
							show_popup (al_pm, al_c.menu_left.truncated_to_integer, (al_c.y + al_c.height + 2.0).truncated_to_integer)
							if attached {SW_MENU_BAR} al_c as al_bar then
								popup_bar := al_bar
							end
						end
					end
				end
				owner.after_floating_input
			elseif a_type = Event_panel_right_press then
				if attached content.widget_at (a_x, a_y) as al_target then
					offer_context_menu (al_target, a_x, a_y)
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
				release_capture (a_x, a_y)
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
					-- a new key down: whatever the last one armed is stale
				swallow_next_char := False
				if owner.fire_accelerator (a_x, l_keys.control_down, l_keys.alt_down, l_keys.shift_down) then
						-- scan 19: the WM_CHAR behind it is the same keystroke
					swallow_next_char := True
					owner.after_floating_input
				elseif attached focused as al_f then
					al_f.handle_key (a_x, l_keys.shift_down)
					owner.after_floating_input
				end
			elseif a_type = Event_panel_char then
				l_swallow := swallow_next_char and a_x < 32
				swallow_next_char := False
				l_code := paired_code_point (a_x)
				if l_code < 0 then
						-- the high half of a pair: the low half follows
				elseif l_swallow then
						-- the key down half of this gesture ran the accelerator
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

	release_capture (a_x, a_y: INTEGER)
			-- The pointer let go: whoever took the press gets the release.
		do
			if attached capture as al_c then
				if al_c.is_pressed then
					al_c.set_pressed (False)
				end
				al_c.handle_release (a_x, a_y)
				capture := Void
				owner.after_floating_input
			end
		ensure
			released: capture = Void
		end

	handle_popup_input (a_m: SW_MENU; a_type, a_x, a_y: INTEGER)
			-- While `popup' is open it owns the pointer and the keys, as the
			-- owner's popup does: a press picks an item or closes it, the
			-- pointer moves the highlight, the arrows, Home, End and Enter walk
			-- it, Escape closes it, a letter picks the item it underlines, and
			-- Left and Right step to the menu bar's neighbors.
		require
			open: popup = a_m
		local
			idx: INTEGER
			act: detachable PROCEDURE
		do
			inspect a_type
			when Event_panel_press, Event_panel_right_press then
				idx := a_m.item_at (a_x, a_y)
				if idx > 0 and then a_type = Event_panel_press then
					act := a_m.items.i_th (idx).action
				end
				close_popup
				if attached act as al_act then
					al_act.call
				end
				owner.after_floating_input
			when Event_panel_release then
					-- the press that opened the popup ends here
				release_capture (a_x, a_y)
			when Event_panel_move then
				a_m.set_hover_at (a_x, a_y)
				owner.after_floating_input
			when Event_panel_key then
				inspect a_x
				when 40 then -- DOWN
					a_m.hover_next
				when 38 then -- UP
					a_m.hover_previous
				when 36 then -- HOME
					a_m.hover_first
				when 35 then -- END
					a_m.hover_last
				when 13 then -- ENTER
					act := a_m.hovered_action
					close_popup
					if attached act as al_act then
						al_act.call
					end
				when 39 then -- RIGHT
					step_popup_bar (1)
				when 37 then -- LEFT
					step_popup_bar (-1)
				else
				end
				owner.after_floating_input
			when Event_panel_char then
				if a_x = 27 then
					close_popup
				elseif a_x > 32 then
					idx := a_m.item_for_mnemonic (a_x.to_character_32)
					if idx > 0 then
						act := a_m.items.i_th (idx).action
						close_popup
						if attached act as al_act then
							al_act.call
						end
					end
				end
				owner.after_floating_input
			else
			end
		end

	step_popup_bar (a_step: INTEGER)
			-- Left or Right with a drop-down open: open the neighboring pad's
			-- menu instead, by screen position when the bar is mirrored.
		require
			stepping: a_step = 1 or a_step = -1
		local
			idx: INTEGER
		do
			if attached popup_bar as al_bar and then al_bar.is_enabled then
				if al_bar.mirrors_layout then
					idx := al_bar.neighbor_pad (al_bar.last_opened_pad, - a_step)
				else
					idx := al_bar.neighbor_pad (al_bar.last_opened_pad, a_step)
				end
				if idx > 0 then
					close_popup
					al_bar.open_menu (painter, idx)
					if attached al_bar.take_pending_menu as al_pm then
						show_popup (al_pm, al_bar.pad_bounds (painter, idx).left.truncated_to_integer, (al_bar.y + al_bar.height + 2.0).truncated_to_integer)
						popup_bar := al_bar
					end
				end
			end
		end

	offer_context_menu (a_target: SW_WIDGET; a_x, a_y: INTEGER)
			-- A right press: ask the target, then its ancestors, for a menu, and
			-- open the first one offered (focusing its widget, as the owner does).
		local
			w: detachable SW_WIDGET
			l_handled: BOOLEAN
		do
			from
				w := a_target
			until
				l_handled or w = Void
			loop
				if w.is_enabled then
					if attached w.offered_menu (a_x, a_y) as al_m then
						if w.accepts_focus and then w /= focused then
							move_focus (w)
						end
						show_popup (al_m, a_x, a_y)
						l_handled := True
					else
						l_handled := w.handle_context (a_x, a_y)
					end
				end
				if not l_handled then
					w := w.parent
				end
			end
		end

	after_edit
			-- An Edit command changed the focused widget: the owner's itinerary repaints.
		do
			owner.after_floating_input
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
				move_focus (ring_neighbor (l_ring, focused, a_dir))
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

	swallow_next_char: BOOLEAN
			-- Did the last key down run an accelerator, so the control code
			-- its WM_CHAR carries is the same keystroke?

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
