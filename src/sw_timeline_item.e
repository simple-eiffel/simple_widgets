note
	description: "[
		One event, reign, period or dispute position on an SW_LANE_TIMELINE
		(GW-17): a range of astronomical years, the lane it sits in, and the
		CERTAINTY CLASS that says what kind of evidence fixes the date - drawn
		as a pattern with a label, never by colour alone:
		A fixed to the day (a tick), B fixed to the year (a solid bar), C a
		range from a chronology scheme (a bar with its scheme badge), D a
		scientific range (a gradient bar), E an archaeological period (a soft
		band), F literary or narrative-internal (a dashed bar, "per the
		text"), G tradition (a hatched band, "tradition", never a point).
	]"

class
	SW_TIMELINE_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_id, a_lane: INTEGER; a_title: READABLE_STRING_GENERAL; a_from, a_to, a_class: INTEGER)
		require
			ordered: a_from <= a_to
			known_class: a_class >= Class_a and a_class <= Class_g
		do
			id := a_id
			lane := a_lane
			create title.make_from_string_general (a_title)
			year_from := a_from
			year_to := a_to
			certainty := a_class
			create badge.make_empty
			importance := Importance_major
		ensure
			kept: id = a_id and lane = a_lane and year_from = a_from and year_to = a_to and certainty = a_class
		end

feature -- Access

	id: INTEGER
	lane: INTEGER
	title: STRING_32
	year_from, year_to: INTEGER
			-- Astronomical years, inclusive.

	certainty: INTEGER
			-- A `Class_' constant.

	badge: STRING_32
			-- A scheme or provenance badge (class C names its scheme); empty
			-- for none.

	dispute: INTEGER
			-- The dispute this item is a position of; 0 for none.

	lean_note: detachable STRING_32
			-- When this position is the owner's lean: its confidence and
			-- wording ("AD 33 over AD 30: 0.60, a lean, not consensus").

	importance: INTEGER
			-- `Importance_period' (shown at every scale), `Importance_major'
			-- (century scale and finer) or `Importance_detail' (decade scale
			-- and finer): semantic zoom.

	is_point: BOOLEAN
			-- Drawn as a tick? Class A, or a one-year item other than
			-- tradition (G is never drawn as a point).
		do
			Result := certainty = Class_a or else (year_from = year_to and certainty /= Class_g and certainty /= Class_e)
		end

	is_lean: BOOLEAN
		do
			Result := attached lean_note
		end

	contains (a_year: REAL_64): BOOLEAN
			-- Does the item's range hold `a_year'?
		do
			Result := a_year >= year_from and a_year < year_to + 1
		end

feature -- Certainty classes

	Class_a: INTEGER = 1
	Class_b: INTEGER = 2
	Class_c: INTEGER = 3
	Class_d: INTEGER = 4
	Class_e: INTEGER = 5
	Class_f: INTEGER = 6
	Class_g: INTEGER = 7

	Importance_period: INTEGER = 0
	Importance_major: INTEGER = 1
	Importance_detail: INTEGER = 2

feature -- Element change

	set_badge (a_badge: READABLE_STRING_GENERAL)
		do
			create badge.make_from_string_general (a_badge)
		ensure
			set: badge.same_string_general (a_badge)
		end

	set_dispute (a_dispute: INTEGER)
		require
			non_negative: a_dispute >= 0
		do
			dispute := a_dispute
		ensure
			set: dispute = a_dispute
		end

	set_lean (a_note: READABLE_STRING_GENERAL)
			-- Mark this position as the owner's lean, with its wording. Never
			-- pre-selected: the timeline only marks it.
		do
			create lean_note.make_from_string_general (a_note)
		ensure
			lean: is_lean
		end

	set_importance (a_level: INTEGER)
		require
			known: a_level >= Importance_period and a_level <= Importance_detail
		do
			importance := a_level
		ensure
			set: importance = a_level
		end

invariant
	ordered: year_from <= year_to
	known_class: certainty >= Class_a and certainty <= Class_g
	tradition_never_a_point: certainty = Class_g implies not is_point
	known_importance: importance >= Importance_period and importance <= Importance_detail

end
