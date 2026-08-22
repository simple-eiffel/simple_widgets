note
	description: "[
		7GUIs (Eugen Kiss's benchmark), implemented spec-exact on
		simple_widgets: Counter, Temperature Converter, Flight
		Booker, Timer, CRUD, Circle Drawer, Cells - one tab each.
		Domain logic lives in CELLS_ENGINE and CIRCLES_MODEL; this
		class is presentation and wiring.
	]"

class
	SW_7GUIS

create
	make

feature {NONE} -- Initialization

	make
		local
			root: SW_COLUMN
			tabs: SW_TABS
		do
			create theme.make_dark
			create window.make ("7GUIs on simple_widgets", 1240, 40, 900, 900, theme)
				-- every attached attribute exists before any agent (VEVI)
			create count_label.make ("0", {SW_PAINTER}.Role_mono, 26.0, True)
			create temp_c.make_single_line ("")
			create temp_f.make_single_line ("")
			create flight_kind.make
			create flight_start.make_single_line ("27.03.2014")
			create flight_return.make_single_line ("27.03.2014")
			create book_button.make ("Book", Void)
			create timer_gauge.make (0.0)
			create timer_label.make_mono ("0.0s")
			create timer_slider.make (0.5, Void)
			create crud_filter.make_single_line ("")
			create crud_name.make_single_line ("")
			create crud_surname.make_single_line ("")
			create crud_list.make (170.0)
			create update_button.make ("Update", Void)
			create delete_button.make ("Delete", Void)
			create people.make (8)
			create filtered.make (8)
			create circles.make
			create canvas.make (260.0)
			create undo_button.make ("Undo", Void)
			create redo_button.make ("Redo", Void)
			create cells.make
			create sheet.make (430.0)
			duration := 15.0
				-- wiring (agents are safe now)
			temp_c.set_spellcheck (False)
			temp_f.set_spellcheck (False)
			temp_c.set_on_change (agent on_celsius_changed)
			temp_f.set_on_change (agent on_fahrenheit_changed)
			flight_kind.add_option ("one-way flight")
			flight_kind.add_option ("return flight")
			flight_kind.select_index (1)
			flight_kind.set_on_change (agent on_flight_kind_changed)
			flight_start.set_spellcheck (False)
			flight_return.set_spellcheck (False)
			flight_start.set_on_change (agent on_dates_changed)
			flight_return.set_on_change (agent on_dates_changed)
			book_button.set_on_click (agent on_book)
			flight_return.set_enabled (False)
			timer_slider.set_on_change (agent on_duration_changed)
			crud_filter.set_spellcheck (False)
			crud_name.set_spellcheck (False)
			crud_surname.set_spellcheck (False)
			crud_filter.set_clear_button (True)
			crud_filter.set_on_change (agent refilter)
			crud_list.set_row_renderer (agent render_person)
			crud_list.set_on_select (agent on_person_selected)
			update_button.set_on_click (agent on_update_person)
			delete_button.set_on_click (agent on_delete_person)
			update_button.set_enabled (False)
			delete_button.set_enabled (False)
			seed_people
			canvas.set_on_paint (agent paint_circles)
			canvas.set_on_press (agent on_canvas_press)
			canvas.set_menu_provider (agent circle_menu)
			undo_button.set_on_click (agent on_undo)
			redo_button.set_on_click (agent on_redo)
			refresh_circle_buttons
			sheet.set_on_cell_commit (agent on_cell_commit)
			sheet.set_formula_provider (agent seed_formula)
			seed_cells
			window.set_on_tick (agent on_tick)
			window.set_frame_echo ("g7_frame.png")
				-- layout
			create root.make
			root := root.with_padding (14.0).with_gap (10.0)
			root.put (create {SW_LABEL}.make ("7GUIs", {SW_PAINTER}.Role_ui, 20.0, True))
			root.put ((create {SW_LABEL}.make_mono ("the benchmark, spec-exact, every pixel drawn")).as_muted)
			create tabs.make
			tabs.add_page ("Counter", counter_page)
			tabs.add_page ("Temp", temperature_page)
			tabs.add_page ("Flight", flight_page)
			tabs.add_page ("Timer", timer_page)
			tabs.add_page ("CRUD", crud_page)
			tabs.add_page ("Circles", circles_page)
			tabs.add_page ("Cells", cells_page)
			root.put (tabs)
			window.set_root (root)
			window.run
		end

feature {NONE} -- Shared

	theme: SW_THEME

	window: SW_WINDOW

