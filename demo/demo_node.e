note
	description: "A labeled tree node for the demo: the host-side shape SW_TREE adapts over."

class
	DEMO_NODE

create
	make

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL)
		do
			create label.make_from_string_general (a_label)
			create children.make (4)
		ensure
			labeled: label.same_string_general (a_label)
		end

feature -- Access

	label: STRING_32

	children: ARRAYED_LIST [DEMO_NODE]

feature -- Element change

	put (a_child: DEMO_NODE)
		do
			children.extend (a_child)
		ensure
			grew: children.count = old children.count + 1
		end

	with_child (a_label: READABLE_STRING_GENERAL): like Current
		local
			c: DEMO_NODE
		do
			create c.make (a_label)
			children.extend (c)
			Result := Current
		ensure
			chained: Result = Current
		end

invariant
	label_attached: label /= Void
	children_attached: children /= Void

end
