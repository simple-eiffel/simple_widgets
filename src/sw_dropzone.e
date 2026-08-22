note
	description: "[
		A drawn target for files dragged from the shell: tray glyph,
		invitation text, hover accent. WM_DROPFILES delivers only
		the final drop (no drag-over tracking - that is OLE DnD,
		a future), so the zone brightens on mouse hover and speaks
		through on_drop when paths land.
	]"

class
	SW_DROPZONE

inherit
	SW_WIDGET
		redefine
			accepts_files, receive_files
		end

create
	make

feature {NONE} -- Initialization

	make (a_invitation: READABLE_STRING_GENERAL)
		do
			create invitation.make_from_string_general (a_invitation)
			create last_paths.make (0)
		ensure
			invited: invitation.same_string_general (a_invitation)
		end

feature -- Access

	invitation: STRING_32

	on_drop: detachable PROCEDURE [ARRAYED_LIST [STRING_32]]

	last_paths: ARRAYED_LIST [STRING_32]
			-- What the most recent drop delivered.

feature -- Element change

	set_on_drop (a_action: PROCEDURE [ARRAYED_LIST [STRING_32]])
		do
			on_drop := a_action
		ensure
			set: on_drop = a_action
		end

feature -- Files

	accepts_files: BOOLEAN
		do
			Result := is_enabled
		end

	receive_files (a_paths: ARRAYED_LIST [STRING_32]; a_px, a_py: REAL_64)
		do
			last_paths := a_paths
			if attached on_drop as a then
				a.call (a_paths)
			end
		ensure then
			kept: last_paths = a_paths
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 92.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cx: REAL_64
		do
			t := a_p.theme
			if shows_hover then
				a_p.set_color (t.wash_accent)
			else
				a_p.set_color (t.surface_variant)
			end
			a_p.rrect_fill (x, y, width, height, t.radius + 2.0)
			if shows_hover then
				a_p.set_color (t.accent)
			else
				a_p.set_color (t.outline)
			end
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius + 2.0)
			cx := x + width / 2.0
				-- the falling-file glyph: arrow into an open tray
			a_p.set_color (t.ink_muted)
			a_p.set_line_width (2.0)
			a_p.line (cx, y + 16.0, cx, y + 36.0, 2.0)
			a_p.line (cx - 6.0, y + 29.0, cx, y + 36.0, 2.0)
			a_p.line (cx + 6.0, y + 29.0, cx, y + 36.0, 2.0)
			a_p.line (cx - 16.0, y + 40.0, cx - 12.0, y + 47.0, 2.0)
			a_p.line (cx - 12.0, y + 47.0, cx + 12.0, y + 47.0, 2.0)
			a_p.line (cx + 12.0, y + 47.0, cx + 16.0, y + 40.0, 2.0)
			a_p.set_line_width (1.0)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			a_p.set_color (t.ink_muted)
			a_p.text (cx - a_p.advance (invitation) / 2.0, y + height - 16.0, invitation)
		end

invariant
	invited: invitation /= Void
	paths_attached: last_paths /= Void

end
