note
	description: "A test widget whose drawing fails: printing must survive it."

class
	SW_TEST_FAILING_WIDGET

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make
		do
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 100.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			(create {DEVELOPER_EXCEPTION}).raise
		end

end
