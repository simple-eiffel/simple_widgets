note
	description: "[
		A widget that paints SW_MARKED_TEXT spans through a legend
		(0.24.0): the legend that turns a span's reason into a look, and
		the painter (with its size floors) that draws them. Shared by the
		text box, the paragraph list and the parallel text, which each
		carried the same three features. It inherits nothing, so it sits
		beside any parents with no adaptation at all.
	]"
	author: "Larry Rix"

class
	SW_MARK_HOST

feature -- Marks

	legend: detachable SW_MARK_LEGEND
			-- What a span's reason looks like.

	mark_painter: SW_MARK_PAINTER
			-- Paints the spans; set its size floors here.
		attribute
			create Result.make
		end

	set_legend (a_legend: detachable SW_MARK_LEGEND)
		do
			legend := a_legend
		ensure
			set: legend = a_legend
		end

end
