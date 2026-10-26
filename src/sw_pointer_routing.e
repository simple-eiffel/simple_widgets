note
	description: "[
		The walks every surface that hosts a widget tree takes (pushed up
		2026-10-25 out of SW_WINDOW for GW-22, whose floating windows host
		trees too): a click or the wheel offered from the widget under the
		pointer up its parents until one takes it, the first widget on that
		spine that welcomes files, the focus ring's next stop, and whole
		code points out of UTF-16 units. Stateless but for the half of a
		surrogate pair.
	]"

deferred class
	SW_POINTER_ROUTING

feature {NONE} -- Walks

	spine_click (a_target: SW_WIDGET; a_x, a_y: INTEGER; a_double: BOOLEAN): detachable SW_WIDGET
			-- Offer the click to `a_target', then up the parent chain until
			-- one consumes it; that one. Disabled widgets are inert and the
			-- click passes through them.
		local
			w: detachable SW_WIDGET
			handled: BOOLEAN
		do
			from
				w := a_target
			until
				handled or w = Void
			loop
				if w.is_enabled then
					if a_double then
						handled := w.handle_double_click (a_x, a_y)
					else
						handled := w.handle_click (a_x, a_y)
					end
				end
				if handled then
					Result := w
				else
					w := w.parent
				end
			end
		ensure
			enabled_consumer: attached Result as al_r implies al_r.is_enabled
		end

	spine_wheel (a_target: SW_WIDGET; a_delta: INTEGER)
			-- The wheel goes to the widget under the POINTER, then up the
			-- spine - never to keyboard focus.
		local
			w: detachable SW_WIDGET
			handled: BOOLEAN
		do
			from
				w := a_target
			until
				handled or w = Void
			loop
				if w.is_enabled then
					handled := w.handle_wheel (a_delta)
				end
				if not handled then
					w := w.parent
				end
			end
		end

	spine_file_taker (a_target: detachable SW_WIDGET): detachable SW_WIDGET
			-- The first enabled widget from `a_target' up that welcomes files.
		do
			from
				Result := a_target
			until
				Result = Void or else (Result.is_enabled and then Result.accepts_files)
			loop
				Result := Result.parent
			end
		ensure
			welcoming: attached Result as al_r implies al_r.accepts_files
		end

	ring_neighbour (a_ring: LIST [SW_WIDGET]; a_current: detachable SW_WIDGET; a_dir: INTEGER): SW_WIDGET
			-- The focus ring's stop `a_dir' steps (1 or -1) from `a_current',
			-- wrapping; from outside the ring, its first (or last) stop.
		require
			ring: not a_ring.is_empty
			unit_step: a_dir = 1 or a_dir = -1
		local
			i: INTEGER
		do
			if attached a_current as al_current then
				i := a_ring.index_of (al_current, 1)
			end
			i := i + a_dir
			if i < 1 then
				i := a_ring.count
			elseif i > a_ring.count then
				i := 1
			end
			Result := a_ring.i_th (i)
		ensure
			on_the_ring: a_ring.has (Result)
		end

	paired_code_point (a_unit: INTEGER): INTEGER
			-- The code point `a_unit' completes: -1 for the high half of a
			-- surrogate pair (kept until its low half arrives), the pair's
			-- code point for its low half, else `a_unit' itself (R8: widgets
			-- only ever see whole code points).
		do
			if a_unit >= 0xD800 and a_unit <= 0xDBFF then
				pending_surrogate := a_unit
				Result := -1
			elseif a_unit >= 0xDC00 and a_unit <= 0xDFFF and pending_surrogate /= 0 then
				Result := 0x10000 + (pending_surrogate - 0xD800) * 0x400 + (a_unit - 0xDC00)
				pending_surrogate := 0
			else
				pending_surrogate := 0
				Result := a_unit
			end
		ensure
			waiting: Result = -1 implies pending_surrogate = a_unit
			paired: Result >= 0x10000 implies pending_surrogate = 0
		end

	pending_surrogate: INTEGER
			-- High half of a UTF-16 pair awaiting its partner.

end
