note
	description: "[
		The system clipboard, as text. A SURFACE-layer service: widgets
		use it so applications never declare the externals.
	]"

class
	SW_CLIPBOARD

feature -- Access

	text: STRING_32
			-- Clipboard content as text; empty when none.
		local
			buf: MANAGED_POINTER
			n, i: INTEGER
			c: NATURAL_16
		do
			create Result.make_empty
			create buf.make (Buffer_bytes)
			n := c_clip_get (buf.item, Buffer_bytes // 2)
			from
				i := 0
			until
				i >= n
			loop
				c := buf.read_natural_16 (i * 2)
				if c >= 0xD800 and c <= 0xDBFF and i + 1 < n then
						-- surrogate pair: one code point across two units (R8)
					Result.append_code (0x10000
						+ (c.to_natural_32 - 0xD800) * 0x400
						+ (buf.read_natural_16 ((i + 1) * 2).to_natural_32 - 0xDC00))
					i := i + 2
				else
					Result.append_character (c.to_character_32)
					i := i + 1
				end
			end
		end

	has_text: BOOLEAN
		do
			Result := c_clip_has_text = 1
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
		local
			ns: NATIVE_STRING
		do
			create ns.make (a_text)
			c_clip_set (ns.item).do_nothing
		end

feature {NONE} -- Implementation

	Buffer_bytes: INTEGER = 262144
			-- 128k characters of paste is plenty for a text box.

feature {NONE} -- Externals

	c_clip_set (a_s: POINTER): INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_clip_set((const wchar_t*)$a_s);"
		end

	c_clip_get (a_buf: POINTER; a_cap: INTEGER): INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_clip_get((wchar_t*)$a_buf, (int)$a_cap);"
		end

	c_clip_has_text: INTEGER
		external
			"C inline use %"simple_widgets.h%""
		alias
			"return sw_clip_has_text();"
		end

end
