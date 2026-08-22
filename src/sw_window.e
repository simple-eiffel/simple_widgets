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
			offscreen := cairo.create_surface (win_w, win_h)
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
			when 7 then
				age_toasts
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

	close_popup
		do
			popup := Void
		ensure
			closed: popup = Void
		end

	dispatch_normal (a_type, a_x, a_y: INTEGER)
		do
			inspect a_type
			when 2 then
				if attached root as r and then attached r.widget_at (a_x, a_y) as w then
					if w.accepts_focus and then w /= focused then
						if attached focused as prev then
							prev.set_focused (False)
						end
						focused := w
						w.set_focused (True)
					end
					capture := bubble_click (w, a_x, a_y, False)
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
					if attached focused as w then
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
				if attached root as r and then attached r.widget_at (a_x, a_y) as w then
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
				age_toasts
			when 13 then
				update_hover (a_x, a_y)
			when 14 then
				if attached hovered as hw then
					hw.set_hovered (False)
					hovered := Void
					after_input
				end
			when 11 then
				if attached root as r and then attached r.widget_at (a_x, a_y) as w then
					bubble_context (w, a_x, a_y)
				end
				after_input
			when 12 then
				if attached root as r and then attached r.widget_at (a_x, a_y) as w then
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

	update_hover (a_x, a_y: INTEGER)
			-- Move the hover state to the widget under the pointer;
			-- re-render only when the target changed.
		local
			w: detachable SW_WIDGET
		do
			if attached root as r then
				w := r.widget_at (a_x, a_y)
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
				r.set_bounds (0.0, 0.0, win_w, win_h)
				r.arrange (painter)
				r.draw (painter)
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
			if not frame_echo_path.is_empty then
				offscreen.write_png (frame_echo_path).do_nothing
			end
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
		local
			i: INTEGER
			changed: BOOLEAN
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
				changed := True
				i := i - 1
			end
			if changed then
				after_input
			end
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

	dialog: detachable SW_DIALOG
			-- The open modal dialog; owns all input while present.

	toasts: ARRAYED_LIST [TUPLE [txt: STRING_32; tkind: INTEGER; life: INTEGER]]
		attribute
			create Result.make (4)
		end

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
