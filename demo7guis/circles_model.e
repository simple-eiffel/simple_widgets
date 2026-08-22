note
	description: "[
		The Circle Drawer's domain: circles plus snapshot-based
		undo/redo. Every significant change pushes the PRIOR state
		onto the undo stack and clears redo - 7GUIs' exact law.
	]"

class
	CIRCLES_MODEL

create
	make

feature {NONE} -- Initialization

	make
		do
			create circles.make (16)
			create undo_stack.make (16)
			create redo_stack.make (16)
		end

feature -- Access

	circles: ARRAYED_LIST [TUPLE [cx, cy, radius: REAL_64]]

	can_undo: BOOLEAN
		do
			Result := not undo_stack.is_empty
		end

	can_redo: BOOLEAN
		do
			Result := not redo_stack.is_empty
		end

	nearest_hit (a_x, a_y: REAL_64): INTEGER
			-- The circle containing the point nearest by centre;
			-- 0 when the point is inside none.
		local
			i: INTEGER
			d2, best: REAL_64
		do
			best := {REAL_64}.max_value
			from
				i := 1
			until
				i > circles.count
			loop
				d2 := (circles.i_th (i).cx - a_x) * (circles.i_th (i).cx - a_x)
					+ (circles.i_th (i).cy - a_y) * (circles.i_th (i).cy - a_y)
				if d2 <= circles.i_th (i).radius * circles.i_th (i).radius and d2 < best then
					best := d2
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= circles.count
		end

feature -- Commands

	add_circle (a_x, a_y: REAL_64)
			-- A significant change: snapshot first.
		do
			push_undo
			circles.extend ([a_x, a_y, 15.0])
		ensure
			grew: circles.count = old circles.count + 1
			redo_cleared: not can_redo
		end

	begin_adjustment (a_index: INTEGER)
			-- Mark the coming diameter drags as ONE significant
			-- change: snapshot now, drags mutate freely after.
		require
			in_range: a_index >= 1 and a_index <= circles.count
		do
			push_undo
		ensure
			redo_cleared: not can_redo
		end

	set_radius (a_index: INTEGER; a_r: REAL_64)
		require
			in_range: a_index >= 1 and a_index <= circles.count
			positive: a_r > 0.0
		do
			circles.i_th (a_index).radius := a_r
		ensure
			set: circles.i_th (a_index).radius = a_r
		end

	undo
		require
			can: can_undo
		do
			redo_stack.extend (snapshot)
			restore (undo_stack.last)
			undo_stack.finish
			undo_stack.remove
		ensure
			redoable: can_redo
		end

	redo
		require
			can: can_redo
		do
			undo_stack.extend (snapshot)
			restore (redo_stack.last)
			redo_stack.finish
			redo_stack.remove
		ensure
			undoable: can_undo
		end

feature {NONE} -- Snapshots

	undo_stack, redo_stack: ARRAYED_LIST [ARRAYED_LIST [TUPLE [cx, cy, radius: REAL_64]]]

	snapshot: ARRAYED_LIST [TUPLE [cx, cy, radius: REAL_64]]
		do
			create Result.make (circles.count)
			across
				circles as c
			loop
				Result.extend ([c.cx, c.cy, c.radius])
			end
		ensure
			same_size: Result.count = circles.count
		end

	restore (a_state: ARRAYED_LIST [TUPLE [cx, cy, radius: REAL_64]])
		do
			circles.wipe_out
			across
				a_state as c
			loop
				circles.extend ([c.cx, c.cy, c.radius])
			end
		ensure
			restored: circles.count = a_state.count
		end

	push_undo
		do
			undo_stack.extend (snapshot)
			redo_stack.wipe_out
		ensure
			undoable: can_undo
			redo_cleared: not can_redo
		end

invariant
	stacks_attached: undo_stack /= Void and redo_stack /= Void

end
