note
	description: "[
		The runtime. Owns the native window, the message pump, the
		offscreen surface, the painter, keyboard focus and event
		dispatch - everything an application should never have to
		declare. An application creates a window, hands it a root
		widget, and calls `run'.

		All prints are forbidden here and in every client: the Eiffel
		runtime allocates a console on the first console write in a
		GUI-subsystem program. `log_line' writes to the session log
		instead.
	]"

class
	SW_WINDOW

create
	make

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_GENERAL; a_x, a_y, a_w, a_h: INTEGER; a_theme: SW_THEME)
		require
			sane_size: a_w > 0 and a_h > 0
		do
			create title.make_from_string_general (a_title)
			win_x := a_x
			win_y := a_y
			win_w := a_w
			win_h := a_h
			theme := a_theme
			create cairo.make
			create ev_buf.make (16)
			create frame_echo_path.make_empty
			create drawer_tabs.make (2)
			create tab_rects.make (2)
			alloc_w := win_w
			alloc_h := win_h
			offscreen := cairo.create_surface (alloc_w, alloc_h)
			create ctx.make (offscreen)
			create painter.make (ctx, theme)
		ensure
			theme_kept: theme = a_theme
		end

feature -- Access

	title: STRING_32
	theme: SW_THEME
	root: detachable SW_WIDGET
	focused: detachable SW_WIDGET
	win_x, win_y, win_w, win_h: INTEGER

	painter: SW_PAINTER
			-- The drawing kit, exposed for measurement before `run'.

feature -- Element change

	set_root (a_root: SW_WIDGET)
		do
			root := a_root
		ensure
			set: root = a_root
		end

	set_theme (a_theme: SW_THEME)
			-- Swap the token set live; the next render wears it.
		do
			theme := a_theme
			create painter.make (ctx, a_theme)
		ensure
			swapped: theme = a_theme
		end

	set_frame_echo (a_path: READABLE_STRING_GENERAL)
			-- After every render, also write the frame to `a_path' -
			-- the testing hook that lets a harness see the pixels.
		do
			create frame_echo_path.make_from_string_general (a_path)
		end

