note
	description: "[
		Assault on state control by agent collection (the Vision2
		sensitivity idiom, Larry's call): enabling conditions install
		and apply immediately, refresh_enabling walks the sub_widgets
		spine so one pass covers a whole face, and menu-bar pads grey
		and deafen on their own conditions - queried live.
	]"

class
	SW_STATE_CONTROL_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- The mutable world the conditions close over

	armed: BOOLEAN

	armed_now: BOOLEAN
		do
			Result := armed
		end

	fresh_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("noop", "", True, Void)
		end

feature -- Tests

	test_enabled_when_applies_immediately
		local
			b: SW_BUTTON
		do
			armed := False
			create b.make ("target", Void)
			assert ("buttons start enabled", b.is_enabled)
			b.set_enabled_when (agent armed_now)
			assert ("the verdict lands at install", not b.is_enabled)
			armed := True
			assert ("no refresh yet: still off", not b.is_enabled)
			b.refresh_enabling
			assert ("refresh applies the new truth", b.is_enabled)
		end

	test_refresh_walks_the_sub_widget_spine
		local
			col: SW_COLUMN
			row: SW_ROW
			deep: SW_BUTTON
		do
			armed := False
			create col.make
			create row.make
			create deep.make ("deep", Void)
			deep.set_enabled_when (agent armed_now)
			row.put (deep)
			col.put (row)
			assert ("installed off", not deep.is_enabled)
			armed := True
			col.refresh_enabling
			assert ("one walk from the root reaches the leaf", deep.is_enabled)
			armed := False
			col.refresh_enabling
			assert ("and back off again", not deep.is_enabled)
		end

	test_menubar_pad_conditions
		local
			mb: SW_MENU_BAR
		do
			armed := False
			create mb.make
			mb.add_menu ("Always", agent fresh_menu)
			mb.add_menu_when ("Gated", agent fresh_menu, agent armed_now)
			assert ("unconditioned pad is enabled", mb.pad_enabled (1))
			assert ("gated pad obeys: off", not mb.pad_enabled (2))
			armed := True
			assert ("gated pad obeys: on (queried live)", mb.pad_enabled (2))
		end

end
