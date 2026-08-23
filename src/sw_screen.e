note
	description: "[
		The desktop as a picture: SHELL_DESKTOP's raw grab married to
		cairo - a virtual-screen region becomes a CAIRO_SURFACE ready
		for write_png, SW_IMAGE or any painter. The pure-route
		EV_SCREEN, completed.
	]"

class
	SW_SCREEN

inherit
	SHELL_DESKTOP

feature -- Capture

	grab (a_x, a_y, a_w, a_h: INTEGER): detachable CAIRO_SURFACE
			-- The desktop region as an ARGB32 surface; Void when the
			-- desktop cannot be read (locked session, secure screen).
		require
			positive: a_w > 0 and a_h > 0
		local
			s: CAIRO_SURFACE
		do
			create s.make (a_w, a_h)
			s.flush.do_nothing
			if grab_into (a_x, a_y, a_w, a_h, s.data, s.stride) then
				s.mark_dirty.do_nothing
				Result := s
			else
				s.destroy
			end
		ensure
			sized: attached Result as r implies r.width = a_w and r.height = a_h
		end

end
