note
	description: "[
		The dev studio: the mesh on the left, the living reveal on
		the right - DevTools' two panes, ours. Clicking a node
		repopulates the pane (a fresh SW_INSPECTOR column); frontier
		nodes grow in place; text-bearing subjects (labels, text
		boxes) offer a contract-safe live edit: the Apply drives
		their PUBLIC set_text, every invariant armed. Lives in
		devkit - release builds never compile the studio.
	]"

class
	SW_DEV_STUDIO

inherit
	SW_SPLITTER
		rename
			make as make_split
		end

create
	make_over

feature {NONE} -- Initialization

	make_over (a_root: SW_WIDGET; a_depth: INTEGER)
		require
			some_depth: a_depth >= 1
		local
			pane: SW_COLUMN
		do
			create mesh.make_over (a_root, a_depth)
			create pane_host.make
			pane_host := pane_host.with_gap (6.0)
			create edit_box.make_single_line ("")
			edit_box.set_spellcheck (False)
			create apply_button.make ("Apply set_text", Void)
			make_split (mesh.growing, pane_host)
			set_ratio (0.62)
			mesh.set_on_select (agent on_node_selected)
			apply_button.set_on_click (agent apply_edit)
			pane := pane_host
			pane.put ((create {SW_LABEL}.make_ui ("Click a node; its truth lands here. Plus-badged nodes grow on click; right-click a node for actions.")).as_muted.with_wrap)
		end

feature -- Access

	mesh: SW_MESH

	subject: detachable SW_WIDGET

feature -- Tooling

	pane_line_count: INTEGER
			-- How many rows the reveal pane holds right now.
		do
			Result := pane_host.children.count
		end

	edit_text: STRING_32
			-- What the live-edit box holds.
		do
			Result := edit_box.text
		end

	set_edit_text (a_text: READABLE_STRING_GENERAL)
			-- Stage `a_text' in the live-edit box.
		do
			edit_box.set_text (a_text)
		end

	apply_edit
			-- Drive the subject's PUBLIC setter: the invariant is the
			-- safety, and a violation dying loudly is the point.
		do
			if attached {SW_TEXT_BOX} subject as tb then
				tb.set_text (edit_box.text)
			elseif attached {SW_LABEL} subject as lb then
				lb.set_text (edit_box.text)
			end
		end

feature {NONE} -- Pane

	pane_host: SW_COLUMN

	edit_box: SW_TEXT_BOX

	apply_button: SW_BUTTON

	on_node_selected (a_w: SW_WIDGET)
			-- Rebuild the pane: the full dossier in a growing scroll
			-- area (every reflected field reachable by wheel), plus
			-- the edit rig when the subject bears text.
		local
			scroll: SW_SCROLL_AREA
		do
			subject := a_w
			pane_host.children.wipe_out
			create scroll.make (240.0)
			scroll.set_child (create {SW_INSPECTOR}.make_full (a_w))
			pane_host.put (scroll.growing)
			if attached {SW_TEXT_BOX} a_w as tb then
				edit_box.set_text (tb.text)
				pane_host.put ((create {SW_LABEL}.make_ui ("live edit %/8212/ contracts armed:")).as_muted)
				pane_host.put (edit_box)
				pane_host.put (apply_button)
			elseif attached {SW_LABEL} a_w as lb then
				edit_box.set_text (lb.text)
				pane_host.put ((create {SW_LABEL}.make_ui ("live edit %/8212/ contracts armed:")).as_muted)
				pane_host.put (edit_box)
				pane_host.put (apply_button)
			end
		end

invariant
	organs_attached: mesh /= Void and pane_host /= Void

end
