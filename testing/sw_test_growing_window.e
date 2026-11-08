note
	description: "A test window that can be grown as the user's resize grows it (`resize_surface')."

class
	SW_TEST_GROWING_WINDOW

inherit
	SW_WINDOW

create
	make

feature -- Testing

	grow_to (a_w, a_h: INTEGER)
			-- As a user's resize to `a_w' by `a_h' does.
		require
			positive: a_w > 0 and a_h > 0
		do
			resize_surface (a_w, a_h)
		ensure
			sized: win_w = a_w and win_h = a_h
		end

end
