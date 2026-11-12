note
	description: "[
		A top-level window's widget tree published to screen readers (GW-14),
		shared by the main window (SW_WINDOW) and every second window
		(SW_FLOATING_WINDOW, simple_shell#48): node 0 is the window, named by
		its title, then every laid-out widget below its roots in tree order,
		under its own stable id, with its role, name, value, bounds,
		focusability and enablement; then what an heir adds above the roots
		(`add_extra_nodes': SW_WINDOW's dialog and popup menu); then the
		keyboard focus, when it moved. Each window publishes through its own
		SW_ACCESSIBILITY, under its own native window, so each serves its own
		table.
	]"

deferred class
	SW_ACCESSIBLE_TREE

feature -- Accessibility (GW-14)

	accessibility: SW_ACCESSIBILITY
			-- The UI Automation bridge this window publishes through.
		once ("OBJECT")
			create Result
		end

	is_accessible: BOOLEAN
			-- Does the window publish its widget tree to screen readers?
		deferred
		end

	focused: detachable SW_WIDGET
			-- The widget this window's keys go to, if any.
		deferred
		end

	accessible_widgets: ARRAYED_LIST [SW_WIDGET]
			-- The widgets published last, in tree order (node 0, the window
			-- itself, is not among them).
		attribute
			create Result.make (64)
		end

	accessible_id_of (a_widget: SW_WIDGET): INTEGER
			-- The node id `a_widget' is published under (its own, stable
			-- `accessible_node_id'); 0 when it is not in the tree. A tree a
			-- frame has outdated is published again first: with no client
			-- listening (always, off Windows) frames do not publish, and a
			-- section closed since would still answer (scan 13 on Linux).
		do
			if accessibility_is_stale and then is_accessible then
				publish_accessibility
			end
			if accessible_widgets.has (a_widget) then
				Result := a_widget.accessible_node_id
			end
		ensure
			non_negative: Result >= 0
		end

	accessible_widget_with_id (a_id: INTEGER): detachable SW_WIDGET
			-- The widget published last under node id `a_id', if any.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > accessible_widgets.count or Result /= Void
			loop
				if accessible_widgets.i_th (i).accessible_node_id = a_id then
					Result := accessible_widgets.i_th (i)
				end
				i := i + 1
			end
		end

	accessible_focus_tellings: INTEGER
			-- How many times UI Automation has been told the focus moved.

	publish_accessibility
			-- Publish the widget tree: node 0 is the window (named by its
			-- title), then every laid-out widget below its roots in tree
			-- order under its own stable id, each with its role, name, value,
			-- bounds, focusability and enablement; then what the window adds
			-- above them (`add_extra_nodes'); then the keyboard focus, when it
			-- moved. A window publishes when it opens, on frames while a client
			-- listens, and when a client asks (event 59).
		local
			l_parents: ARRAYED_LIST [INTEGER]
			i: INTEGER
			w: SW_WIDGET
		do
			accessibility_is_stale := False
			accessible_widgets.wipe_out
			create l_parents.make (64)
			across
				accessible_roots as ic
			loop
				collect_accessible (ic, 0, l_parents)
			end
			accessibility.begin_tree (accessible_widgets.count + 1 + extra_node_count + accessible_item_total)
			accessibility.add_node (0, 0, {SW_ACCESSIBILITY}.Role_window, accessible_title, Void, 0.0, 0.0,
				accessible_width, accessible_height, False, True)
			from
				i := 1
			until
				i > accessible_widgets.count
			loop
				w := accessible_widgets.i_th (i)
				accessibility.add_node (w.accessible_node_id, l_parents.i_th (i), w.accessible_role, w.accessible_name,
					w.accessible_value, w.x, w.y, w.width, w.height, w.accepts_focus, w.is_enabled)
				if not w.accessible_description.is_empty then
					accessibility.describe_last_node (w.accessible_description)
				end
				w.publish_accessible_items (accessibility)
				i := i + 1
			end
			add_extra_nodes
			accessibility.commit (accessible_window_handle)
			is_accessibility_published := True
			tell_accessible_focus
		ensure
			published: is_accessibility_published
			fresh: not accessibility_is_stale
		end

	describe_accessibility: STRING_32
			-- The published tree as simple_gui's shared tests read it (W10): one line per
			-- node, "role: name", indented two spaces per level, in the shared role names
			-- (SW_ACCESSIBILITY.role_name, or a widget's `shared_role_name' where UI Automation
			-- has no word for it); generic nodes (panes) are left out, as GTK's walk leaves them
			-- out. Publishes first, so it is always current.
		local
			i, d: INTEGER
			l_role: STRING_32
			l_named: HASH_TABLE [STRING_32, INTEGER]
		do
			publish_accessibility
			create l_named.make (16)
			across accessible_widgets as ic loop
				if attached ic.shared_role_name as al_name then
					l_named.force (al_name, ic.accessible_node_id)
				end
			end
			create Result.make (256)
			from
				i := 1
			until
				i > accessibility.served_rows
			loop
				l_role := accessibility.role_name (accessibility.served_role (i))
				if attached l_named.item (accessibility.served_id (i)) as al_shared then
					l_role := al_shared
				end
				if not l_role.same_string ("generic") then
					from
						d := accessibility.served_depth (i)
					until
						d = 0
					loop
						Result.append ("  ")
						d := d - 1
					end
					Result.append (l_role)
					Result.append (": ")
					Result.append (accessibility.served_name (i))
					Result.append_character ('%N')
				end
				i := i + 1
			end
		end

	accessible_item_total: INTEGER
			-- The non-widget nodes the collected widgets will publish (a list's rows).
		do
			across accessible_widgets as ic loop
				Result := Result + ic.accessible_item_count
			end
		end

	is_accessibility_published: BOOLEAN
			-- Has the tree been published at least once?

	accessibility_is_stale: BOOLEAN
			-- Was a frame drawn since the tree was last published?

feature {NONE} -- What the window publishes

	accessible_roots: ARRAYED_LIST [SW_WIDGET]
			-- The trees below node 0, in order.
		deferred
		end

	accessible_title: READABLE_STRING_GENERAL
			-- Node 0's name: the window's title.
		deferred
		end

	accessible_width: REAL_64
			-- Node 0's width, in client pixels.
		deferred
		end

	accessible_height: REAL_64
			-- Node 0's height, in client pixels.
		deferred
		end

	accessible_window_handle: POINTER
			-- The native window the table is served for (`default_pointer'
			-- before it opens).
		deferred
		end

	extra_node_count: INTEGER
			-- Rows `add_extra_nodes' adds; none here.
		do
		ensure
			non_negative: Result >= 0
		end

	add_extra_nodes
			-- Add what floats above the roots; nothing here.
		do
		end

feature {NONE} -- Accessibility internals (GW-14)

	last_told_focus: detachable SW_WIDGET
			-- The widget UI Automation was last told holds the focus.

	collect_accessible (a_widget: SW_WIDGET; a_parent: INTEGER; a_parents: ARRAYED_LIST [INTEGER])
			-- Append `a_widget' (under node `a_parent') and, below it, every
			-- laid-out widget it shows; a widget with no size is skipped with
			-- its subtree.
		local
			l_id: INTEGER
		do
			if a_widget.width > 0.0 and a_widget.height > 0.0 then
				accessible_widgets.extend (a_widget)
				a_parents.extend (a_parent)
				l_id := a_widget.accessible_node_id
				across
					a_widget.accessible_children as al_child
				loop
					collect_accessible (al_child, l_id, a_parents)
				end
			end
		ensure
			parallel: a_parents.count = accessible_widgets.count
		end

	tell_accessible_focus
			-- When the keyboard focus moved since UI Automation was last told,
			-- tell it - only then (scan 13: every publish told it again).
		local
			l_id: INTEGER
		do
			if is_accessibility_published and then focused /= last_told_focus then
				last_told_focus := focused
				if attached focused as al_focused then
					l_id := accessible_id_of (al_focused)
				end
				accessibility.focus_changed (l_id)
				accessible_focus_tellings := accessible_focus_tellings + 1
			end
		end

end
