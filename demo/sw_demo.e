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
		do
			create theme.make_light
			create counter_label.make ("clicks: 0  %/8212/ buttons report HERE", {SW_PAINTER}.Role_mono, 14.0, True)
			create edit_box.make ("The quick brown fox jumps over the lazy dog, and keeps on running until the wrap engine breaks the line exactly where the measured advances say it must.")
			create window.make ("simple_widgets demo", 8, 8, 900, 560, theme)
			window.add_font ("D:\prod\simple_narrate\fonts\Archivo.ttf").do_nothing
			window.add_font ("D:\prod\simple_narrate\fonts\Literata.ttf").do_nothing
			window.add_font ("D:\prod\simple_narrate\fonts\IBMPlexMono.ttf").do_nothing
			window.set_frame_echo ("sw_demo_frame.png")

			create root.make
			root := root.with_padding (16.0).with_gap (14.0)

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
			create buttons.make
			buttons.put (create {SW_BUTTON}.make_primary ("Click Me", agent on_click_me))
			buttons.put (create {SW_BUTTON}.make ("Log Only", agent on_log_only))
			buttons.put ((create {SW_BUTTON}.make ("Disabled", Void)).disabled)
			card.put (buttons)
			root.put (card)

			create card.make_striped (theme.warning)
			card.put ((create {SW_LABEL}.make_ui ("SW_TEXT_BOX %/8212/ click, drag, double-click, shift+arrows, type")).as_muted)
			edit_box.set_on_change (agent on_text_changed)
			card.put (edit_box)
			root.put (card)

			window.set_root (root)
			window.run
		end

feature {NONE} -- Behaviour

	window: SW_WINDOW

	counter_label: SW_LABEL

	clicks: INTEGER

	on_click_me
		do
			clicks := clicks + 1
			counter_label.set_text ("clicks: " + clicks.out + "  %/8212/ Click Me works!")
			window.log_line ("demo: clicked " + clicks.out)
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

end
