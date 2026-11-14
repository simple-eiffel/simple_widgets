note
	description: "[
		Widgets layered over a base (simple_gui's GUI_OVERLAY on Windows, 1y-c): text over a
		picture, a badge, a floating button, a veil. The base fills the overlay and gives it its
		size; each layer sits at a place (a corner, an edge, the center, or filling the base), a
		margin in from the edges, moved by an offset, at its natural size but never larger than
		the overlay less the margins, and clipped to the overlay. Later layers lie above earlier
		ones; hit tests go from the top layer down, skipping layers that let the pointer through,
		then the base. Leading and trailing mirror under right-to-left; offsets do not.
	]"

class
	SW_OVERLAY

inherit
	SW_BOX_CONTAINER
		redefine
			preferred_width, arrange, widget_at
		end

create
	make

feature {NONE} -- Initialization

	make
			-- An empty overlay.
		do
			create children.make (4)
			create layers.make (4)
		ensure
			no_base: base = Void
			empty: children.is_empty
		end

feature -- Access

	base: detachable SW_WIDGET
			-- The widget under the layers.

	Layer_top_leading: INTEGER = 1
	Layer_top: INTEGER = 2
	Layer_top_trailing: INTEGER = 3
	Layer_leading: INTEGER = 4
	Layer_center: INTEGER = 5
	Layer_trailing: INTEGER = 6
	Layer_bottom_leading: INTEGER = 7
	Layer_bottom: INTEGER = 8
	Layer_bottom_trailing: INTEGER = 9
	Layer_fill: INTEGER = 10

	is_layer (a_w: SW_WIDGET): BOOLEAN
			-- Is `a_w' one of the layers?
		do
			Result := layer_of (a_w) /= Void
		end

	place_of (a_w: SW_WIDGET): INTEGER
		require
			layer: is_layer (a_w)
		do
			check attached layer_of (a_w) as al_l then
				Result := al_l.place
			end
		end

	passes_input (a_w: SW_WIDGET): BOOLEAN
		require
			layer: is_layer (a_w)
		do
			check attached layer_of (a_w) as al_l then
				Result := al_l.passes
			end
		end

feature -- Element change

	set_base (a_w: SW_WIDGET)
			-- Put `a_w' under the layers.
		require
			no_base: base = Void
			not_here: not children.has (a_w)
		do
			children.put_front (a_w)
			a_w.set_parent (Current)
			base := a_w
		ensure
			set: base = a_w and a_w.parent = Current
		end

	put_layer (a_w: SW_WIDGET; a_place: INTEGER)
			-- Lay `a_w' over the others at `a_place', no margin, no offset.
		require
			known: a_place >= Layer_top_leading and a_place <= Layer_fill
			not_here: not children.has (a_w)
		do
			put (a_w)
			layers.extend ([a_w, a_place, 0.0, 0.0, 0.0, False])
		ensure
			layered: is_layer (a_w) and place_of (a_w) = a_place
		end

	set_layer_place (a_w: SW_WIDGET; a_place: INTEGER; a_margin: REAL_64)
		require
			layer: is_layer (a_w)
			known: a_place >= Layer_top_leading and a_place <= Layer_fill
			non_negative: a_margin >= 0.0
		do
			check attached layer_of (a_w) as al_l then
				al_l.place := a_place
				al_l.margin := a_margin
			end
		ensure
			placed: place_of (a_w) = a_place
		end

	set_layer_offset (a_w: SW_WIDGET; a_dx, a_dy: REAL_64)
			-- Move `a_w' `a_dx' right and `a_dy' down from its place.
		require
			layer: is_layer (a_w)
		do
			check attached layer_of (a_w) as al_l then
				al_l.dx := a_dx
				al_l.dy := a_dy
			end
		end

	set_layer_passes_input (a_w: SW_WIDGET; a_on: BOOLEAN)
		require
			layer: is_layer (a_w)
		do
			check attached layer_of (a_w) as al_l then
				al_l.passes := a_on
			end
		ensure
			set: passes_input (a_w) = a_on
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- The base's.
		do
			if attached base as al_b and then not al_b.is_hidden then
				Result := al_b.slot_width (al_b.preferred_width (a_p))
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The base's.
		do
			if attached base as al_b and then not al_b.is_hidden then
				Result := al_b.slot_height (al_b.preferred_height (a_p, a_width))
			end
		end

	arrange (a_p: SW_PAINTER)
			-- The base over the whole overlay; each layer at its place, margin and offset.
		local
			l_w, l_h, l_x, l_y, l_m: REAL_64
			l_col, l_row: INTEGER
		do
			if attached base as al_b and then not al_b.is_hidden then
				al_b.set_bounds (x, y, width, height)
				al_b.arrange (a_p)
			end
			across layers as ic loop
				if not ic.widget.is_hidden then
					l_m := ic.margin
					if ic.place = Layer_fill then
						l_w := (width - 2.0 * l_m).max (0.0)
						l_h := (height - 2.0 * l_m).max (0.0)
						l_x := x + l_m
						l_y := y + l_m
					else
						l_w := ic.widget.slot_width (ic.widget.preferred_width (a_p)).min ((width - 2.0 * l_m).max (0.0))
						l_h := ic.widget.slot_height (ic.widget.preferred_height (a_p, l_w)).min ((height - 2.0 * l_m).max (0.0))
						l_col := (ic.place - 1) \\ 3
						l_row := (ic.place - 1) // 3
						inspect l_col
						when 0 then l_x := x + l_m
						when 1 then l_x := x + (width - l_w) / 2.0
						else l_x := x + width - l_w - l_m
						end
						l_x := mirrored_x (l_x, l_w)
						inspect l_row
						when 0 then l_y := y + l_m
						when 1 then l_y := y + (height - l_h) / 2.0
						else l_y := y + height - l_h - l_m
						end
					end
					ic.widget.set_bounds (l_x + ic.dx, l_y + ic.dy, l_w, l_h)
					ic.widget.arrange (a_p)
				end
			end
			vanish_hidden
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The base, then each layer, clipped to the overlay.
		do
			a_p.push_clip (x, y, width, height)
			across laid_out as ic loop
				ic.paint (a_p)
			end
			a_p.pop_clip
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- The top layer under the point that takes the pointer, else the base's, else this.
		local
			i: INTEGER
		do
			if contains (a_px, a_py) then
				from i := layers.count until Result /= Void or i < 1 loop
					if not layers.i_th (i).passes and not layers.i_th (i).widget.is_hidden then
						Result := layers.i_th (i).widget.widget_at (a_px, a_py)
					end
					i := i - 1
				end
				if Result = Void and then attached base as al_b and then not al_b.is_hidden then
					Result := al_b.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature {NONE} -- Implementation

	layers: ARRAYED_LIST [TUPLE [widget: SW_WIDGET; place: INTEGER; margin, dx, dy: REAL_64; passes: BOOLEAN]]
			-- The layers, bottom first.

	layer_of (a_w: SW_WIDGET): detachable TUPLE [widget: SW_WIDGET; place: INTEGER; margin, dx, dy: REAL_64; passes: BOOLEAN]
			-- `a_w''s layer record, if it is one.
		do
			across layers as ic until Result /= Void loop
				if ic.widget = a_w then
					Result := ic
				end
			end
		end

invariant
	layers_exist: layers /= Void
	base_is_child: attached base as al_b implies children.has (al_b)

end
