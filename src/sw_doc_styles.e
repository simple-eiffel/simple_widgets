note
	description: "[
		How a simple_document DOC_TEXT is set by the shaper: each maximal
		stretch of one setting (DOC_TEXT.flags_at, stretch_end) becomes
		one SHAPING_STYLES span with its whole setting - bold at weight
		700, italic, small capitals, superscript raised small - and an
		INK made of its link, code and strikethrough bits, so the shaper
		cuts the runs wherever one of those changes and a paint hook can
		colour a link, wash code or strike a run, one run at a time.
		Shared by every widget that draws DOC_TEXT (SW_DOCUMENT_VIEW
		first).
	]"
	author: "Larry Rix"

class
	SW_DOC_STYLES

feature -- Access

	styles_of (a_text: DOC_TEXT): SHAPING_STYLES
			-- `a_text''s spans, flattened for the shaper.
		local
			i, e, f: INTEGER
			l_super: BOOLEAN
		do
			create Result.make
			if a_text.span_count > 0 then
				from
					i := 1
				until
					i > a_text.count
				loop
					f := a_text.flags_at (i)
					e := a_text.stretch_end (i)
					if f /= 0 then
						l_super := f & {DOC_TEXT}.Flag_superscript /= 0
						Result.add_setting (i, e - i + 1,
							if l_super then Result.Superscript_scale else 1.0 end,
							if l_super then Result.Superscript_rise else 0.0 end,
							f & {DOC_TEXT}.Flag_small_caps /= 0,
							if f & {DOC_TEXT}.Flag_bold /= 0 then Result.Weight_bold else 0 end,
							f & {DOC_TEXT}.Flag_italic /= 0,
							ink_of (f))
					end
					i := e + 1
				end
			end
		ensure
			plain_is_empty: a_text.span_count = 0 implies Result.is_empty
		end

	ink_of (a_flags: INTEGER): INTEGER
			-- The ink a stretch with `a_flags' is set in: its link, code and
			-- strikethrough bits (0: none of them).
		do
			Result := a_flags & Painted_flags
		ensure
			non_negative: Result >= 0
		end

	Painted_flags: INTEGER
			-- The flags a paint hook draws, not the shaper.
		once
			Result := {DOC_TEXT}.Flag_link | {DOC_TEXT}.Flag_code | {DOC_TEXT}.Flag_strike
		end

end
