note
	description: "[
		The lens, armed: the devkit override of the release no-op.
		Reveals build SW_INSPECTOR popovers; the chip names whatever
		hovers. Only dev targets (ECF override devkit) compile this
		file - and with it, the inspector at all.
	]"

class
	DEV_LENS

feature -- Status

	is_active (a_dev_mode_on: BOOLEAN): BOOLEAN
		do
			Result := a_dev_mode_on
		end

	observes (a_target: SW_WIDGET): BOOLEAN
			-- Larry's law: the instrument never inspects the
			-- instrument. False for any widget inside the mesh, the
			-- studio, or an inspector column - chips, reveals and
			-- dev-mode picking all gate on this.
		local
			w: detachable SW_WIDGET
			chrome: BOOLEAN
		do
			from
				w := a_target
			until
				chrome or w = Void
			loop
				chrome := attached {SW_MESH} w
					or attached {SW_DEV_STUDIO} w
					or attached {SW_INSPECTOR} w
				if attached w as pw then
					w := pw.parent
				end
			end
			Result := not chrome
		end

feature -- Hooks

	reveal (a_window: SW_WINDOW; a_subject: SW_WIDGET; a_x, a_y: INTEGER)
		local
			insp: SW_INSPECTOR
		do
			if attached {SW_DEV_STUDIO} a_window.sheet_content as st then
					-- a docked studio is up: the reveal lands in its
					-- pane (DevTools aims the dock, not a popover that
					-- would replace it)
				st.aim_at (a_subject)
			else
				create insp.make_for (a_subject)
				insp.set_mesh_action (agent open_mesh_for (a_window, a_subject))
				a_window.show_popover (insp, a_x, a_y, 360.0)
			end
		end

	open_mesh_for (a_window: SW_WINDOW; a_root: SW_WIDGET)
			-- The doorway: the studio, rooted at the revealed control
			-- (the sheet naturally replaces the popover - one overlay).
		do
			a_window.show_sheet (create {SW_DEV_STUDIO}.make_over (a_root, 3), 860.0)
		end

	draw_chip (a_p: SW_PAINTER; a_theme: SW_THEME; a_hovered: SW_WIDGET)
		do
			if not observes (a_hovered) then
					-- dev chrome wears no chip
			else
			a_p.set_color (a_theme.accent)
			a_p.set_line_width (2.0)
			a_p.rrect_stroke (a_hovered.x - 1.5, a_hovered.y - 1.5,
				a_hovered.width + 3.0, a_hovered.height + 3.0, 3.0)
			a_p.set_line_width (1.0)
			a_p.font ({SW_PAINTER}.Role_mono, 12.0, True)
			a_p.set_color (a_theme.surface)
			a_p.rrect_fill (a_hovered.x, a_hovered.y - 20.0,
				a_p.advance (a_hovered.generating_type.name_32) + 60.0, 17.0, 3.0)
			a_p.set_color (a_theme.accent)
			a_p.text (a_hovered.x + 4.0, a_hovered.y - 6.0,
				a_hovered.generating_type.name_32 + {STRING_32} " "
				+ a_hovered.width.rounded.out + {STRING_32} "x" + a_hovered.height.rounded.out)
			end
		end

end
