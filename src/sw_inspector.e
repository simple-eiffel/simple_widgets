note
	description: "[
		The dev-mode reveal: a fresh column describing one widget -
		its class (generating_type), bounds, layout hints, state
		flags, parent chain, creator dev_note, and a REFLECTOR
		attribute dump (the props pane reflection gives for free).
		Presented as a popover by the window when dev mode is on and
		a widget is right-clicked. The force-directed mesh is the
		next movement of this suite (S02 holds the score).
	]"

class
	SW_INSPECTOR

inherit
	SW_COLUMN

create
	make_for

feature {NONE} -- Initialization

	make_for (a_subject: SW_WIDGET)
		do
			make
			subject := a_subject
			gap := 2.0
			build_lines
		ensure
			aimed: subject = a_subject
		end

feature -- Access

	subject: SW_WIDGET

	line_count: INTEGER
		do
			Result := children.count
		end

	summary: STRING_32
			-- The headline: class plus geometry - testable truth.
		do
			Result := subject.generating_type.name_32.twin
			Result.append ({STRING_32} "  ")
			Result.append (subject.width.rounded.out)
			Result.append_character ('x')
			Result.append (subject.height.rounded.out)
			Result.append ({STRING_32} " @ ")
			Result.append (subject.x.rounded.out)
			Result.append_character (',')
			Result.append (subject.y.rounded.out)
		end

feature {NONE} -- Building

	build_lines
		local
			flags, chain: STRING_32
			w: detachable SW_WIDGET
			r: REFLECTED_REFERENCE_OBJECT
			i, shown: INTEGER
			line: STRING_32
		do
			put ((create {SW_LABEL}.make (summary, {SW_PAINTER}.Role_mono, 14.0, True)))
			create flags.make (40)
			flags.append ({STRING_32} "grow ")
			flags.append (subject.grow.out)
			if not subject.is_enabled then
				flags.append ({STRING_32} "  DISABLED")
			end
			if subject.is_focused then
				flags.append ({STRING_32} "  focused")
			end
			if subject.is_hovered then
				flags.append ({STRING_32} "  hovered")
			end
			put ((create {SW_LABEL}.make_mono (flags)).as_muted)
			create chain.make (60)
			chain.append ({STRING_32} "under: ")
			from
				w := subject.parent
			until
				w = Void
			loop
				chain.append (w.generating_type.name_32)
				w := w.parent
				if w /= Void then
					chain.append ({STRING_32} " < ")
				end
			end
			if chain.count > 7 then
				put ((create {SW_LABEL}.make_mono (chain)).as_muted)
			end
			if attached subject.dev_note as note_text then
				put (create {SW_LABEL}.make_mono ({STRING_32} "note: " + note_text))
			end
			put (create {SW_SEPARATOR}.make)
				-- the props pane reflection gives for free
			create r.make (subject)
			from
				i := 1
			until
				i > r.field_count or shown >= 14
			loop
				create line.make (48)
				line.append_string_general (r.field_name (i))
				line.append ({STRING_32} " = ")
				line.append (field_text (r, i))
				put ((create {SW_LABEL}.make_mono (line)).as_muted)
				shown := shown + 1
				i := i + 1
			end
			if r.field_count > shown then
				put ((create {SW_LABEL}.make_mono ({STRING_32} "... "
					+ (r.field_count - shown).out + {STRING_32} " more fields")).as_muted)
			end
		end

	field_text (r: REFLECTED_REFERENCE_OBJECT; i: INTEGER): STRING_32
			-- A one-line rendering of field `i': value for basics,
			-- class name for references, Void honestly.
		do
			create Result.make (24)
			if r.field_type (i) = {REFLECTOR_CONSTANTS}.integer_32_type then
				Result.append (r.integer_32_field (i).out)
			elseif r.field_type (i) = {REFLECTOR_CONSTANTS}.boolean_type then
				Result.append (r.boolean_field (i).out)
			elseif r.field_type (i) = {REFLECTOR_CONSTANTS}.real_64_type then
				Result.append (r.real_64_field (i).out)
			elseif r.field_type (i) = {REFLECTOR_CONSTANTS}.natural_32_type then
				Result.append ({STRING_32} "0x" + r.natural_32_field (i).to_hex_string)
			elseif r.field_type (i) = {REFLECTOR_CONSTANTS}.reference_type then
				if attached r.reference_field (i) as v then
					if attached {READABLE_STRING_GENERAL} v as s then
						Result.append_character ('"')
						Result.append_string_general (s.substring (1, s.count.min (24)))
						Result.append_character ('"')
					else
						Result.append (v.generating_type.name_32)
					end
				else
					Result.append ({STRING_32} "Void")
				end
			else
				Result.append ({STRING_32} "(basic)")
			end
		end

invariant
	aimed: subject /= Void

end
