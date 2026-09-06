note
	description: "[
		What a highlight MEANS: the application's reasons, each mapped
		to a look (SW_MARK) and a human label. "spelling" is red with a
		single text outline; "stale" is amber washed; "voice:narrator"
		is a teal box; "advisory" is violet italic - whatever the
		application decides, and it may decide differently as its state
		changes: `set_mark' re-themes every span carrying that reason
		at the next paint, because spans carry REASONS and the legend
		carries LOOKS.

		A BADGE is meaning too, so it lives here and not on the mark:
		one or two characters (`badge_of') painted as a small tag at
		the start of every span carrying the reason, for the reader who
		cannot keep twelve hues in mind. Empty means none.

		A legend is also what draws itself as a key for the reader
		(SW_MARK_LEGEND_VIEW): `keys' in the order they were defined,
		`label_of', `badge_of' and `mark_of' for each. An unknown reason answers Void from `mark_of', and
		SW_MARK_PAINTER paints nothing for it rather than guessing -
		`unresolved' on SW_MARKED_TEXT names the reasons a legend does
		not cover, so an application can notice.
	]"
	author: "Larry Rix"

class
	SW_MARK_LEGEND

create
	make

feature {NONE} -- Initialization

	make
		do
			create entries.make (8)
			create order.make (8)
			order.compare_objects
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
		do
			Result := order.count
		end

	keys: ARRAYED_LIST [STRING_32]
			-- Every reason, in definition order (copies).
		do
			create Result.make (order.count)
			across
				order as k
			loop
				Result.extend (k.twin)
			end
		ensure
			complete: Result.count = count
		end

	has (a_reason: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := entries.has (a_reason.to_string_32)
		end

	mark_of (a_reason: READABLE_STRING_GENERAL): detachable SW_MARK
			-- The look for `a_reason'; Void when the legend has none.
		do
			if attached entries.item (a_reason.to_string_32) as e then
				Result := e.mark
			end
		ensure
			known_iff_has: (Result /= Void) = has (a_reason)
		end

	label_of (a_reason: READABLE_STRING_GENERAL): STRING_32
			-- The reader's label for `a_reason'; the reason itself when
			-- the legend has none.
		do
			if attached entries.item (a_reason.to_string_32) as e then
				Result := e.label.twin
			else
				Result := a_reason.to_string_32
			end
		ensure
			never_empty: a_reason.is_empty or else not Result.is_empty
		end

	badge_of (a_reason: READABLE_STRING_GENERAL): STRING_32
			-- The tag painted at the start of a span carrying `a_reason';
			-- empty when none (or the reason is unknown).
		do
			if attached entries.item (a_reason.to_string_32) as e then
				Result := e.badge.twin
			else
				create Result.make_empty
			end
		ensure
			short: Result.count <= Max_badge_length
		end

	Max_badge_length: INTEGER = 2

feature -- Element change

	define (a_reason: READABLE_STRING_GENERAL; a_mark: SW_MARK; a_label: READABLE_STRING_GENERAL)
			-- `a_reason' looks like `a_mark' and reads as `a_label'; a
			-- reason already defined is redefined in place, keeping its
			-- position in `keys'.
		require
			reason_valid: is_valid_reason (a_reason)
		local
			k: STRING_32
		do
			k := a_reason.to_string_32
			if not entries.has (k) then
				order.extend (k)
			end
			if attached entries.item (k) as e then
				entries.force ([a_mark, a_label.to_string_32, e.badge], k)
			else
				entries.force ([a_mark, a_label.to_string_32, create {STRING_32}.make_empty], k)
			end
		ensure
			defined: has (a_reason)
			look: mark_of (a_reason) = a_mark
			labelled: label_of (a_reason).same_string_general (a_label)
		end

	set_badge (a_reason: READABLE_STRING_GENERAL; a_badge: READABLE_STRING_GENERAL)
			-- `a_reason' wears `a_badge' (at most `Max_badge_length'
			-- characters; empty takes it off).
		require
			defined: has (a_reason)
			short: a_badge.count <= Max_badge_length
		do
			if attached entries.item (a_reason.to_string_32) as e then
				entries.force ([e.mark, e.label, a_badge.to_string_32], a_reason.to_string_32)
			end
		ensure
			worn: badge_of (a_reason).same_string_general (a_badge)
		end

	set_mark (a_reason: READABLE_STRING_GENERAL; a_mark: SW_MARK)
			-- Re-theme `a_reason': every span carrying it changes at
			-- the next paint.
		require
			defined: has (a_reason)
		do
			if attached entries.item (a_reason.to_string_32) as e then
				entries.force ([a_mark, e.label, e.badge], a_reason.to_string_32)
			end
		ensure
			look: mark_of (a_reason) = a_mark
			label_kept: label_of (a_reason).same_string (old label_of (a_reason))
		end

	remove (a_reason: READABLE_STRING_GENERAL)
		require
			defined: has (a_reason)
		do
			entries.remove (a_reason.to_string_32)
			order.prune_all (a_reason.to_string_32)
		ensure
			gone: not has (a_reason)
			one_fewer: count = old count - 1
		end

feature -- Status

	is_valid_reason (a_reason: READABLE_STRING_GENERAL): BOOLEAN
			-- A reason is a key: not empty, no line break, no '|' (the
			-- codec's separator).
		do
			Result := not a_reason.is_empty and then not a_reason.has ('%N')
				and then not a_reason.has ('|')
		end

feature {NONE} -- Implementation

	entries: HASH_TABLE [TUPLE [mark: SW_MARK; label, badge: STRING_32], STRING_32]

	order: ARRAYED_LIST [STRING_32]
			-- Definition order, for a drawn key.

invariant
	parallel: entries.count = order.count

end
