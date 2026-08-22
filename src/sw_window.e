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
			inspect a_type
			when 2 then
				if attached root as r and then attached r.widget_at (a_x, a_y) as w then
					if w.accepts_focus then
						focused := w
					end
					w.handle_click (a_x, a_y)
				end
				after_input
			when 3 then
				if attached focused as w then
					w.handle_char (a_x)
					after_input
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
					w.handle_double_click (a_x, a_y)
				end
				after_input
			when 9 then
				if attached focused as w then
					w.handle_drag (a_x, a_y)
					after_input
				end
			else
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
			if not frame_echo_path.is_empty then
				offscreen.write_png (frame_echo_path).do_nothing
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
