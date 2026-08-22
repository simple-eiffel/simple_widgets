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

			root.put (create {SW_LABEL}.make ("simple_widgets", {SW_PAINTER}.Role_ui, 20.0, True))
			root.put ((create {SW_LABEL}.make_mono ("the toolkit above simple_cairo %/183/ no Vision2 %/183/ no boilerplate")).as_muted)

			create card.make_striped (theme.success)
			card.put (create {SW_LABEL}.make_body ("Every colour, face and metric here comes from the theme; every position from the layout."))
			create chips.make
			chips.put (create {SW_CHIP}.make ("NEUTRAL", {SW_CHIP}.Kind_neutral))
			chips.put (create {SW_CHIP}.make ("RENDERED", {SW_CHIP}.Kind_accent))
			chips.put (create {SW_CHIP}.make ("APPROVED", {SW_CHIP}.Kind_success))
			chips.put (create {SW_CHIP}.make ("DIRTY", {SW_CHIP}.Kind_warning))
			chips.put (create {SW_CHIP}.make ("FAILED", {SW_CHIP}.Kind_danger))
			card.put (chips)
			root.put (card)

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
			root.put (card)

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
			root.put (card)

			root.put (scroll_split_card (theme))
			root.put (tabs_card (theme))
			root.put (list_card (theme))
			statusbar.set_left ("ready %/8212/ every pixel drawn by simple_widgets")
			statusbar.set_right ("36 widgets and counting")
			root.put (create {SW_SPACER}.make)
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

	scroll_split_card (a_theme: SW_THEME): SW_CARD
			-- A splitter whose left pane scrolls 24 rows in a viewport.
		local
			tall, right_col: SW_COLUMN
			sa: SW_SCROLL_AREA
			i: INTEGER
			lbl: SW_LABEL
		do
			create tall.make
			tall := tall.with_gap (6.0)
			from
				i := 1
			until
				i > 24
			loop
				create lbl.make_mono ("row " + (if i < 10 then "0" else "" end) + i.out + "  %/8212/  middle-click picks me")
				if i \\ 6 = 0 then
					lbl.set_color (a_theme.accent)
				end
				lbl.set_pebble ("[from row " + i.out + "] ")
				tall.put (lbl)
				i := i + 1
			end
			create sa.make (150.0)
			sa.set_child (tall)
			create right_col.make
			right_col := right_col.with_gap (8.0)
			right_col.put (create {SW_LABEL}.make_body ("The divider between these panes drags; the ratio is contract-clamped so neither side can vanish."))
			right_col.put (create {SW_CHIP}.make ("SW_SPLITTER + SW_SCROLL_AREA", {SW_CHIP}.Kind_accent))
			create Result.make_striped (a_theme.accent)
			Result.put ((create {SW_LABEL}.make_ui ("scroll and split %/8212/ clipped, wheeled, dragged")).as_muted)
			Result.put (create {SW_SPLITTER}.make (sa, right_col))
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
			Result.add_separator
			Result.add_item ("Quit (decorative)", "", False, Void)
		end

	widgets_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Toast the selected kind", "", True, agent on_toast)
			Result.add_item ("Open the danger dialog", "", True, agent on_delete)
			Result.add_item ("Toggle theme", "", True, agent on_toggle_theme)
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

	on_about
		local
			d: SW_DIALOG
		do
			create d.make ({SW_DIALOG}.Kind_info, "simple_widgets",
				"A drawn widget toolkit for Eiffel on pure Win32 %/8212/ no Vision2, no GTK, no native controls. Every pixel here, including this dialog and the menu you just used, is painted by the toolkit itself.")
			d.add_button ("Nice", True, Void)
			window.show_dialog (d)
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
