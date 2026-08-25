note
	description: "[
		A drawn modal dialog (R7: never MessageBox): kind-striped card
		centered over a dimmed backdrop, a title, a word-wrapped
		message, and a row of buttons carrying action agents. The
		window owns modality: while a dialog is up, it swallows all
		input except its buttons and Escape.
	]"

class
	SW_DIALOG

create
	make

feature -- Kinds (semantic, matching chip vocabulary)

	Kind_info: INTEGER = 1
	Kind_success: INTEGER = 2
	Kind_warning: INTEGER = 3
	Kind_danger: INTEGER = 4

feature {NONE} -- Initialization

	make (a_kind: INTEGER; a_title, a_message: READABLE_STRING_GENERAL)
		require
			kind_known: a_kind >= Kind_info and a_kind <= Kind_danger
		do
			kind := a_kind
			create title.make_from_string_general (a_title)
			create message.make_from_string_general (a_message)
			create buttons.make (2)
			create zones.make (2)
			create wrapped.make (4)
		ensure
			kind_set: kind = a_kind
		end

feature -- Access

	kind: INTEGER
	title: STRING_32
	message: STRING_32
	buttons: ARRAYED_LIST [TUPLE [label: STRING_32; is_primary: BOOLEAN; action: detachable PROCEDURE]]

	x, y, width, height: REAL_64

feature -- Element change

	add_button (a_label: READABLE_STRING_GENERAL; a_primary: BOOLEAN; a_action: detachable PROCEDURE)
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			buttons.extend ([l, a_primary, a_action])
		ensure
			grew: buttons.count = old buttons.count + 1
		end

feature -- Geometry

	measure (a_p: SW_PAINTER; a_win_w, a_win_h: REAL_64)
			-- Wrap the message, size the card, centre it. '%N' breaks
			-- a line and a blank line stands as a paragraph gap - it
			-- used to survive word-splitting and draw as a missing
			-- glyph (the 1.9.0 About tofu).
		local
			max_w, cx, ww: REAL_64
			paragraphs, words: LIST [STRING_32]
			line: STRING_32
		do
			width := (a_win_w - 120.0).min (540.0).max (300.0)
			max_w := width - 2.0 * Pad
			wrapped.wipe_out
			a_p.font ({SW_PAINTER}.Role_body, 12.5, False)
			paragraphs := message.split ('%N')
			across
				paragraphs as p
			loop
				if p.is_empty then
					wrapped.extend (create {STRING_32}.make_empty)
				else
					words := p.split (' ')
					create line.make (80)
					across
						words as w
					loop
						ww := a_p.advance (w)
						if line.is_empty then
							line := w.twin
							cx := ww
						elseif cx + Space_w + ww > max_w then
							wrapped.extend (line)
							line := w.twin
							cx := ww
						else
							line.append_character (' ')
							line.append (w)
							cx := cx + Space_w + ww
						end
					end
					if not line.is_empty then
						wrapped.extend (line)
					end
				end
			end
			height := Pad + 30.0 + wrapped.count * 22.0 + 18.0 + 34.0 + Pad
			x := (a_win_w - width) / 2.0
			y := ((a_win_h - height) / 2.0).max (24.0)
		ensure
			wrapped_something: message.is_empty or else not wrapped.is_empty
			sized: width > 0.0 and height > 0.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			by, bx, bw: REAL_64
			i: INTEGER
			b: TUPLE [label: STRING_32; is_primary: BOOLEAN; action: detachable PROCEDURE]
			stripe: NATURAL_32
		do
			t := a_p.theme
			inspect kind
			when 2 then
				stripe := t.success
			when 3 then
				stripe := t.warning
			when 4 then
				stripe := t.danger
			else
				stripe := t.accent
			end
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, 5.0)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, 5.0)
			a_p.set_color (stripe)
			a_p.fill_rect (x, y + 4.0, 4.0, height - 8.0)

			a_p.font ({SW_PAINTER}.Role_ui, 14.5, True)
			a_p.set_color (t.ink)
			a_p.text (x + Pad, y + Pad + 14.0, title)

			a_p.font ({SW_PAINTER}.Role_body, 12.5, False)
			a_p.set_color (t.ink)
			from
				i := 1
			until
				i > wrapped.count
			loop
				a_p.text (x + Pad, y + Pad + 30.0 + i * 22.0 - 6.0, wrapped.i_th (i))
				i := i + 1
			end

			zones.wipe_out
			by := y + height - Pad - 32.0
			bx := x + width - Pad
			from
				i := buttons.count
			until
				i < 1
			loop
				b := buttons.i_th (i)
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				bw := a_p.advance (b.label) + 24.0
				bx := bx - bw
				a_p.set_color (t.surface)
				a_p.rrect_fill (bx, by, bw, 32.0, t.radius)
				if b.is_primary then
					a_p.set_color (stripe)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_stroke (bx + 0.5, by + 0.5, bw - 1.0, 31.0, t.radius)
				if b.is_primary then
					a_p.set_color (stripe)
				else
					a_p.set_color (t.ink)
				end
				a_p.text (bx + 12.0, by + 21.0, b.label)
				zones.extend ([bx, by, bw, 32.0, i])
				bx := bx - 8.0
				i := i - 1
			end
		end

feature -- Interaction

	button_at (a_px, a_py: REAL_64): INTEGER
			-- 1-based button index under the point; 0 = none.
		do
			across
				zones as z
			loop
				if a_px >= z.zx and then a_px <= z.zx + z.zw
					and then a_py >= z.zy and then a_py <= z.zy + z.zh
				then
					Result := z.idx
				end
			end
		ensure
			valid: Result >= 0 and Result <= buttons.count
		end

	contains (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := a_px >= x and then a_px <= x + width
				and then a_py >= y and then a_py <= y + height
		end

feature {NONE} -- Implementation

	Pad: REAL_64 = 18.0
	Space_w: REAL_64 = 4.5

	wrapped: ARRAYED_LIST [STRING_32]

	zones: ARRAYED_LIST [TUPLE [zx, zy, zw, zh: REAL_64; idx: INTEGER]]

invariant
	title_attached: title /= Void
	message_attached: message /= Void
	buttons_attached: buttons /= Void
	kind_valid: kind >= Kind_info and kind <= Kind_danger

end
