note
	description: "[
		Generated geometry, parsed (pushed up 2026-10-25 from
		SW_WORLD_GEOMETRY and SW_REGION_GEOMETRY, whose two parser copies
		had drifted): data blocks of flat "lon lat lon lat ..." numbers,
		rings or lines separated by ';', a block boundary free to fall
		mid-ring. An heir's once feature calls `parse_block' on each block
		in order and `flush' after the last.
	]"

deferred class
	SW_GEOMETRY_DATA

feature {NONE} -- Parsing

	parse_block (a_data: STRING; a_acc: ARRAYED_LIST [ARRAY [REAL_64]])
			-- Rings or lines separated by ';', numbers by white space; an
			-- unfinished tail waits in `pending' for the next block (and
			-- `flush').
		local
			i: INTEGER
			c: CHARACTER
			tok: STRING
		do
			create tok.make (12)
			from
				i := 1
			until
				i > a_data.count
			loop
				c := a_data.item (i)
				if c = ';' then
					if not tok.is_empty then
						pending.extend (tok.to_double)
						tok.wipe_out
					end
					flush (a_acc)
				elseif c = ' ' or c = '%N' or c = '%T' or c = '%R' then
					if not tok.is_empty then
						pending.extend (tok.to_double)
						tok.wipe_out
					end
				else
					tok.extend (c)
				end
				i := i + 1
			end
			if not tok.is_empty then
				pending.extend (tok.to_double)
			end
		end

	flush (a_acc: ARRAYED_LIST [ARRAY [REAL_64]])
			-- Move the pending numbers out as one ring or line (two points at
			-- least).
		local
			l_ring: ARRAY [REAL_64]
			i: INTEGER
		do
			if pending.count >= 4 then
				create l_ring.make_filled (0.0, 1, pending.count)
				from
					i := 1
				until
					i > pending.count
				loop
					l_ring [i] := pending.i_th (i)
					i := i + 1
				end
				a_acc.extend (l_ring)
			end
			pending.wipe_out
		ensure
			emptied: pending.is_empty
		end

	pending: ARRAYED_LIST [REAL_64]
			-- Numbers of a ring or line not yet flushed.
		once
			create Result.make (4096)
		end

end
