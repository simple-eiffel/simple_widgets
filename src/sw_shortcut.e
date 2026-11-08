note
	description: "[
		A keyboard shortcut written the platform-neutral way simple_gui writes it (W8):
		"primary+O", "primary+shift+Z", "alt+F4", "F5". "primary" is Control on Windows
		and Linux (Command on macOS); "ctrl" and "control" mean the same here. The key is
		one letter or digit, F1 to F12, or a name: Delete, Escape, Enter, Tab, Space, Home,
		End, PageUp, PageDown, Left, Up, Right, Down, Insert, Backspace, plus, minus,
		comma, period. Case does not matter.

		Answers the virtual key and modifiers SW_WINDOW.register_accelerator takes, and
		the text a menu shows beside the item ("Ctrl+Shift+Z").
	]"

class
	SW_SHORTCUT

create
	make

feature {NONE} -- Initialization

	make (a_spec: READABLE_STRING_GENERAL)
			-- Read `a_spec'; `is_valid' tells whether it named a key.
		local
			l_parts: LIST [STRING_32]
			l_part: STRING_32
			i: INTEGER
			l_bad: BOOLEAN
		do
			spec := a_spec.to_string_32
			l_parts := a_spec.to_string_32.split ('+')
			from
				i := 1
			until
				i > l_parts.count or l_bad
			loop
				l_part := l_parts.i_th (i).as_lower
				l_part.adjust
				if i < l_parts.count then
					if l_part.same_string ("primary") or l_part.same_string ("ctrl") or l_part.same_string ("control") then
						has_control := True
					elseif l_part.same_string ("shift") then
						has_shift := True
					elseif l_part.same_string ("alt") then
						has_alt := True
					else
						l_bad := True
					end
				else
					vk := key_code (l_part)
				end
				i := i + 1
			end
			if l_bad then
				vk := 0
			end
		ensure
			kept: spec.same_string_general (a_spec)
		end

feature -- Access

	spec: STRING_32
			-- As written.

	vk: INTEGER
			-- The Windows virtual key; 0 when `spec' named none.

	has_control, has_shift, has_alt: BOOLEAN

	is_valid: BOOLEAN
			-- Did `spec' name a key (with known modifiers)?
		do
			Result := vk > 0
		end

	is_function_key: BOOLEAN
		do
			Result := vk >= 112 and vk <= 123
		end

	is_registrable: BOOLEAN
			-- Can SW_WINDOW.register_accelerator take it: Control or Alt held, or a function
			-- key (a bare letter would take the letter out of every text box)?
		do
			Result := is_valid and (has_control or has_alt or is_function_key)
		end

	display_text: STRING_32
			-- What a menu shows beside the item: "Ctrl+Shift+Z", "Alt+F4", "F5".
		require
			valid: is_valid
		do
			create Result.make (16)
			if has_control then
				Result.append ({STRING_32} "Ctrl+")
			end
			if has_alt then
				Result.append ({STRING_32} "Alt+")
			end
			if has_shift then
				Result.append ({STRING_32} "Shift+")
			end
			Result.append (key_name)
		ensure
			ends_with_the_key: Result.ends_with (key_name)
		end

	key_name: STRING_32
			-- The key's own name as Windows menus print it.
		require
			valid: is_valid
		do
			if (vk >= 65 and vk <= 90) or (vk >= 48 and vk <= 57) then
				create Result.make_filled (vk.to_character_32, 1)
			elseif is_function_key then
				Result := {STRING_32} "F" + (vk - 111).out.to_string_32
			elseif attached named_keys.item (vk) as al_name then
				Result := al_name
			else
				Result := vk.out.to_string_32
			end
		end

feature {NONE} -- Implementation

	key_code (a_name: STRING_32): INTEGER
			-- The virtual key `a_name' (lowercase, trimmed) names; 0 for none.
		local
			c: CHARACTER_32
		do
			if a_name.count = 1 then
				c := a_name.item (1).as_upper
				if (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') then
					Result := c.code
				elseif c = '+' or c = '=' then
					Result := 0xBB
				elseif c = '-' then
					Result := 0xBD
				elseif c = ',' then
					Result := 0xBC
				elseif c = '.' then
					Result := 0xBE
				end
			elseif a_name.count >= 2 and then a_name.item (1) = 'f' and then a_name.substring (2, a_name.count).is_integer then
				if a_name.substring (2, a_name.count).to_integer >= 1 and a_name.substring (2, a_name.count).to_integer <= 12 then
					Result := 111 + a_name.substring (2, a_name.count).to_integer
				end
			elseif aliases.has (a_name) then
				Result := aliases.item (a_name)
			else
				from
					named_keys.start
				until
					named_keys.after or Result /= 0
				loop
					if named_keys.item_for_iteration.as_lower.same_string (a_name) then
						Result := named_keys.key_for_iteration
					end
					named_keys.forth
				end
			end
		end

	named_keys: HASH_TABLE [STRING_32, INTEGER]
			-- Virtual key -> the name Windows menus print.
		once
			create Result.make (20)
			Result.put ("Backspace", 8)
			Result.put ("Tab", 9)
			Result.put ("Enter", 13)
			Result.put ("Esc", 27)
			Result.put ("Space", 32)
			Result.put ("PgUp", 33)
			Result.put ("PgDn", 34)
			Result.put ("End", 35)
			Result.put ("Home", 36)
			Result.put ("Left", 37)
			Result.put ("Up", 38)
			Result.put ("Right", 39)
			Result.put ("Down", 40)
			Result.put ("Ins", 45)
			Result.put ("Del", 46)
			Result.put ("+", 0xBB)
			Result.put (",", 0xBC)
			Result.put ("-", 0xBD)
			Result.put (".", 0xBE)
		end

	aliases: HASH_TABLE [INTEGER, STRING_32]
			-- Other spellings of the named keys (lowercase).
		once
			create Result.make (16)
			Result.put (13, "return")
			Result.put (27, "escape")
			Result.put (33, "pageup")
			Result.put (34, "pagedown")
			Result.put (45, "insert")
			Result.put (46, "delete")
			Result.put (0xBB, "plus")
			Result.put (0xBB, "equal")
			Result.put (0xBD, "minus")
			Result.put (0xBC, "comma")
			Result.put (0xBE, "period")
		end

invariant
	spec_exists: spec /= Void
	non_negative_key: vk >= 0

end
