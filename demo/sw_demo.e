note
	description: "[
		The whole point, demonstrated: a themed, interactive face in
		under a hundred lines of application code. No externals, no
		coordinates, no Cairo - a window, widgets, layout and agents.
	]"

class
	SW_DEMO

create
	make

feature {NONE} -- Initialization

	make
		local
			theme: SW_THEME
			root: SW_COLUMN
			body: SW_COLUMN
			body_scroll: SW_SCROLL_AREA
			card: SW_CARD
			chips: SW_ROW
			buttons: SW_ROW
			grp: SW_GROUP
			pw: SW_TEXT_BOX
		do
			create theme.make_dark
			create counter_label.make ("clicks: 0  %/8212/ buttons report HERE", {SW_PAINTER}.Role_mono, 14.0, True)
			create progress.make (0.0)
			progress.set_shows_caption (True)
			create kind_select.make
			kind_select.add_option ("Info")
			kind_select.add_option ("Success")
			kind_select.add_option ("Warning")
			kind_select.add_option ("Danger")
			kind_select.set_tooltip ("Chooses the kind for Toast It %/8212/ picking one previews it")
			create edit_box.make ("The quick brown fox jumps over the lazy dog, and keeps on runing untill the wrap engine breaks the line exactly where the measured advances say it must.")
			create menubar.make
			create statusbar.make
			create combo.make_with_options
			create seg.make
			create fleet_grid.make (240.0)
			create cal.make
			create fleet_tree.make (200.0)
			create color_picker.make (0x4D8FD6)
			create date_us.make_picker
			create date_iso.make_picker
			create time_12.make_picker
			create time_24.make_picker
			create grid_filter_box.make_single_line ("")
			create stepper.make
			create accordion.make
			create rating.make (3, 5, Void)
			create toolbar.make
			create window.make ("simple_widgets demo", 2200, 10, 900, 1600, theme)
				-- agents only from here down: every attached attribute is set
			create danger_button.make ("Danger", Void)
			toolbar.add_tool ("New", "Start fresh (decorative)", True, agent on_menu_new)
			toolbar.add_tool ("Save", "Save (decorative)", True, agent on_menu_save)
			toolbar.add_gap
			toolbar.add_toggle ("Bold", "Latches %/8212/ the status bar reports it", False, agent on_tool_flip)
			toolbar.add_toggle ("Italic", "Latches %/8212/ the status bar reports it", False, agent on_tool_flip)
			toolbar.add_gap
			toolbar.add_tool ("Broken", "A disabled tool stays muted", False, Void)
			combo.add_option ("Cairo")
			combo.add_option ("Vision2")
			combo.add_option ("WEL")
			combo.add_option ("simple_widgets")
			combo.set_on_change (agent on_combo_changed)
			combo.set_tooltip ("An editable dropdown %/8212/ type freely, or pick via the chevron")
			window.set_drawer_tab ("Settings", agent build_settings_drawer, {SW_WINDOW}.Edge_right)
			danger_button.set_on_click (agent on_log_only)
			danger_button.set_kind ({SW_BUTTON}.Kind_danger)
			danger_button.set_tooltip ("A danger-kind button %/8212/ arm or disarm me with the checkbox")
			window.add_font ("D:\prod\simple_narrate\fonts\Archivo.ttf").do_nothing
			window.add_font ("D:\prod\simple_narrate\fonts\Literata.ttf").do_nothing
			window.add_font ("D:\prod\simple_narrate\fonts\IBMPlexMono.ttf").do_nothing
			window.set_frame_echo ("sw_demo_frame.png")

			create root.make
			root := root.with_padding (16.0).with_gap (14.0)

			menubar.add_menu ("File", agent file_menu)
			menubar.add_menu ("Widgets", agent widgets_menu)
			menubar.add_menu ("Help", agent help_menu)
			root.put (menubar)
			root.put (toolbar)
			create body.make
			body := body.with_gap (14.0)

			body.put (create {SW_LABEL}.make ("simple_widgets", {SW_PAINTER}.Role_ui, 20.0, True))
			body.put ((create {SW_LABEL}.make_mono ("the toolkit above simple_cairo %/183/ no Vision2 %/183/ no boilerplate")).as_muted)

			create card.make_striped (theme.success)
			card.put (create {SW_LABEL}.make_body ("Every colour, face and metric here comes from the theme; every position from the layout."))
			create chips.make
			chips.put (create {SW_CHIP}.make ("NEUTRAL", {SW_CHIP}.Kind_neutral))
			chips.put (create {SW_CHIP}.make ("RENDERED", {SW_CHIP}.Kind_accent))
			chips.put (create {SW_CHIP}.make ("APPROVED", {SW_CHIP}.Kind_success))
			chips.put (create {SW_CHIP}.make ("DIRTY", {SW_CHIP}.Kind_warning))
			chips.put (create {SW_CHIP}.make ("FAILED", {SW_CHIP}.Kind_danger))
			card.put (chips)
			body.put (card)

			create card.make_striped (theme.accent)
			card.put (counter_label)
			card.put (progress)
			create buttons.make
			buttons.put ((create {SW_BUTTON}.make_primary ("Click Me", agent on_click_me)).with_tooltip ("Adds 10%% to the progress bar"))
			buttons.put (create {SW_BUTTON}.make ("Log Only", agent on_log_only))
			buttons.put ((create {SW_BUTTON}.make ("Disabled", Void)).disabled)
			buttons.put (create {SW_BUTTON}.make ("Dark / Light", agent on_toggle_theme))
			buttons.put (danger_button)
			buttons.put (create {SW_CHECK_BOX}.make ("Danger armed", True, agent on_toggle_danger))
			card.put (buttons)
			create buttons.make
			buttons.put (create {SW_SWITCH}.make ("Live updates", True, agent on_log_only))
			buttons.put ((create {SW_RADIO_GROUP}.make).with_option ("Alpha").with_option ("Beta").with_option ("Gamma"))
			create grp.make_titled ("Choices")
			grp.put (buttons)
			card.put (grp)
			create buttons.make
			buttons.put (kind_select)
			buttons.put (create {SW_BUTTON}.make ("Toast It", agent on_toast))
			buttons.put ((create {SW_BUTTON}.make ("Delete%/8230/", agent on_delete)).as_kind ({SW_BUTTON}.Kind_danger))
			buttons.put (((create {SW_BUTTON}.make ("I grow with the window", Void)).disabled).growing)
			card.put (buttons)
			body.put (card)

			create card.make_striped (theme.warning)
			card.put ((create {SW_LABEL}.make_ui ("SW_TEXT_BOX %/8212/ click, drag, double-click, shift+arrows, type")).as_muted)
			edit_box.set_on_change (agent on_text_changed)
			kind_select.set_on_change (agent on_kind_changed)
			card.put (edit_box)
			card.put ((create {SW_LABEL}.make_ui ("SW_COMBO %/8212/ editable + chevron %/183/ make_password %/8212/ bullets, no copy, no spellcheck")).as_muted)
			create buttons.make
			buttons.put (combo)
			create pw.make_password ("hunter2")
			pw.set_tooltip ("A password box %/8212/ the eye reveals, the clipboard still never sees the secret")
			buttons.put (pw.growing)
			card.put (buttons)
			body.put (card)

			body.put (scroll_split_card (theme))
			body.put (disclosure_card (theme))
			body.put (tabs_card (theme))
			body.put (list_card (theme))
			statusbar.set_left ("ready %/8212/ every pixel drawn by simple_widgets")
			statusbar.set_right ("58 widgets and counting")
			create body_scroll.make (400.0)
			body_scroll.set_child (body)
			root.put (body_scroll.growing)
			root.put (statusbar)

			window.set_root (root)
			window.run
		end

	tabs_card (a_theme: SW_THEME): SW_CARD
			-- SW_TABS hosting a slider page and a number page - both
			-- wired to visible state per the immediate-feedback rule.
		local
			tabs: SW_TABS
			page: SW_COLUMN
			sl: SW_SLIDER
			nb: SW_NUMBER_BOX
			stats: SW_ROW
			stat2: SW_STATISTIC
			empty: SW_EMPTY_STATE
			iso_locale, euro_locale: SW_LOCALE
			pick_row: SW_ROW
		do
			create tabs.make
			create page.make
			page := page.with_gap (10.0)
			page.put (create {SW_LABEL}.make_ui ("Drag me %/8212/ the progress bar above follows live"))
			create sl.make (0.0, agent on_slider_moved)
			page.put (sl)
			tabs.add_page ("Slider", page)
			create page.make
			page := page.with_gap (10.0)
			page.put (create {SW_LABEL}.make_ui ("Spin or wheel me %/8212/ the headline reports every change"))
			create nb.make (50, 0, 100, agent on_number_changed)
			page.put (nb)
			tabs.add_page ("Number Box", page)
			create page.make
			page := page.with_gap (10.0)
			page.put (create {SW_LABEL}.make_ui ("A PNG loaded by cairo, contain-scaled and centered by SW_IMAGE"))
			page.put ((create {SW_IMAGE}.make_from_file ("D:/prod/simple_widgets/docs/images/logo.png")).with_display_height (170.0))
			tabs.add_page ("Picture", page)
			create page.make
			page := page.with_gap (12.0)
			create stats.make
			stats.put (create {SW_STATISTIC}.make ("widgets shipped", "45"))
			create stat2.make ("assault tests", "25")
			stat2.set_delta ("+7", True)
			stats.put (stat2)
			create stat2.make ("native controls", "0")
			stat2.set_delta ("forever", True)
			stats.put (stat2)
			page.put (stats)
			create stats.make
			stats.put (create {SW_AVATAR}.make ("Larry Rix"))
			stats.put (create {SW_AVATAR}.make ("Claude"))
			stats.put (create {SW_AVATAR}.make ("simple widgets"))
			stats.put ((create {SW_BADGE}.make_count (3)))
			stats.put ((create {SW_BADGE}.make_count (150)))
			stats.put (create {SW_BADGE}.make_dot)
			seg := seg.with_segment ("List").with_segment ("Grid").with_segment ("Cards")
			seg.set_on_change (agent on_view_changed)
			stats.put (seg)
			rating.set_on_change (agent on_rated)
			rating.set_tooltip ("Click a star to rate; click the same star to clear")
			stats.put (rating)
			page.put (stats)
			page.put (create {SW_SKELETON}.make (3))
			create empty.make ("Nothing here yet", "This region is honest about being empty.")
			empty.set_action ("Create the first thing", agent on_empty_action)
			page.put (empty)
			tabs.add_page ("Wave 3", page)
			create page.make
			page := page.with_gap (8.0)
			grid_filter_box.set_clear_button (True)
			grid_filter_box.set_spellcheck (False)
			grid_filter_box.set_on_change (agent on_grid_filter_changed)
			page.put (grid_filter_box)
			fleet_grid.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]]}.make ("Widget", 190.0, agent grid_name))
			fleet_grid.add_column ((create {SW_GRID_COLUMN [TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]]}.make ("Wave", 80.0, agent grid_wave_text)).with_key (agent grid_wave_key))
			fleet_grid.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]]}.make ("Category", 200.0, agent grid_category))
			seed_fleet_grid
			fleet_grid.set_on_select (agent on_grid_row_selected)
			page.put (fleet_grid)
			page.put ((create {SW_LABEL}.make_ui ("Click a header to sort (again for descending; Wave sorts as numbers). Drag a divider to resize. Filter above.")).as_muted)
			tabs.add_page ("Grid", page)
			create page.make
			page := page.with_gap (8.0)
			cal.set_on_pick (agent on_calendar_picked)
			page.put (cal)
			date_us.set_tooltip ("US locale from the theme: MM/DD/YYYY %/8212/ type or use the glyph")
			date_us.set_on_date_change (agent on_date_changed)
			page.put (date_us)
			create iso_locale.make_iso
			date_iso := date_iso.with_picker_locale (iso_locale)
			date_iso.set_tooltip ("ISO override ON THIS CONTROL: YYYY-MM-DD %/8212/ locale is settable per control")
			page.put (date_iso)
			create pick_row.make
			time_12.set_tooltip ("Theme locale: 12-hour, H:MM AM/PM")
			pick_row.put (time_12.growing)
			create euro_locale.make_european
			time_24 := time_24.with_picker_locale (euro_locale)
			time_24.set_tooltip ("European override: 24-hour HH:MM")
			pick_row.put (time_24.growing)
			page.put (pick_row)
			page.put ((create {SW_LABEL}.make_ui ("SW_CALENDAR + SW_DATE_PICKER + SW_TIME_PICKER %/8212/ culture is a setting: US by default, overridable per control. Bad input wears the invalid tint.")).as_muted)
			tabs.add_page ("Pickers", page)
			create page.make
			page := page.with_gap (10.0)
			fleet_tree.set_label (agent node_label)
			fleet_tree.set_children (agent node_children)
			fleet_tree.set_roots (build_fleet_forest)
			fleet_tree.set_on_select (agent on_tree_selected)
			page.put (fleet_tree)
			color_picker.set_on_change (agent on_color_changed)
			page.put (color_picker)
			page.put ((create {SW_LABEL}.make_ui ("SW_TREE %/8212/ lazy children via agents; arrows navigate, left/right fold. SW_COLOR_PICKER %/8212/ drag the field and the bar.")).as_muted)
			tabs.add_page ("Tree & Color", page)
			tabs.set_on_change (agent on_tab_changed)
			create Result.make_striped (a_theme.warning)
			Result.put ((create {SW_LABEL}.make_ui ("SW_TABS %/8212/ pages swap; hover the bar")).as_muted)
			Result.put (tabs)
		end

	on_slider_moved (a_f: REAL_64)
		do
			progress.set_fraction (a_f)
			counter_label.set_text ("slider: " + ((a_f * 100.0).rounded).out + "%%")
		end

	on_number_changed (a_v: INTEGER)
		do
			counter_label.set_text ("number box: " + a_v.out)
		end

	on_tab_changed (a_i: INTEGER)
		do
			window.log_line ("demo: tab " + a_i.out)
		end

	list_card (a_theme: SW_THEME): SW_CARD
			-- Ten thousand agent-rendered rows; only the visible band
			-- ever draws.
		local
			lst: SW_LIST
		do
			create lst.make (170.0)
			lst.set_row_count (10000)
			lst.set_on_select (agent on_big_row)
			lst.set_row_height (30.0)
			lst.set_row_renderer (agent draw_demo_row)
			lst.set_on_select (agent on_row_selected)
			create Result.make_striped (a_theme.success)
			Result.put ((create {SW_LABEL}.make_ui ("SW_LIST %/8212/ 10,000 virtualized rows; wheel, click, drag the bar")).as_muted)
			Result.put (lst)
		end

	draw_demo_row (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
			-- One list row: index in mono, a phase tag, a thin baseline.
		do
			a_p.font ({SW_PAINTER}.Role_mono, 13.0, False)
			if a_i \\ 100 = 0 then
				a_p.set_color (a_p.theme.accent)
			else
				a_p.set_color (a_p.theme.ink)
			end
			a_p.text (a_x + 12.0, a_y + a_h - 9.0, "item " + a_i.out)
			a_p.font ({SW_PAINTER}.Role_ui, 11.0, False)
			a_p.set_color (a_p.theme.ink_muted)
			a_p.text (a_x + 140.0, a_y + a_h - 10.0, "virtualized %/8212/ only the visible band is drawn")
		end

	on_row_selected (a_i: INTEGER)
		do
			counter_label.set_text ("list row selected: " + a_i.out)
			window.log_line ("demo: list selected " + a_i.out)
		end

	stepper: SW_STEPPER

	accordion: SW_ACCORDION

	disclosure_card (a_theme: SW_THEME): SW_CARD
			-- Stepper, accordion (with a timeline inside), and the
			-- verbs that drive the process.
		local
			verbs: SW_ROW
			tl: SW_TIMELINE
			col: SW_COLUMN
		do
			stepper := stepper.with_step ("Capture").with_step ("OCR").with_step ("Export")
			stepper.set_current_step (2)
			stepper.set_on_change (agent on_step_changed)
			create verbs.make
			verbs.put (create {SW_BUTTON}.make ("Back", agent on_step_back))
			verbs.put (create {SW_BUTTON}.make_primary ("Advance", agent on_step_forward))
			create col.make
			col := col.with_gap (6.0)
			col.put (create {SW_LABEL}.make_body ("Sections disclose on demand; exclusive by default, so opening one closes the rest."))
			accordion.add_section ("Details", col)
			create tl.make
			tl.add_entry ("09:57", "Wave 2 back four shipped", "combo, toolbar, image, password eye", {SW_TIMELINE}.Kind_success)
			tl.add_entry ("11:20", "File dialogs landed", "sheet layer born", {SW_TIMELINE}.Kind_accent)
			tl.add_entry ("13:05", "Contract assault sealed the wave", "25/25 five times", {SW_TIMELINE}.Kind_success)
			tl.add_entry ("now", "Wave 3 disclosure batch", "", {SW_TIMELINE}.Kind_warning)
			accordion.add_section ("Timeline", tl)
			create col.make
			col.put ((create {SW_BUTTON}.make ("Dangerous thing", agent on_delete)).as_kind ({SW_BUTTON}.Kind_danger))
			accordion.add_section ("Danger zone", col)
			accordion.set_on_change (agent on_section_toggled)
			create Result.make_striped (a_theme.accent)
			Result.put ((create {SW_LABEL}.make_ui ("SW_STEPPER %/8212/ done steps are revisitable %/183/ SW_ACCORDION %/8212/ click the headers")).as_muted)
			Result.put (stepper)
			Result.put (verbs)
			Result.put (accordion)
		end

	on_step_changed (a_i: INTEGER)
		do
			statusbar.set_left ({STRING_32} "step " + a_i.out + {STRING_32} ": " + stepper.steps.i_th (a_i))
		end

	on_step_back
		do
			stepper.retreat
		end

	on_step_forward
		do
			stepper.advance
		end

	on_section_toggled (a_i: INTEGER)
		do
			if accordion.is_section_open (a_i) then
				statusbar.set_left ({STRING_32} "opened: " + accordion.sections.i_th (a_i).title)
			else
				statusbar.set_left ({STRING_32} "closed: " + accordion.sections.i_th (a_i).title)
			end
		end

	build_settings_drawer: SW_WIDGET
			-- Fresh drawer content per open - hover the edge tab to
			-- peek it, click the tab (or inside) to pin it.
		local
			d: SW_DRAWER
		do
			create d.make_titled ("Settings")
			d.set_on_close (agent on_drawer_close)
			d.put (create {SW_SWITCH}.make ("Live updates", True, Void))
			d.put (create {SW_SWITCH}.make ("Hover signals", True, Void))
			d.put (create {SW_SWITCH}.make ("Telemetry (decorative)", False, Void))
			d.put ((create {SW_LABEL}.make_body ("Hover the edge tab to peek; click to pin. A peeked drawer closes when the pointer leaves it.")))
			Result := d
		end

	on_open_drawer
		do
			window.show_drawer (build_settings_drawer, 300.0, True)
		end

	on_drawer_close
		do
			window.close_sheet
		end

	on_open_popover
		local
			col: SW_COLUMN
		do
			create col.make
			col := col.with_gap (8.0)
			col.put (create {SW_LABEL}.make_ui ("An anchored panel hosting real widgets:"))
			col.put (create {SW_RATING}.make (2, 5, Void))
			col.put ((create {SW_LABEL}.make_ui ("Click outside to dismiss.")).as_muted)
			window.show_popover (col, 96.0, 46.0, 260.0)
		end

	fleet_tree: SW_TREE [DEMO_NODE]

	color_picker: SW_COLOR_PICKER

	node_label (a_n: DEMO_NODE): STRING_32
		do
			Result := a_n.label
		end

	node_children (a_n: DEMO_NODE): ARRAYED_LIST [DEMO_NODE]
		do
			Result := a_n.children
		end

	build_fleet_forest: ARRAYED_LIST [DEMO_NODE]
		local
			w1, w2, w3: DEMO_NODE
		do
			create Result.make (3)
			create w1.make ("Wave 1 %/8212/ foundations")
			w1 := w1.with_child ("SW_WINDOW").with_child ("SW_TEXT_BOX").with_child ("SW_LIST").with_child ("SW_MENU")
			create w2.make ("Wave 2 %/8212/ form-complete")
			w2 := w2.with_child ("SW_COMBO").with_child ("SW_TOOLBAR").with_child ("SW_FILE_DIALOG")
			create w3.make ("Wave 3 %/8212/ the long tail")
			w3 := w3.with_child ("SW_DATA_GRID").with_child ("SW_CALENDAR").with_child ("SW_TREE").with_child ("SW_COLOR_PICKER")
			Result.extend (w1)
			Result.extend (w2)
			Result.extend (w3)
		end

	on_tree_selected (a_n: DEMO_NODE)
		do
			statusbar.set_left ({STRING_32} "tree: " + a_n.label)
		end

	on_color_changed (a_rgb: NATURAL_32)
		do
			statusbar.set_left ({STRING_32} "colour: " + color_picker.hex_text)
		end

	cal: SW_CALENDAR

	date_us, date_iso: SW_DATE_PICKER

	time_12, time_24: SW_TIME_PICKER

	on_calendar_picked (a_y, a_m, a_d: INTEGER)
		do
			statusbar.set_left ({STRING_32} "calendar: " + a_y.out + {STRING_32} "-" + a_m.out + {STRING_32} "-" + a_d.out)
		end

	on_date_changed (a_y, a_m, a_d: INTEGER)
		do
			statusbar.set_left ({STRING_32} "date picked: " + a_y.out + {STRING_32} "-" + a_m.out + {STRING_32} "-" + a_d.out)
		end

	fleet_grid: SW_DATA_GRID [TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]]

	grid_filter_box: SW_TEXT_BOX

	grid_name (a_r: TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]): STRING_32
		do
			Result := a_r.name
		end

	grid_wave_text (a_r: TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]): STRING_32
		do
			Result := a_r.wave.out.to_string_32
		end

	grid_wave_key (a_r: TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]): COMPARABLE
		do
			Result := a_r.wave
		end

	grid_category (a_r: TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]): STRING_32
		do
			Result := a_r.category
		end

	grid_row_passes (a_r: TUPLE [name: STRING_32; wave: INTEGER; category: STRING_32]): BOOLEAN
		do
			Result := grid_filter_box.text.is_empty
				or else a_r.name.as_lower.has_substring (grid_filter_box.text.as_lower)
				or else a_r.category.as_lower.has_substring (grid_filter_box.text.as_lower)
		end

	on_grid_filter_changed
		do
			fleet_grid.set_filter (agent grid_row_passes)
		end

	on_grid_row_selected (a_model: INTEGER)
		do
			statusbar.set_left ({STRING_32} "grid: " + fleet_grid.rows.i_th (a_model).name)
		end

	seed_fleet_grid
		local
			g: like fleet_grid
		do
			g := fleet_grid
			g.add_row ([{STRING_32} "SW_BUTTON", 1, {STRING_32} "input"])
			g.add_row ([{STRING_32} "SW_TEXT_BOX", 1, {STRING_32} "text engine"])
			g.add_row ([{STRING_32} "SW_LIST", 1, {STRING_32} "data"])
			g.add_row ([{STRING_32} "SW_MENU", 1, {STRING_32} "chrome"])
			g.add_row ([{STRING_32} "SW_SPLITTER", 1, {STRING_32} "layout"])
			g.add_row ([{STRING_32} "SW_COMBO", 2, {STRING_32} "input"])
			g.add_row ([{STRING_32} "SW_TOOLBAR", 2, {STRING_32} "chrome"])
			g.add_row ([{STRING_32} "SW_FILE_DIALOG", 2, {STRING_32} "dialogs"])
			g.add_row ([{STRING_32} "SW_IMAGE", 2, {STRING_32} "media"])
			g.add_row ([{STRING_32} "SW_RATING", 3, {STRING_32} "indicator"])
			g.add_row ([{STRING_32} "SW_ACCORDION", 3, {STRING_32} "disclosure"])
			g.add_row ([{STRING_32} "SW_DRAWER", 3, {STRING_32} "disclosure"])
			g.add_row ([{STRING_32} "SW_CANVAS", 3, {STRING_32} "custom drawing"])
			g.add_row ([{STRING_32} "SW_SHEET", 3, {STRING_32} "data"])
			g.add_row ([{STRING_32} "SW_DATA_GRID", 3, {STRING_32} "data - the crown"])
		end

	scroll_split_card (a_theme: SW_THEME): SW_CARD
			-- A splitter whose left pane is a selectable SW_LIST; every
			-- row also offers a pebble to the middle-click pick.
		local
			lst: SW_LIST
			right_col: SW_COLUMN
		do
			create lst.make (150.0)
			lst.set_row_count (24)
			lst.set_row_renderer (agent render_split_row)
			lst.set_row_pebble (agent split_row_pebble)
			lst.set_on_select (agent on_split_row)
			create right_col.make
			right_col := right_col.with_gap (8.0)
			right_col.put (create {SW_LABEL}.make_body ("The divider between these panes drags; the ratio is contract-clamped so neither side can vanish."))
			right_col.put (create {SW_CHIP}.make ("SW_SPLITTER + SW_SCROLL_AREA", {SW_CHIP}.Kind_accent))
			create Result.make_striped (a_theme.accent)
			Result.put ((create {SW_LABEL}.make_ui ("scroll and split %/8212/ click selects, wheel scrolls, middle-click picks")).as_muted)
			Result.put (create {SW_SPLITTER}.make (lst, right_col))
		end

	render_split_row (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			a_p.font ({SW_PAINTER}.Role_mono, 13.0, False)
			if a_i \\ 6 = 0 then
				a_p.set_color (a_p.theme.accent)
			else
				a_p.set_color (a_p.theme.ink)
			end
			a_p.text (a_x + 8.0, a_y + a_h - 9.0, "row " + (if a_i < 10 then "0" else "" end) + a_i.out + " %/8212/ select or middle-pick")
		end

	split_row_pebble (a_i: INTEGER): detachable ANY
		do
			Result := "[from row " + a_i.out + "] "
		end

	on_split_row (a_i: INTEGER)
		do
			statusbar.set_left ({STRING_32} "split list: row " + a_i.out + {STRING_32} " selected")
		end

	on_big_row (a_i: INTEGER)
		do
			statusbar.set_left ({STRING_32} "big list: item " + a_i.out + {STRING_32} " selected")
		end

feature {NONE} -- Behaviour

	window: SW_WINDOW

	counter_label: SW_LABEL

	clicks: INTEGER

	on_click_me
		do
			clicks := clicks + 1
			counter_label.set_text ("clicks: " + clicks.out + "  %/8212/ Click Me works!")
			progress.set_fraction ((clicks.to_double / 10.0).min (1.0))
			window.log_line ("demo: clicked " + clicks.out)
		end

	progress: SW_PROGRESS

	danger_button: SW_BUTTON

	menubar: SW_MENU_BAR

	statusbar: SW_STATUS_BAR

	file_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("New Session", "Ctrl+N", True, agent on_menu_new)
			Result.add_item ("Save", "Ctrl+S", True, agent on_menu_save)
			Result.add_item ("Open%/8230/", "", True, agent on_open_file)
			Result.add_item ("Save As%/8230/", "", True, agent on_save_file)
			Result.add_separator
			Result.add_item ("Quit (decorative)", "", False, Void)
		end

	widgets_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Toast the selected kind", "", True, agent on_toast)
			Result.add_item ("Open the danger dialog", "", True, agent on_delete)
			Result.add_item ("Toggle theme", "", True, agent on_toggle_theme)
			Result.add_item ("Open the drawer", "", True, agent on_open_drawer)
			Result.add_item ("Open a popover", "", True, agent on_open_popover)
		end

	help_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("About simple_widgets", "", True, agent on_about)
		end

	on_menu_new
		do
			window.toast ("New session %/8212/ decorative for now", 1)
			statusbar.set_left ("new session requested")
		end

	on_menu_save
		do
			window.toast ("Saved (nothing, honestly)", 2)
			statusbar.set_left ("save requested")
		end

	on_open_file
		local
			fd: SW_FILE_DIALOG
		do
			create fd.make_open ("D:/prod/simple_widgets")
			fd.set_on_accept (agent on_file_chosen)
			fd.set_on_cancel (agent on_file_cancelled)
			window.show_sheet (fd, 560.0)
		end

	on_save_file
		local
			fd: SW_FILE_DIALOG
		do
			create fd.make_save ("D:/prod/simple_widgets", "untitled.txt")
			fd.set_on_accept (agent on_file_chosen)
			fd.set_on_cancel (agent on_file_cancelled)
			window.show_sheet (fd, 560.0)
		end

	on_file_chosen (a_path: STRING_32)
		do
			window.close_sheet
			statusbar.set_left ({STRING_32} "file: " + a_path)
			window.toast ({STRING_32} "Chosen: " + a_path, 2)
		end

	on_file_cancelled
		do
			window.close_sheet
		end

	on_about
		local
			d: SW_DIALOG
		do
			create d.make ({SW_DIALOG}.Kind_info, "simple_widgets",
				"A drawn widget toolkit for Eiffel on pure Win32 %/8212/ no Vision2, no GTK, no native controls. Every pixel here, including this dialog and the menu you just used, is painted by the toolkit itself.")
			d.add_button ("Nice", True, Void)
			window.show_dialog (d)
		end

	seg: SW_SEGMENTED

	rating: SW_RATING

	on_view_changed (a_i: INTEGER)
		do
			statusbar.set_left ({STRING_32} "view: " + seg.selected_text)
		end

	on_rated (a_v: INTEGER)
		do
			statusbar.set_left ({STRING_32} "rated " + a_v.out + {STRING_32} " of 5")
		end

	on_empty_action
		do
			window.toast ("The first thing exists now", 2)
		end

	combo: SW_COMBO

	toolbar: SW_TOOLBAR

	on_combo_changed
		do
			statusbar.set_left ({STRING_32} "combo: " + combo.text)
		end

	on_tool_flip
		do
			statusbar.set_right ({STRING_32} "bold " + on_off (toolbar.is_tool_on ("Bold"))
				+ {STRING_32} " %/183/ italic " + on_off (toolbar.is_tool_on ("Italic")))
		end

	on_off (a_on: BOOLEAN): STRING_32
		do
			if a_on then
				Result := {STRING_32} "on"
			else
				Result := {STRING_32} "off"
			end
		end

	kind_select: SW_SELECT

	on_kind_changed
			-- The choice speaks for itself: preview the chosen kind.
		do
			window.toast ({STRING_32} "" + kind_select.selected_text + " selected %/8212/ toasts of this kind look like me", kind_select.selected_index.max (1))
		end

	on_toast
		do
			window.toast ({STRING_32} "A " + kind_select.selected_text + " toast %/8212/ drawn, queued, fading",
				kind_select.selected_index.max (1))
		end

	on_delete
		local
			d: SW_DIALOG
		do
			create d.make ({SW_DIALOG}.Kind_danger, "Delete everything?",
				"This is the toolkit%'s own drawn modal over a dimmed backdrop %/8212/ no MessageBox anywhere in the process. Nothing will actually be deleted.")
			d.add_button ("Cancel", False, agent on_kept)
			d.add_button ("Delete", True, agent on_deleted)
			window.show_dialog (d)
		end

	on_deleted
		do
			window.toast ("Deleted! (not really)", 4)
		end

	on_kept
		do
			window.toast ("Kept. Wise.", 1)
		end

	on_toggle_danger
		do
			danger_button.set_enabled (not danger_button.is_enabled)
			counter_label.set_text ("Danger " + (if danger_button.is_enabled then "armed" else "disarmed" end))
			window.log_line ("demo: danger toggled")
		end

	on_log_only
		do
			counter_label.set_text ("Log Only pressed %/8212/ also wrote sw_session.log")
			window.log_line ("demo: log-only button")
		end

	edit_box: SW_TEXT_BOX

	on_text_changed
		do
			window.log_line ("demo: text now " + edit_box.text.count.out + " chars")
		end

	is_light: BOOLEAN

	on_toggle_theme
		local
			th: SW_THEME
		do
			is_light := not is_light
			if is_light then
				create th.make_light
			else
				create th.make_dark
			end
			window.set_theme (th)
			counter_label.set_text ("theme: " + (if is_light then "light" else "dark" end))
			window.log_line ("demo: theme toggled")
		end



end