feature {NONE} -- 1: Counter

	count_label: SW_LABEL

	count: INTEGER

	counter_page: SW_COLUMN
		local
			row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (10.0)
			create row.make
			row.put (count_label)
			row.put (create {SW_BUTTON}.make_primary ("Count", agent on_count))
			Result.put (row)
		end

	on_count
		do
			count := count + 1
			count_label.set_text (count.out)
		end

feature {NONE} -- 2: Temperature Converter

	temp_c, temp_f: SW_TEXT_BOX

	temp_updating: BOOLEAN

	temperature_page: SW_COLUMN
		local
			row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (10.0)
			create row.make
			row.put (temp_c.growing)
			row.put (create {SW_LABEL}.make_ui ("Celsius ="))
			row.put (temp_f.growing)
			row.put (create {SW_LABEL}.make_ui ("Fahrenheit"))
			Result.put (row)
			Result.put ((create {SW_LABEL}.make_ui ("Type in either field; the other follows. Non-numbers leave the twin alone.")).as_muted)
		end

	on_celsius_changed
		do
			if not temp_updating and then temp_c.text.is_double then
				temp_updating := True
				temp_f.set_text ((temp_c.text.to_double * 9.0 / 5.0 + 32.0).rounded.out)
				temp_updating := False
			end
		end

	on_fahrenheit_changed
		do
			if not temp_updating and then temp_f.text.is_double then
				temp_updating := True
				temp_c.set_text (((temp_f.text.to_double - 32.0) * 5.0 / 9.0).rounded.out)
				temp_updating := False
			end
		end

feature {NONE} -- 3: Flight Booker

	flight_kind: SW_SELECT

	flight_start, flight_return: SW_TEXT_BOX

	book_button: SW_BUTTON

	flight_page: SW_COLUMN
		do
			create Result.make
			Result := Result.with_gap (10.0)
			Result.put (flight_kind)
			Result.put (flight_start)
			Result.put (flight_return)
			Result.put (book_button)
			Result.put ((create {SW_LABEL}.make_ui ("Dates are DD.MM.YYYY. Bad dates go red and Book disables; a return before the start disables it too.")).as_muted)
		end

	date_code (a_text: STRING_32): INTEGER
			-- Comparable yyyymmdd; -1 when ill-formatted.
		local
			parts: LIST [STRING_32]
			d, m, yy: INTEGER
		do
			Result := -1
			parts := a_text.split ('.')
			if parts.count = 3 and then parts.i_th (1).is_integer
				and then parts.i_th (2).is_integer and then parts.i_th (3).is_integer
			then
				d := parts.i_th (1).to_integer
				m := parts.i_th (2).to_integer
				yy := parts.i_th (3).to_integer
				if d >= 1 and d <= 31 and m >= 1 and m <= 12 and yy >= 1000 and yy <= 9999 then
					Result := yy * 10000 + m * 100 + d
				end
			end
		end

	on_flight_kind_changed
		do
			flight_return.set_enabled (flight_kind.selected_index = 2)
			on_dates_changed
		end

	on_dates_changed
		local
			sc, rc: INTEGER
			ok: BOOLEAN
		do
			sc := date_code (flight_start.text)
			flight_start.set_invalid (sc < 0)
			ok := sc >= 0
			if flight_kind.selected_index = 2 then
				rc := date_code (flight_return.text)
				flight_return.set_invalid (rc < 0)
				ok := ok and rc >= 0 and then rc >= sc
			else
				flight_return.set_invalid (False)
			end
			book_button.set_enabled (ok)
		end

	on_book
		do
			if flight_kind.selected_index = 1 then
				window.toast ({STRING_32} "You have booked a one-way flight on " + flight_start.text + {STRING_32} ".", 2)
			else
				window.toast ({STRING_32} "You have booked a return flight: " + flight_start.text
					+ {STRING_32} " to " + flight_return.text + {STRING_32} ".", 2)
			end
		end

