note
	description: "[
		A widget that exists to be right-clicked: it draws a plain ground
		and offers a context menu of nothing but emoji labels.

		WHY A FIXTURE AND NOT SW_CHAT_THREAD. The eight-emoji reaction
		picker that found this defect is simple_chat's menu, not the
		toolkit's - SW_CHAT_THREAD's own `context_menu' is Copy and two
		selection commands, all Latin. Reaching for it would have proven
		the toy path still draws Latin. This offers the menu the consumer
		actually opens, so `simulate_context_click' presents exactly the
		popup that came up as eight empty boxes.
	]"
	author: "Larry Rix"

class
	SW_EMOJI_MENU_PROBE

inherit
	SW_WIDGET
		redefine
			context_menu
		end

create
	make

feature {NONE} -- Initialization

	make
			-- A probe offering nothing yet.
		do
			create labels.make (8)
		ensure
			nothing_offered: labels.is_empty
		end

feature -- Access

	labels: ARRAYED_LIST [STRING_32]
			-- The item labels the offered menu will carry, in order.

feature -- Element change

	add_label (a_label: READABLE_STRING_GENERAL)
			-- Offer one more item labelled `a_label'.
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_label)
			labels.extend (s)
		ensure
			grew: labels.count = old labels.count + 1
		end

feature -- Input

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- One enabled item per label, no shortcuts, no separators -
			-- the shape of a reaction picker.
		local
			m: SW_MENU
		do
			create m.make
			across
				labels as l
			loop
				m.add_item (l, "", True, Void)
			end
			Result := m
		ensure then
			offered: Result /= Void
			one_item_per_label: attached Result as al implies al.items.count = labels.count
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 120.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- A flat ground, so the frame under the popup is the theme's
			-- and not whatever the surface was allocated with.
		do
			a_p.set_color (a_p.theme.background)
			a_p.fill_rect (x, y, width, height)
		end

invariant
	labels_attached: labels /= Void

end
