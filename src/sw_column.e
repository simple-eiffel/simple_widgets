note
	description: "[
		Children stacked top to bottom, each given the full inner
		width, separated by the gap, inset by the padding.
	]"

class
	SW_COLUMN

inherit
	SW_BOX_CONTAINER
		redefine
			preferred_width,
			arrange, widget_at
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create children.make (8)
			gap := 8.0
			padding := 0.0
		ensure
			no_explicit_spacing: not gap_is_explicit and not padding_is_explicit
		end

feature -- Access

	padding: REAL_64
			-- Space between THIS BOX'S EDGE and its children -
			-- EV_BOX.border_width. Consulted only when
			-- `padding_is_explicit'; otherwise `default_padding'.

	padding_is_explicit: BOOLEAN
			-- Has the application set `padding' itself?

	is_fitting: BOOLEAN
			-- Does a column too short for its children take the shortfall back
			-- from its growers, down to each one's `min_height'? Off by default:
			-- a column's growers otherwise keep their natural height and run
			-- past its bottom, which every existing layout was built on (0.46.3).

feature -- Element change

	fitting: like Current
			-- Fluent: take a shortfall back from the growers (a sheet whose text must
			-- leave its buttons in view, 2026-10-30). Give each grower a `min_height'.
		do
			is_fitting := True
			Result := Current
		ensure
			fitting: is_fitting
			chained: Result = Current
		end

	with_padding (a_pad: REAL_64): like Current
		require
			non_negative: a_pad >= 0.0
		do
			padding := a_pad
			padding_is_explicit := True
			Result := Current
		ensure
			explicit: padding_is_explicit and padding = a_pad
		end

	set_padding (a_pad: REAL_64)
			-- Fix this box's own border; the theme no longer decides.
		require
			non_negative: a_pad >= 0.0
		do
			padding := a_pad
			padding_is_explicit := True
		ensure
			explicit: padding_is_explicit and padding = a_pad
		end

feature -- Spacing (theme defaults, explicit always wins)

	default_padding (a_p: SW_PAINTER): REAL_64
			-- This box's border when the application has not set one.
			--
			-- ZERO, and that is the whole anti-double-border rule: the
			-- BORDER is applied ONCE, by SW_WINDOW at the root (and by
			-- SW_DIALOG inside its card), so a box nested three deep
			-- adds no second, third or fourth border. Vision2 defaults
			-- EV_BOX.border_width to 0 for the same reason
			-- (EV_BOX_I.Default_border_width = 0) and lets the dialog
			-- set it. Descendants that ARE a surface in their own right
			-- - SW_CARD, SW_GROUP, SW_FILE_DIALOG - redefine this.
		do
			Result := 0.0
		ensure
			non_negative: Result >= 0.0
		end

	default_gap (a_p: SW_PAINTER): REAL_64
			-- Sibling separation when the application has not set one:
			-- the theme's `padding', which scales with the text.
		do
			Result := a_p.theme.padding
		ensure
			non_negative: Result >= 0.0
		end

	effective_padding (a_p: SW_PAINTER): REAL_64
			-- The border actually used this layout.
		do
			if padding_is_explicit then
				Result := padding
			else
				Result := default_padding (a_p)
			end
		ensure
			explicit_wins: padding_is_explicit implies Result = padding
			non_negative: Result >= 0.0
		end

	effective_gap (a_p: SW_PAINTER): REAL_64
			-- The sibling separation actually used this layout.
		do
			if gap_is_explicit then
				Result := gap
			else
				Result := default_gap (a_p)
			end
		ensure
			explicit_wins: gap_is_explicit implies Result = gap
			non_negative: Result >= 0.0
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- The widest child plus the padding walls.
		local
			pad: REAL_64
		do
			pad := effective_padding (a_p)
			across
				children as c
			loop
				Result := Result.max (c.clamped_width (c.preferred_width (a_p)))
			end
			Result := Result + 2.0 * pad
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			inner, pad, gp: REAL_64
			n: INTEGER
		do
			pad := effective_padding (a_p)
			gp := effective_gap (a_p)
			inner := (a_width - 2.0 * pad).max (0.0)
			across
				children as c
			loop
				Result := Result + c.preferred_height (a_p, inner)
				n := n + 1
			end
			if n > 1 then
				Result := Result + gp * (n - 1)
			end
			Result := Result + 2.0 * pad
		end

	arrange (a_p: SW_PAINTER)
			-- Natural heights first; leftover container height splits
			-- among growers by weight; a fitting column takes a shortfall
			-- back from them by weight, down to each one's `min_height'.
		local
			cy, inner, ch, natural, leftover, total_grow, pad, gp: REAL_64
			heights: ARRAYED_LIST [REAL_64]
			i: INTEGER
		do
			pad := effective_padding (a_p)
			gp := effective_gap (a_p)
			inner := (width - 2.0 * pad).max (0.0)
			create heights.make (children.count)
			across
				children as c
			loop
				heights.extend (c.clamped_height (c.preferred_height (a_p, inner)))
				natural := natural + heights.last
				total_grow := total_grow + c.grow
			end
			if children.count > 1 then
				natural := natural + gp * (children.count - 1)
			end
			leftover := height - 2.0 * pad - natural
			cy := y + pad
			from
				i := 1
			until
				i > children.count
			loop
				ch := heights.i_th (i)
				if leftover > 0.0 and total_grow > 0.0 and children.i_th (i).grow > 0.0 then
					ch := children.i_th (i).clamped_height
						(ch + leftover * children.i_th (i).grow / total_grow)
				elseif is_fitting and leftover < 0.0 and total_grow > 0.0 and children.i_th (i).grow > 0.0 then
						-- too short a fitting column (2026-10-30, Larry: the About sheet's
						-- text did not follow the sheet): the growers give the space back,
						-- so the children after them stay inside. Opt-in since 0.46.3: by
						-- default (0.46.2) it shrank dock panels' lists to nothing and their
						-- clip failed cairo's positive_extent
					ch := (ch + leftover * children.i_th (i).grow / total_grow)
						.max (children.i_th (i).min_height)
				end
				children.i_th (i).set_bounds (x + pad, cy, inner, ch)
				children.i_th (i).arrange (a_p)
				cy := cy + ch + gp
				i := i + 1
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			across
				children as c
			loop
				c.draw (a_p)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				across
					children as c
				until
					Result /= Void
				loop
					Result := c.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

invariant
	padding_non_negative: padding >= 0.0

end