feature {NONE} -- 4: Timer

	timer_gauge: SW_PROGRESS

	timer_label: SW_LABEL

	timer_slider: SW_SLIDER

	elapsed, duration: REAL_64

	timer_page: SW_COLUMN
		local
			row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (10.0)
			create row.make
			row.put (create {SW_LABEL}.make_ui ("Elapsed:"))
			row.put (timer_label)
			Result.put (row)
			Result.put (timer_gauge)
			create row.make
			row.put (create {SW_LABEL}.make_ui ("Duration:"))
			row.put (timer_slider.growing)
			Result.put (row)
			Result.put (create {SW_BUTTON}.make ("Reset", agent on_timer_reset))
			Result.put ((create {SW_LABEL}.make_ui ("The gauge fills as time passes; drag the slider and it reacts mid-flight.")).as_muted)
		end

	on_tick
		do
			if elapsed < duration then
				elapsed := (elapsed + 0.25).min (duration)
				refresh_timer
			end
		end

	on_duration_changed (a_f: REAL_64)
		do
			duration := a_f * 30.0
			refresh_timer
		end

	on_timer_reset
		do
			elapsed := 0.0
			refresh_timer
		end

	refresh_timer
		do
			if duration > 0.0 then
				timer_gauge.set_fraction ((elapsed / duration).min (1.0))
			else
				timer_gauge.set_fraction (1.0)
			end
			timer_label.set_text (elapsed.truncated_to_integer.out + "." + ((elapsed * 10.0).rounded \\ 10).out + "s of " + duration.rounded.out + "s")
		end