feature -- Fonts

	add_font (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Load a TTF for this process only (FR_PRIVATE); its family
			-- name becomes selectable. False when the file is missing
			-- or rejected.
		local
			s8: STRING_8
			cs: C_STRING
		do
			s8 := a_path.to_string_8
			create cs.make (s8)
			Result := c_add_font (cs.item) > 0
		end

feature -- Log

	log_line (a_s: READABLE_STRING_GENERAL)
		local
			f: PLAIN_TEXT_FILE
		do
			create f.make_with_name (log_name)
			if f.exists then
				f.open_append
			else
				f.open_write
			end
			if f.is_open_write then
				f.put_string (a_s.to_string_32.to_string_8)
				f.put_new_line
				f.close
			end
		end

	log_name: STRING_32
		once
			create Result.make_from_string_general ("sw_session.log")
		end

feature -- Operation

	run
			-- Show the window and pump until it closes.
		local
			ns: NATIVE_STRING
			quit: BOOLEAN
			ev: INTEGER
		do
			render
			create ns.make (title)
			hwnd := c_create_window (ns.item, win_x, win_y, win_w, win_h)
			if hwnd = default_pointer then
				log_line ("sw: window creation FAILED")
			else
				log_line ("sw: window up")
				from
				until
					quit
				loop
					if c_pump = 0 then
						quit := True
					end
					from
						ev := c_next_event (ev_buf.item)
					until
						ev = 0
					loop
						dispatch (ev, ev_buf.read_integer_32 (4), ev_buf.read_integer_32 (8))
						ev := c_next_event (ev_buf.item)
					end
				end
			end
			log_line ("sw: window closed")
		end

	request_render
			-- Redraw now: for state changed outside an input event.
		do
			render
			blit
		end

	write_frame (a_path: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := offscreen.write_png (a_path.to_string_32)
		end

feature {NONE} -- Dispatch

	dispatch (a_type, a_x, a_y: INTEGER)
		do
			if a_type = 7 then
					-- The heartbeat is global: toasts age and the frame
					-- echo flushes no matter which phase owns the pointer.
					-- A popup must never freeze the window's clock.
				age_toasts
			elseif a_type = 16 then
					-- Likewise the surface: a resize that arrives while a
					-- dialog or popup is open must still reallocate.
				resize_surface (a_x, a_y)
			end
			if attached dialog as d then
				dispatch_to_dialog (d, a_type, a_x, a_y)
			elseif attached popup as m then
				dispatch_to_popup (m, a_type, a_x, a_y)
			else
				dispatch_normal (a_type, a_x, a_y)
			end
		end

	dispatch_to_dialog (a_d: SW_DIALOG; a_type, a_x, a_y: INTEGER)
			-- Modality: only the dialog's buttons and Escape act;
			-- everything else is swallowed.
		local
			idx: INTEGER
			act: detachable PROCEDURE
		do
			inspect a_type
			when 2 then
				idx := a_d.button_at (a_x, a_y)
				if idx > 0 then
					act := a_d.buttons.i_th (idx).action
					close_dialog
					if attached act as a then
						a.call
					end
					after_input
				end
			when 3 then
				if a_x = 27 then
					close_dialog
					after_input
				end
			when 6 then
				blit
			else
			end
		end

feature -- Dialogs

	show_dialog (a_d: SW_DIALOG)
		do
			a_d.measure (painter, win_w, win_h)
			dialog := a_d
			after_input
		ensure
			shown: dialog = a_d
		end

	close_dialog
		do
			dialog := Void
		ensure
			closed: dialog = Void
		end

feature {NONE} -- Dispatch internals

	dispatch_to_popup (a_m: SW_MENU; a_type, a_x, a_y: INTEGER)
			-- While a popup is up it owns the pointer and Escape;
			-- everything else is swallowed until it closes.
		local
			idx: INTEGER
			act: detachable PROCEDURE
		do
			inspect a_type
			when 2 then
				idx := a_m.item_at (a_x, a_y)
				if idx > 0 then
					act := a_m.items.i_th (idx).action
				end
				close_popup
				if attached act as a then
					a.call
				end
				after_input
			when 13 then
				a_m.set_hover_at (a_x, a_y)
				after_input
			when 3 then
				if a_x = 27 then
					close_popup
					after_input
				end
			when 6 then
				blit
			when 11 then
				close_popup
				after_input
			else
			end
		end

	show_popup (a_m: SW_MENU; a_x, a_y: INTEGER)
		do
			a_m.measure (painter)
			a_m.place (a_x, a_y, win_w, win_h)
			popup := a_m
		ensure
			shown: popup = a_m
		end

feature -- Sheets

	Mode_center: INTEGER = 0
	Mode_left: INTEGER = 1
	Mode_right: INTEGER = 2
	Mode_anchored: INTEGER = 3

	show_sheet (a_content: SW_WIDGET; a_width: REAL_64)
			-- Present `a_content' modally, centered on a dimmed
			-- backdrop: the sheet becomes the input root until
			-- closed. Popups still open above it. Outside clicks are
			-- ignored - centered sheets are truly modal.
		require
			positive: a_width > 0.0
		do
			present (a_content, a_width, Mode_center, 0.0, 0.0)
		ensure
			shown: sheet = a_content
		end

	show_drawer (a_content: SW_WIDGET; a_width: REAL_64; a_from_right: BOOLEAN)
			-- Present `a_content' as a full-height edge panel on a
			-- lightly dimmed backdrop. A click outside the panel (or
			-- Escape) closes it - drawers are dismissable by nature.
		require
			positive: a_width > 0.0
		do
			if a_from_right then
				present (a_content, a_width, Mode_right, 0.0, 0.0)
			else
				present (a_content, a_width, Mode_left, 0.0, 0.0)
			end
		ensure
			shown: sheet = a_content
		end

	show_popover (a_content: SW_WIDGET; a_x, a_y, a_width: REAL_64)
			-- Present `a_content' as a light anchored panel at
			-- (a_x, a_y) - no backdrop, outside click or Escape
			-- closes. The anchored cousin of a menu, hosting any
			-- widget tree.
		require
			positive: a_width > 0.0
		do
			present (a_content, a_width, Mode_anchored, a_x, a_y)
		ensure
			shown: sheet = a_content
		end

	close_sheet
			-- Close whatever overlay is up - sheet, drawer, popover.
		do
			sheet := Void
			if attached focused as f then
				f.set_focused (False)
			end
			focused := Void
		ensure
			closed: sheet = Void
		end

feature {NONE} -- Popup lifecycle

	close_popup
		do
			popup := Void
		ensure
			closed: popup = Void
		end

	dispatch_normal (a_type, a_x, a_y: INTEGER)
		do
			if pick_pebble /= Void then
				dispatch_in_pick (a_type, a_x, a_y)
			else
				dispatch_plain (a_type, a_x, a_y)
			end
		end

	dispatch_in_pick (a_type, a_x, a_y: INTEGER)
			-- Pick-and-drop mode: the pointer carries a pebble. A left
			-- click on a welcoming hole drops it; right-click, Escape
			-- or a click anywhere else cancels; moves redraw the
			-- trajectory.
		local
			w: detachable SW_WIDGET
		do
			inspect a_type
			when 2 then
				if attached pick_pebble as pb then
					if attached active_root as r then
						w := r.widget_at (a_x, a_y)
					end
					if attached w as tw and then tw.is_enabled and then tw.accepts_pebble (pb) then
						end_pick
						tw.receive_pebble (pb)
					else
						end_pick
					end
				end
				after_input
			when 13 then
				pick_cur_x := a_x
				pick_cur_y := a_y
				after_input
			when 3 then
				if a_x = 27 then
					end_pick
					after_input
				end
			when 11 then
				end_pick
				after_input
			when 6 then
				blit
			else
			end
		end

	begin_pick (a_pebble: ANY; a_x, a_y: INTEGER)
		do
			pick_pebble := a_pebble
			pick_x := a_x
			pick_y := a_y
			pick_cur_x := a_x
			pick_cur_y := a_y
		ensure
			picking: pick_pebble = a_pebble
		end

	end_pick
		do
			pick_pebble := Void
		ensure
			idle: pick_pebble = Void
		end

	dispatch_plain (a_type, a_x, a_y: INTEGER)
		do
			inspect a_type
			when 2 then
				if attached active_root as r and then attached r.widget_at (a_x, a_y) as w then
					if w.accepts_focus and then w /= focused then
						if attached focused as prev then
							prev.set_focused (False)
						end
						focused := w
						w.set_focused (True)
					end
					capture := bubble_click (w, a_x, a_y, False)
				elseif sheet = Void and then drawer_tab_at (a_x, a_y) > 0 then
					open_drawer_from_tab (drawer_tab_at (a_x, a_y), True)
				elseif sheet /= Void and then sheet_mode /= Mode_center
					and then not point_in_sheet_panel (a_x, a_y)
				then
						-- drawers and popovers dismiss on outside click;
						-- centered sheets are truly modal and ignore it
					close_sheet
				end
				if sheet /= Void and then not drawer_pinned
					and then (sheet_mode = Mode_left or sheet_mode = Mode_right)
					and then point_in_sheet_panel (a_x, a_y)
				then
						-- interacting with a peeked drawer pins it: it
						-- must not vanish mid-use
					drawer_pinned := True
				end
				after_input
			when 3 then
					-- UTF-16 arrives in units; astral characters come as a
					-- surrogate pair across two WM_CHARs. Pair them here so
					-- widgets only ever see whole code points (R8).
				if a_x >= 0xD800 and a_x <= 0xDBFF then
					pending_surrogate := a_x
				elseif a_x >= 0xDC00 and a_x <= 0xDFFF and pending_surrogate /= 0 then
					if attached focused as w then
						w.handle_char (0x10000 + (pending_surrogate - 0xD800) * 0x400 + (a_x - 0xDC00))
						after_input
					end
					pending_surrogate := 0
				else
					pending_surrogate := 0
					if a_x = 27 and then sheet /= Void and then focused = Void then
						close_sheet
						after_input
					elseif attached focused as w then
						w.handle_char (a_x)
						after_input
					end
				end
			when 4 then
				if attached focused as w then
					w.handle_key (a_x, c_shift_down = 1)
					after_input
				end
			when 6 then
				blit
			when 8 then
				if attached active_root as r and then attached r.widget_at (a_x, a_y) as w then
					capture := bubble_click (w, a_x, a_y, True)
				end
				after_input
			when 9 then
					-- the pointer belongs to whoever accepted the press,
					-- not to the keyboard focus (every surveyed toolkit
					-- agrees: Qt's grabber, ImGui's active id)
				if attached capture as w then
					w.handle_drag (a_x, a_y)
					after_input
				end
			when 10 then
				if attached capture as cw then
					if cw.is_pressed then
						cw.set_pressed (False)
					end
					capture := Void
					after_input
				end
			when 7 then
				if attached hovered as hw and then not hw.tooltip.is_empty
					and then not tooltip_visible
				then
					dwell_ticks := dwell_ticks + 1
					if dwell_ticks >= 1 then
						tooltip_visible := True
						after_input
					end
				end
			when 13 then
				if sheet = Void and then drawer_tab_at (a_x, a_y) > 0 then
					open_drawer_from_tab (drawer_tab_at (a_x, a_y), False)
				elseif sheet /= Void and then not drawer_pinned
					and then (sheet_mode = Mode_left or sheet_mode = Mode_right)
					and then not point_in_sheet_panel (a_x, a_y)
					and then drawer_tab_at (a_x, a_y) = 0
				then
					close_sheet
				end
				update_hover (a_x, a_y)
			when 14 then
				if attached hovered as hw then
					hw.set_hovered (False)
					hovered := Void
					after_input
				end
			when 17 then
				if attached active_root as r and then attached r.widget_at (a_x, a_y) as w then
					pick_from (w, a_x, a_y)
				end
				after_input

			when 15 then
				if attached active_root as r and then attached r.widget_at (a_x, a_y) as w then
					bubble_wheel (w, ev_buf.read_integer_32 (12))
				end
				after_input
			when 11 then
				if attached active_root as r and then attached r.widget_at (a_x, a_y) as w then
					bubble_context (w, a_x, a_y)
				end
				after_input
			when 12 then
				if attached active_root as r and then attached r.widget_at (a_x, a_y) as w then
					if w.handle_triple_click (a_x, a_y) then
					end
				end
				after_input
			else
			end
		end

	bubble_context (a_target: SW_WIDGET; a_x, a_y: INTEGER)
			-- Ask the target, then its ancestors, for a declared menu;
			-- present the first one offered. Falls back to the
			-- handle_context hook for non-menu reactions.
		local
			w: detachable SW_WIDGET
			handled: BOOLEAN
		do
			from
				w := a_target
			until
				handled or w = Void
			loop
				if w.is_enabled then
					if attached w.context_menu (a_x, a_y) as m then
							-- a right-click focuses its target, as every
							-- editor does - the menu actions act on state
							-- the widget will then also DRAW (selection is
							-- only rendered while focused)
						if w.accepts_focus and then w /= focused then
							if attached focused as prev then
								prev.set_focused (False)
							end
							focused := w
							w.set_focused (True)
						end
						show_popup (m, a_x, a_y)
						handled := True
					else
						handled := w.handle_context (a_x, a_y)
					end
				end
				if not handled then
					w := w.parent
				end
			end
		end

	bubble_click (a_target: SW_WIDGET; a_x, a_y: INTEGER; a_double: BOOLEAN): detachable SW_WIDGET
			-- Offer the click to the target, then up the parent chain
			-- until someone consumes it; the consumer takes the pointer
			-- capture and shows pressed. Disabled widgets are inert and
			-- the click passes through them.
		local
			w: detachable SW_WIDGET
			handled: BOOLEAN
		do
			from
				w := a_target
			until
				handled or w = Void
			loop
				if w.is_enabled then
					if a_double then
						handled := w.handle_double_click (a_x, a_y)
					else
						handled := w.handle_click (a_x, a_y)
					end
				end
				if handled then
					Result := w
				else
					w := w.parent
				end
			end
			if attached Result as cw and then not a_double and then cw.is_enabled then
				cw.set_pressed (True)
				if attached cw.take_pending_menu as pm then
					show_popup (pm, cw.x.truncated_to_integer,
						(cw.y + cw.height + 2.0).truncated_to_integer)
				end
			end
		end

	resize_surface (a_w, a_h: INTEGER)
			-- The user resized the frame: re-layout always; a NEW
			-- offscreen only when the window outgrows the allocation,
			-- and then in 256-pixel steps so a drag reallocates rarely.
		do
			if a_w > 0 and a_h > 0 and (a_w /= win_w or a_h /= win_h) then
				win_w := a_w
				win_h := a_h
				if win_w > alloc_w or win_h > alloc_h then
					alloc_w := ((win_w // 256) + 1) * 256
					alloc_h := ((win_h // 256) + 1) * 256
					ctx.destroy
					offscreen.destroy
					offscreen := cairo.create_surface (alloc_w, alloc_h)
					create ctx.make (offscreen)
					create painter.make (ctx, theme)
				end
				if attached dialog as d then
					d.measure (painter, win_w, win_h)
				end
				after_input
			end
		ensure
			fits: win_w <= alloc_w and win_h <= alloc_h
		end

	pick_from (a_target: SW_WIDGET; a_x, a_y: INTEGER)
			-- Walk the spine for the first widget offering a pebble.
		local
			w: detachable SW_WIDGET
		do
			from
				w := a_target
			until
				pick_pebble /= Void or w = Void
			loop
				if w.is_enabled and then attached w.pebble_at (a_x, a_y) as pb then
					begin_pick (pb, a_x, a_y)
				else
					w := w.parent
				end
			end
		end

	bubble_wheel (a_target: SW_WIDGET; a_delta: INTEGER)
			-- The wheel goes to the widget under the POINTER, then up
			-- the spine - never to keyboard focus.
		local
			w: detachable SW_WIDGET
			handled: BOOLEAN
		do
			from
				w := a_target
			until
				handled or w = Void
			loop
				if w.is_enabled then
					handled := w.handle_wheel (a_delta)
				end
				if not handled then
					w := w.parent
				end
			end
		end

	update_hover (a_x, a_y: INTEGER)
			-- Move the hover state to the widget under the pointer;
			-- re-render only when the target changed.
		local
			w: detachable SW_WIDGET
		do
			if attached active_root as r then
				w := r.widget_at (a_x, a_y)
			end
			if attached w as pw then
				pw.set_hover_point (a_x, a_y)
			end
			if w /= hovered then
				if attached hovered as hw then
					hw.set_hovered (False)
				end
				hovered := w
				if attached w as nw then
					nw.set_hovered (True)
				end
				dwell_ticks := 0
				tooltip_visible := False
				after_input
			elseif attached w as sw and then sw.wants_hover_point then
				after_input
			end
		end

	after_input
		do
			render
			blit
		end

feature {NONE} -- Rendering

	render
		do
			painter.set_color (theme.background)
			ctx.paint.do_nothing
			if attached root as r then
				r.set_bounds (gutter_left, 0.0, win_w - gutter_left - gutter_right, win_h)
				r.arrange (painter)
				r.draw (painter)
			end
			if attached pick_pebble as pb then
				draw_pick_trajectory (pb)
			end
			draw_drawer_gutters
			if attached sheet as s then
				if sheet_mode = Mode_center then
					painter.set_color_alpha (0x000000, 0.45)
					painter.fill_rect (0.0, 0.0, win_w, win_h)
					s.set_bounds ((win_w - sheet_width) / 2.0, 80.0, sheet_width,
						s.preferred_height (painter, sheet_width).min (win_h - 160.0))
					sheet_px := s.x - 16.0
					sheet_py := s.y - 16.0
					sheet_pw := s.width + 32.0
					sheet_ph := s.height + 32.0
					painter.set_color (theme.surface)
					painter.rrect_fill (sheet_px, sheet_py, sheet_pw, sheet_ph, theme.radius + 4.0)
					painter.set_color (theme.outline)
					painter.rrect_stroke (sheet_px + 0.5, sheet_py + 0.5, sheet_pw - 1.0, sheet_ph - 1.0, theme.radius + 4.0)
				elseif sheet_mode = Mode_left or sheet_mode = Mode_right then
					painter.set_color_alpha (0x000000, 0.25)
					painter.fill_rect (0.0, 0.0, win_w, win_h)
					if sheet_mode = Mode_left then
						sheet_px := 0.0
					else
						sheet_px := win_w - sheet_width
					end
					sheet_py := 0.0
					sheet_pw := sheet_width
					sheet_ph := win_h
					painter.set_color (theme.surface)
					painter.fill_rect (sheet_px, sheet_py, sheet_pw, sheet_ph)
					painter.set_color (theme.outline)
					if sheet_mode = Mode_left then
						painter.vline (sheet_px + sheet_pw - 0.5, 0.0, win_h)
					else
						painter.vline (sheet_px + 0.5, 0.0, win_h)
					end
					s.set_bounds (sheet_px + 14.0, 14.0, sheet_pw - 28.0, win_h - 28.0)
				else
						-- anchored popover: no backdrop, clamped into the window
					sheet_pw := sheet_width + 24.0
					sheet_ph := s.preferred_height (painter, sheet_width).min (win_h - 40.0) + 24.0
					sheet_px := sheet_ax.min (win_w - sheet_pw - 4.0).max (4.0)
					sheet_py := sheet_ay.min (win_h - sheet_ph - 4.0).max (4.0)
					s.set_bounds (sheet_px + 12.0, sheet_py + 12.0, sheet_width, sheet_ph - 24.0)
					painter.set_color (theme.surface)
					painter.rrect_fill (sheet_px, sheet_py, sheet_pw, sheet_ph, theme.radius)
					painter.set_color (theme.outline)
					painter.rrect_stroke (sheet_px + 0.5, sheet_py + 0.5, sheet_pw - 1.0, sheet_ph - 1.0, theme.radius)
				end
				s.arrange (painter)
				s.draw (painter)
			end
			if attached popup as m then
				m.draw (painter)
			end
			if tooltip_visible and then attached hovered as hw and then not hw.tooltip.is_empty
				and then dialog = Void
			then
				draw_tooltip (hw)
			end
			if attached dialog as d then
				painter.set_color_alpha (0x000000, 0.45)
				painter.fill_rect (0.0, 0.0, win_w, win_h)
				d.draw (painter)
			end
			draw_toasts
			frame_echo_dirty := True
		end

	draw_drawer_gutters
			-- The edge rails and their stacked tabs: slim vertical
			-- handles, letters stacked downward, one tab under
			-- another - outside the content, inside the window.
		local
			i: INTEGER
			ly, lx, th: REAL_64
			lefts, rights: INTEGER
		do
			tab_rects.wipe_out
			if gutter_left > 0.0 then
				painter.set_color (theme.surface_variant)
				painter.fill_rect (0.0, 0.0, Gutter_w, win_h)
				painter.set_color (theme.outline)
				painter.vline (Gutter_w - 0.5, 0.0, win_h)
			end
			if gutter_right > 0.0 then
				painter.set_color (theme.surface_variant)
				painter.fill_rect (win_w - Gutter_w, 0.0, Gutter_w, win_h)
				painter.set_color (theme.outline)
				painter.vline (win_w - Gutter_w + 0.5, 0.0, win_h)
			end
			painter.font ({SW_PAINTER}.Role_ui, theme.size_chip, True)
			from
				i := 1
			until
				i > drawer_tabs.count
			loop
				th := drawer_tabs.i_th (i).label.count * 12.0 + 34.0
				if drawer_tabs.i_th (i).from_right then
					lx := win_w - Gutter_w
					ly := 120.0 + rights * (th + 14.0)
					rights := rights + 1
				else
					lx := 0.0
					ly := 120.0 + lefts * (th + 14.0)
					lefts := lefts + 1
				end
				if sheet = Void then
					painter.set_color (theme.surface)
					painter.rrect_fill (lx + 2.0, ly, Gutter_w - 4.0, th, 5.0)
					painter.set_color (theme.accent)
					painter.rrect_stroke (lx + 2.5, ly + 0.5, Gutter_w - 5.0, th - 1.0, 5.0)
					draw_drawer_icon (lx + Gutter_w / 2.0, ly + 11.0)
					draw_vertical_label (drawer_tabs.i_th (i).label, lx + Gutter_w / 2.0, ly + 28.0)
				end
				tab_rects.extend ([lx, ly, Gutter_w, th])
				i := i + 1
			end
		end

	draw_vertical_label (a_text: STRING_32; a_cx, a_top: REAL_64)
			-- Letters stacked downward, centered on `a_cx'.
		local
			i: INTEGER
			ch: STRING_32
		do
			painter.set_color (theme.ink_muted)
			from
				i := 1
			until
				i > a_text.count
			loop
				ch := a_text.substring (i, i)
				painter.text (a_cx - painter.advance (ch) / 2.0, a_top + (i - 1) * 12.0 + 6.0, ch)
				i := i + 1
			end
		end

	draw_drawer_icon (a_cx, a_cy: REAL_64)
			-- A tiny drawer: box with a handle line - the tab's badge.
		do
			painter.set_color (theme.ink_muted)
			painter.rrect_stroke (a_cx - 6.0, a_cy - 4.0, 12.0, 9.0, 2.0)
			painter.hline (a_cx - 3.0, a_cy + 0.5, 6.0)
		end

	flush_frame_echo
			-- Write the debug frame off the hot path: PNG compression
			-- on every render made window-grow drags crawl.
		do
			if frame_echo_dirty and then not frame_echo_path.is_empty then
				offscreen.write_png (frame_echo_path).do_nothing
				frame_echo_dirty := False
			end
		end

	draw_pick_trajectory (a_pebble: ANY)
			-- The pick line: origin dot, line to the pointer, and a
			-- ring on the widget under the pointer - accent when it
			-- welcomes the pebble, danger when it does not.
		local
			w: detachable SW_WIDGET
			ok: BOOLEAN
		do
			if attached active_root as r then
				w := r.widget_at (pick_cur_x, pick_cur_y)
			end
			if attached w as tw then
				ok := tw.is_enabled and then tw.accepts_pebble (a_pebble)
				if ok then
					painter.set_color (theme.accent)
				else
					painter.set_color (theme.danger)
				end
				painter.set_line_width (2.0)
				painter.rrect_stroke (tw.x - 2.0, tw.y - 2.0, tw.width + 4.0, tw.height + 4.0, theme.radius + 2.0)
				painter.set_line_width (1.0)
			end
			painter.set_color (theme.accent)
			painter.line (pick_x, pick_y, pick_cur_x, pick_cur_y, 2.0)
			painter.rrect_fill (pick_x - 4.0, pick_y - 4.0, 8.0, 8.0, 4.0)
			painter.rrect_fill (pick_cur_x - 3.0, pick_cur_y - 3.0, 6.0, 6.0, 3.0)
		end

	draw_tooltip (a_w: SW_WIDGET)
			-- A small drawn hint below the widget, clamped on screen.
		local
			t: SW_THEME
			tw, tx, ty: REAL_64
		do
			t := theme
			painter.font ({SW_PAINTER}.Role_ui, 10.5, False)
			tw := painter.advance (a_w.tooltip) + 18.0
			tx := a_w.x.min (win_w - tw - 4.0).max (4.0)
			ty := a_w.y + a_w.height + 6.0
			if ty + 26.0 > win_h then
				ty := a_w.y - 32.0
			end
			painter.set_color (t.ink)
			painter.rrect_fill (tx, ty, tw, 26.0, t.radius)
			painter.set_color (t.background)
			painter.text (tx + 9.0, ty + 17.5, a_w.tooltip)
		end

feature -- Notifications

	toast (a_text: READABLE_STRING_GENERAL; a_kind: INTEGER)
			-- Queue a transient notification; kinds follow the chip
			-- vocabulary (1 accent, 2 success, 3 warning, 4 danger).
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			toasts.extend ([s, a_kind, Toast_life])
			after_input
		ensure
			queued: toasts.count = old toasts.count + 1
		end

	Toast_life: INTEGER = 7
			-- Timer ticks a toast lives (about 3.5 seconds).

feature {NONE} -- Notification internals

	age_toasts
			-- The heartbeat: age toasts, repaint, flush the echo.
			-- The repaint is unconditional - it is the toolkit's
			-- ambient animation clock (skeleton shimmer rides it).
		local
			i: INTEGER
		do
			from
				i := toasts.count
			until
				i < 1
			loop
				toasts.i_th (i).life := toasts.i_th (i).life - 1
				if toasts.i_th (i).life <= 0 then
					toasts.go_i_th (i)
					toasts.remove
				end
				i := i - 1
			end
			after_input
			flush_frame_echo
		end

	draw_toasts
		local
			t: SW_THEME
			ty, tw: REAL_64
			i: INTEGER
			it: TUPLE [txt: STRING_32; tkind: INTEGER; life: INTEGER]
			kc: NATURAL_32
		do
			t := theme
			ty := win_h - 18.0
			from
				i := toasts.count
			until
				i < 1
			loop
				it := toasts.i_th (i)
				painter.font ({SW_PAINTER}.Role_ui, 11.5, False)
				tw := painter.advance (it.txt) + 40.0
				ty := ty - 36.0
				painter.set_color (t.ink)
				painter.rrect_fill (win_w - 18.0 - tw, ty, tw, 30.0, t.radius)
				inspect it.tkind
				when 2 then
					kc := t.success
				when 3 then
					kc := t.warning
				when 4 then
					kc := t.danger
				else
					kc := t.accent
				end
				painter.set_color (kc)
				painter.fill_rect (win_w - 18.0 - tw, ty + 3.0, 4.0, 24.0)
				painter.set_color (t.background)
				painter.text (win_w - 18.0 - tw + 14.0, ty + 20.0, it.txt)
				ty := ty - 8.0
				i := i - 1
			end
		end

	blit
		local
			hdc: POINTER
			ws: CAIRO_SURFACE
			c2: CAIRO_CONTEXT
		do
			hdc := c_get_dc
			if hdc /= default_pointer then
				create ws.make_for_dc (hdc)
				if ws.is_valid then
					create c2.make (ws)
					c2.set_source_surface (offscreen, 0.0, 0.0).paint.do_nothing
					c2.destroy
				end
				ws.destroy
				c_release_dc (hdc)
			end
		end

feature {NONE} -- State

	capture: detachable SW_WIDGET
			-- Owner of the pointer between press and release.

	hovered: detachable SW_WIDGET
			-- Widget currently under the pointer.

	popup: detachable SW_MENU
			-- The open popup menu, drawn above everything.

	sheet: detachable SW_WIDGET
			-- The overlay content (sheet, drawer or popover), if up.

	sheet_width: REAL_64

	sheet_mode: INTEGER
			-- How the overlay presents: Mode_center, Mode_left,
			-- Mode_right or Mode_anchored.

	sheet_ax, sheet_ay: REAL_64
			-- The anchor point for Mode_anchored.

	sheet_px, sheet_py, sheet_pw, sheet_ph: REAL_64
			-- The drawn panel rectangle, refreshed every render; the
			-- outside-click test uses it so a click on the panel's
			-- own border never dismisses.

	present (a_content: SW_WIDGET; a_width: REAL_64; a_mode: INTEGER; a_x, a_y: REAL_64)
		require
			positive: a_width > 0.0
		do
			sheet := a_content
			sheet_width := a_width
			sheet_mode := a_mode
			sheet_ax := a_x
			sheet_ay := a_y
			if attached focused as f then
				f.set_focused (False)
			end
			focused := Void
		ensure
			shown: sheet = a_content
		end

	point_in_sheet_panel (a_x, a_y: INTEGER): BOOLEAN
		do
			Result := a_x >= sheet_px and a_x <= sheet_px + sheet_pw
				and a_y >= sheet_py and a_y <= sheet_py + sheet_ph
		end

feature -- Drawer tab (peek and pin)

	drawer_tabs: ARRAYED_LIST [TUPLE [label: STRING_32; builder: FUNCTION [SW_WIDGET]; from_right: BOOLEAN]]
			-- The registered edge tabs. Tabs live in reserved edge
			-- GUTTERS outside the content and its scrollbars, so
			-- aiming at a scrollbar thumb can never peek a drawer.

	drawer_pinned: BOOLEAN
			-- Pinned drawers stay until dismissed; peeked ones close
			-- when the pointer leaves the panel.

	Gutter_w: REAL_64 = 22.0

	gutter_left: REAL_64
			-- Reserved width on the left edge; 0 without left tabs.
		do
			across
				drawer_tabs as dt
			loop
				if not dt.from_right then
					Result := Gutter_w
				end
			end
		end

	gutter_right: REAL_64
		do
			across
				drawer_tabs as dt
			loop
				if dt.from_right then
					Result := Gutter_w
				end
			end
		end

	Edge_left: INTEGER = 1
	Edge_right: INTEGER = 2
	Edge_top: INTEGER = 3
	Edge_bottom: INTEGER = 4

	set_drawer_tab, add_drawer_tab (a_label: READABLE_STRING_GENERAL; a_builder: FUNCTION [SW_WIDGET]; a_edge: INTEGER)
			-- Register an edge tab: hovering it peeks its drawer,
			-- clicking it pins it open. Several tabs stack per edge.
			-- Placement is the programmer's option; the signature
			-- accepts all four edges so it never churns - top and
			-- bottom gutters arrive with S04.
		require
			edge_known: a_edge >= Edge_left and a_edge <= Edge_bottom
			edge_supported_today: a_edge = Edge_left or a_edge = Edge_right
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			drawer_tabs.extend ([l, a_builder, a_edge = Edge_right])
		ensure
			grew: drawer_tabs.count = old drawer_tabs.count + 1
		end

	tab_rects: ARRAYED_LIST [TUPLE [rx, ry, rw, rh: REAL_64]]
			-- Drawn tab rectangles, parallel to `drawer_tabs',
			-- refreshed every render.

	drawer_tab_at (a_x, a_y: INTEGER): INTEGER
			-- Which tab the point is on; 0 for none.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > tab_rects.count or Result > 0
			loop
				if a_x >= tab_rects.i_th (i).rx and then a_x <= tab_rects.i_th (i).rx + tab_rects.i_th (i).rw
					and then a_y >= tab_rects.i_th (i).ry and then a_y <= tab_rects.i_th (i).ry + tab_rects.i_th (i).rh
				then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= drawer_tabs.count
		end

	open_drawer_from_tab (a_i: INTEGER; a_pinned: BOOLEAN)
		require
			in_range: a_i >= 1 and a_i <= drawer_tabs.count
		do
			present (drawer_tabs.i_th (a_i).builder.item ([]), 300.0,
				(if drawer_tabs.i_th (a_i).from_right then Mode_right else Mode_left end), 0.0, 0.0)
			drawer_pinned := a_pinned
		end

	active_root: detachable SW_WIDGET
			-- Where input lands: the sheet while one is up, else root.
		do
			if attached sheet as s then
				Result := s
			else
				Result := root
			end
		end

	dialog: detachable SW_DIALOG
			-- The open modal dialog; owns all input while present.

	toasts: ARRAYED_LIST [TUPLE [txt: STRING_32; tkind: INTEGER; life: INTEGER]]
		attribute
			create Result.make (4)
		end

	frame_echo_dirty: BOOLEAN

	alloc_w: INTEGER
	alloc_h: INTEGER
			-- The offscreen surface's allocated size; grown in steps so
			-- a corner drag does not reallocate per pixel.

	pick_pebble: detachable ANY
			-- The pebble in flight, when pick-and-drop is active.

	pick_x, pick_y, pick_cur_x, pick_cur_y: INTEGER

	pending_surrogate: INTEGER
			-- High half of a UTF-16 pair awaiting its partner.

	dwell_ticks: INTEGER
			-- Timer ticks the pointer has rested on the hovered widget.

	tooltip_visible: BOOLEAN

	cairo: SIMPLE_CAIRO
	offscreen: CAIRO_SURFACE
	ctx: CAIRO_CONTEXT
	ev_buf: MANAGED_POINTER
	hwnd: POINTER
	frame_echo_path: STRING_32

feature {NONE} -- Externals

	c_create_window (a_title: POINTER; a_x, a_y, a_w, a_h: INTEGER): POINTER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_create_window((const wchar_t*)$a_title, (int)$a_x, (int)$a_y, (int)$a_w, (int)$a_h);"
		end

	c_pump: INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_pump();"
		end

	c_next_event (a_buf: POINTER): INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_next_event((int*)$a_buf);"
		end

	c_get_dc: POINTER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_get_dc();"
		end

	c_release_dc (a_dc: POINTER)
		external
			"C inline use %"simple_widgets.h%""
		alias
			"sw_release_dc($a_dc);"
		end

	c_add_font (a_path: POINTER): INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_add_font((const char*)$a_path);"
		end

	c_shift_down: INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_shift_down();"
		end

invariant
	painter_attached: painter /= Void
	theme_attached: theme /= Void

end