feature {NONE} -- 5: CRUD

	crud_filter, crud_name, crud_surname: SW_TEXT_BOX

	crud_list: SW_LIST

	update_button, delete_button: SW_BUTTON

	people: ARRAYED_LIST [TUPLE [first, last: STRING_32]]

	filtered: ARRAYED_LIST [INTEGER]
			-- Indices into `people' surviving the filter, in order.

	crud_page: SW_COLUMN
		local
			row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (8.0)
			create row.make
			row.put (create {SW_LABEL}.make_ui ("Filter surname:"))
			row.put (crud_filter.growing)
			Result.put (row)
			Result.put (crud_list)
			create row.make
			row.put (create {SW_LABEL}.make_ui ("Name:"))
			row.put (crud_name.growing)
			row.put (create {SW_LABEL}.make_ui ("Surname:"))
			row.put (crud_surname.growing)
			Result.put (row)
			create row.make
			row.put (create {SW_BUTTON}.make_primary ("Create", agent on_create_person))
			row.put (update_button)
			row.put (delete_button)
			Result.put (row)
		end

	seed_people
		do
			people.extend ([{STRING_32} "Hans", {STRING_32} "Emil"])
			people.extend ([{STRING_32} "Max", {STRING_32} "Mustermann"])
			people.extend ([{STRING_32} "Roman", {STRING_32} "Tisch"])
			refilter
		end

	refilter
		local
			i: INTEGER
			pfx: STRING_32
		do
			filtered.wipe_out
			pfx := crud_filter.text.as_lower
			from
				i := 1
			until
				i > people.count
			loop
				if pfx.is_empty or else people.i_th (i).last.as_lower.starts_with (pfx) then
					filtered.extend (i)
				end
				i := i + 1
			end
			crud_list.set_row_count (filtered.count)
			crud_list.select_row (0)
			on_person_selected (0)
		end

	render_person (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			a_p.font ({SW_PAINTER}.Role_ui, 13.0, False)
			a_p.set_color (a_p.theme.ink)
			if a_i >= 1 and a_i <= filtered.count then
				a_p.text (a_x + 8.0, a_y + a_h - 9.0,
					people.i_th (filtered.i_th (a_i)).last + {STRING_32} ", " + people.i_th (filtered.i_th (a_i)).first)
			end
		end

	on_person_selected (a_i: INTEGER)
		do
			update_button.set_enabled (a_i >= 1)
			delete_button.set_enabled (a_i >= 1)
			if a_i >= 1 and a_i <= filtered.count then
				crud_name.set_text (people.i_th (filtered.i_th (a_i)).first)
				crud_surname.set_text (people.i_th (filtered.i_th (a_i)).last)
			end
		end

	on_create_person
		do
			people.extend ([crud_name.text.twin, crud_surname.text.twin])
			refilter
		end

	on_update_person
		do
			if crud_list.selected_index >= 1 and crud_list.selected_index <= filtered.count then
				people.i_th (filtered.i_th (crud_list.selected_index)).first := crud_name.text.twin
				people.i_th (filtered.i_th (crud_list.selected_index)).last := crud_surname.text.twin
				refilter
			end
		end

	on_delete_person
		do
			if crud_list.selected_index >= 1 and crud_list.selected_index <= filtered.count then
				people.go_i_th (filtered.i_th (crud_list.selected_index))
				people.remove
				refilter
			end
		end

feature {NONE} -- 6: Circle Drawer

	circles: CIRCLES_MODEL

	canvas: SW_CANVAS

	undo_button, redo_button: SW_BUTTON

	adjust_index: INTEGER

	adjust_armed: BOOLEAN
			-- Snapshot pending for the current adjustment session.

	circles_page: SW_COLUMN
		local
			row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (8.0)
			create row.make
			row.put (undo_button)
			row.put (redo_button)
			Result.put (row)
			Result.put (canvas)
			Result.put ((create {SW_LABEL}.make_ui ("Click to place a circle; the one under the pointer fills. Right-click it to adjust its diameter.")).as_muted)
		end

	paint_circles (a_p: SW_PAINTER; a_x, a_y, a_w, a_h: REAL_64)
		local
			i, hot: INTEGER
		do
			if canvas.shows_hover then
				hot := circles.nearest_hit (canvas.hover_px - a_x, canvas.hover_py - a_y)
			end
			from
				i := 1
			until
				i > circles.circles.count
			loop
				if i = hot then
					a_p.set_color_alpha (a_p.theme.ink_muted, 0.35)
					a_p.circle_fill (a_x + circles.circles.i_th (i).cx,
						a_y + circles.circles.i_th (i).cy, circles.circles.i_th (i).radius)
				end
				a_p.set_color (a_p.theme.ink)
				a_p.circle_stroke (a_x + circles.circles.i_th (i).cx,
					a_y + circles.circles.i_th (i).cy, circles.circles.i_th (i).radius)
				i := i + 1
			end
		end

	on_canvas_press (a_x, a_y: REAL_64)
		do
			if circles.nearest_hit (a_x, a_y) = 0 then
				circles.add_circle (a_x, a_y)
				refresh_circle_buttons
			end
		end

	circle_menu (a_x, a_y: REAL_64): detachable SW_MENU
		local
			hit: INTEGER
		do
			hit := circles.nearest_hit (a_x, a_y)
			if hit > 0 then
				adjust_index := hit
				create Result.make
				Result.add_item ("Adjust diameter%/8230/", "", True, agent on_adjust_diameter)
			end
		end

	on_adjust_diameter
		local
			col: SW_COLUMN
			sl: SW_SLIDER
		do
			if adjust_index >= 1 and adjust_index <= circles.circles.count then
				adjust_armed := True
				create col.make
				col := col.with_gap (8.0)
				col.put (create {SW_LABEL}.make_ui ("Adjust diameter of circle at ("
					+ circles.circles.i_th (adjust_index).cx.rounded.out + ", "
					+ circles.circles.i_th (adjust_index).cy.rounded.out + ")"))
				create sl.make ((circles.circles.i_th (adjust_index).radius / 60.0).min (1.0), agent on_diameter_slid)
				col.put (sl)
				window.show_popover (col, 300.0, 300.0, 300.0)
			end
		end

	on_diameter_slid (a_f: REAL_64)
		do
			if adjust_index >= 1 and adjust_index <= circles.circles.count then
				if adjust_armed then
						-- first drag of this session: one significant
						-- change begins - snapshot once
					circles.begin_adjustment (adjust_index)
					adjust_armed := False
				end
				circles.set_radius (adjust_index, (a_f * 60.0).max (2.0))
				refresh_circle_buttons
			end
		end

	on_undo
		do
			if circles.can_undo then
				circles.undo
				refresh_circle_buttons
			end
		end

	on_redo
		do
			if circles.can_redo then
				circles.redo
				refresh_circle_buttons
			end
		end

	refresh_circle_buttons
		do
			undo_button.set_enabled (circles.can_undo)
			redo_button.set_enabled (circles.can_redo)
		end

feature {NONE} -- 7: Cells

	cells: CELLS_ENGINE

	sheet: SW_SHEET

	cells_page: SW_COLUMN
		do
			create Result.make
			Result := Result.with_gap (8.0)
			Result.put (sheet)
			Result.put ((create {SW_LABEL}.make_ui ("Double-click a cell (or press Enter) to edit. Formulas start with =, reference cells as A0..Z99, and propagate: try changing A0 with B0 = =A0*2.")).as_muted)
		end

	seed_formula (a_row, a_col: INTEGER): STRING_32
		do
			Result := cells.formula (cells.key (a_row, a_col))
		end

	on_cell_commit (a_row, a_col: INTEGER; a_text: STRING_32)
		do
			cells.commit (cells.key (a_row, a_col), a_text)
			across
				cells.touched as k
			loop
				sheet.set_cell_display (k // cells.Cols, k \\ cells.Cols, cells.display (k))
			end
		end

	seed_cells
		do
			on_cell_commit (0, 1, {STRING_32} "10")
			on_cell_commit (0, 2, {STRING_32} "=A0*2")
			on_cell_commit (1, 1, {STRING_32} "5.5")
			on_cell_commit (2, 1, {STRING_32} "=A0+A1")
			on_cell_commit (4, 1, {STRING_32} "hello")
		end

end
