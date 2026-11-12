note
	description: "[
		Ancestor of everything drawable. A widget owns a rectangle,
		reports its preferred size, draws itself through the painter,
		and may respond to input. Containers redefine `arrange' and
		`widget_at' to manage children.

		No widget touches Cairo or Win32: geometry, painter calls and
		agents are the whole vocabulary.
	]"

deferred class
	SW_WIDGET

feature -- Tree

	parent: detachable SW_WIDGET
			-- Enclosing container, set on adoption; the spine input
			-- bubbling and any future accessibility bridge walk.

	set_parent (a_parent: detachable SW_WIDGET)
		do
			parent := a_parent
		ensure
			set: parent = a_parent
		end

feature -- Tooltip

	tooltip: STRING_32
			-- Hover hint; empty means none. Drawn by the window after
			-- a dwell - a drawn overlay per R7, never a native tip.
		attribute
			create Result.make_empty
		end

	set_tooltip (a_tip: READABLE_STRING_GENERAL)
		do
			create tooltip.make_from_string_general (a_tip)
		ensure
			kept: tooltip.same_string_general (a_tip)
		end

	tooltip_anchor: TUPLE [x, y, w, h: REAL_64]
			-- The box the hint hangs below: the whole widget, or the part a widget with
			-- several parts (a collapsed sidebar's rows) says the tooltip is about.
		do
			Result := [x, y, width, height]
		end

	with_tooltip (a_tip: READABLE_STRING_GENERAL): like Current
			-- Fluent tooltip.
		do
			set_tooltip (a_tip)
			Result := Current
		ensure
			chained: Result = Current
		end

feature -- Geometry

	x: REAL_64
	y: REAL_64
	width: REAL_64
	height: REAL_64

	set_bounds (a_x, a_y, a_w, a_h: REAL_64)
		require
			sane_size: a_w >= 0.0 and a_h >= 0.0
		do
			x := a_x
			y := a_y
			width := a_w
			height := a_h
		ensure
			placed: x = a_x and y = a_y
			sized: width = a_w and height = a_h
		end

	is_hidden: BOOLEAN
			-- Taken out by the program (W4b): absent from layout, drawing, hit tests and the
			-- accessibility tree until shown again.

	is_visible: BOOLEAN
		do
			Result := not is_hidden
		end

	set_visible (a_on: BOOLEAN)
			-- Show or hide this widget; its container closes the gap at the next layout.
		do
			is_hidden := not a_on
			if is_hidden then
				vanish
			end
		ensure
			set: is_visible = a_on
		end

	vanish
			-- Take this widget and everything below it off the surface:
			-- no extent where it stands, so pills, hover and hit tests
			-- pass it by until the next `arrange' places it again. A
			-- folded dock zone and the zones a maximized panel covers
			-- send their contents away so.
		do
			set_bounds (x, y, 0.0, 0.0)
			across
				sub_widgets as al_child
			loop
				al_child.vanish
			end
		ensure
			gone: width = 0.0 and height = 0.0
		end

	contains (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := a_px >= x and then a_px <= x + width
				and then a_py >= y and then a_py <= y + height
		end

feature -- Sizing policy (the containership vocabulary)

	grow: REAL_64
			-- Share of a container's leftover space this widget claims;
			-- 0 = natural size only (the default). Vision2's expanded
			-- item and the web's flex-grow, unified.

	min_width: REAL_64
	min_height: REAL_64
	max_width: REAL_64
	max_height: REAL_64
			-- Anchors; 0 means unset.

	set_grow (a_g: REAL_64)
		require
			non_negative: a_g >= 0.0
		do
			grow := a_g
		ensure
			set: grow = a_g
		end

	growing: like Current
			-- Fluent: claim leftover space with weight 1. (Vision2
			-- called this expanded - an Eiffel keyword, so: growing.)
		do
			grow := 1.0
			Result := Current
		ensure
			growing: grow = 1.0
			chained: Result = Current
		end

	with_min_size (a_w, a_h: REAL_64): like Current
			-- Fluent minimum anchors (0 leaves an axis unset).
		require
			sane: a_w >= 0.0 and a_h >= 0.0
		do
			min_width := a_w
			min_height := a_h
			Result := Current
		ensure
			chained: Result = Current
		end

	with_max_size (a_w, a_h: REAL_64): like Current
			-- Fluent maximum anchors (0 leaves an axis unset).
		require
			sane: a_w >= 0.0 and a_h >= 0.0
		do
			max_width := a_w
			max_height := a_h
			Result := Current
		ensure
			chained: Result = Current
		end

	clamped_width (a_natural: REAL_64): REAL_64
			-- `a_natural' pulled inside the anchors.
		do
			Result := a_natural.max (min_width)
			if max_width > 0.0 then
				Result := Result.min (max_width)
			end
		ensure
			at_least_minimum: Result >= min_width
		end

	clamped_height (a_natural: REAL_64): REAL_64
		do
			Result := a_natural.max (min_height)
			if max_height > 0.0 then
				Result := Result.min (max_height)
			end
		ensure
			at_least_minimum: Result >= min_height
		end

feature -- Direction and placement (W4c)

	layout_direction: INTEGER
			-- `Layout_inherit' (the nearest ancestor's that is set, else left to right),
			-- `Layout_left_to_right' or `Layout_right_to_left'.

	Layout_inherit: INTEGER = 0
	Layout_left_to_right: INTEGER = 1
	Layout_right_to_left: INTEGER = 2

	set_layout_direction (a_direction: INTEGER)
			-- Lay this widget, and the widgets below it that inherit, out in `a_direction'.
		require
			valid: a_direction >= Layout_inherit and a_direction <= Layout_right_to_left
		do
			layout_direction := a_direction
		ensure
			set: layout_direction = a_direction
		end

	mirrors_layout: BOOLEAN
			-- Is this widget laid out right to left: by its own direction, else by the nearest
			-- ancestor's that is set, else not?
		local
			l_w: detachable SW_WIDGET
			l_found: BOOLEAN
		do
			from
				l_w := Current
			until
				l_w = Void or l_found
			loop
				if l_w.layout_direction /= Layout_inherit then
					l_found := True
					Result := l_w.layout_direction = Layout_right_to_left
				end
				l_w := l_w.parent
			end
		end

	cross_alignment: INTEGER
			-- Where this widget sits across its container's axis: `Place_fill' (the
			-- container's own rule, the default), `Place_start', `Place_center' or `Place_end'.
			-- Across a column, start is the left in left-to-right layout and the right in
			-- right-to-left; across a row, start is the top.

	Place_fill: INTEGER = 0
	Place_start: INTEGER = 1
	Place_center: INTEGER = 2
	Place_end: INTEGER = 3

	set_cross_alignment (a_place: INTEGER)
		require
			valid: a_place >= Place_fill and a_place <= Place_end
		do
			cross_alignment := a_place
		ensure
			set: cross_alignment = a_place
		end

	mirrored_x (a_x, a_w: REAL_64): REAL_64
			-- The left edge for a child `a_w' wide that left-to-right layout would put at `a_x':
			-- `a_x' itself, or reflected about this widget's vertical center line when this
			-- widget `mirrors_layout'.
		do
			if mirrors_layout then
				Result := x + x + width - a_x - a_w
			else
				Result := a_x
			end
		ensure
			kept_when_not_mirrored: not mirrors_layout implies Result = a_x
		end

feature -- Edit commands (W8)

	Edit_undo: INTEGER = 10
	Edit_redo: INTEGER = 11
	Edit_cut: INTEGER = 12
	Edit_copy: INTEGER = 13
	Edit_paste: INTEGER = 14
	Edit_select_all: INTEGER = 15
			-- simple_gui's edit roles: an Edit menu's items act on the focused widget.

	is_edit_command (a_command: INTEGER): BOOLEAN
		do
			Result := a_command >= Edit_undo and a_command <= Edit_select_all
		end

	can_edit (a_command: INTEGER): BOOLEAN
			-- Would `perform_edit' do something now? (An Edit menu grays the item when not.)
			-- Nothing, by default; a text box redefines it.
		require
			known: is_edit_command (a_command)
		do
		end

	perform_edit (a_command: INTEGER)
			-- Carry out edit command `a_command'.
		require
			known: is_edit_command (a_command)
			possible: can_edit (a_command)
		do
		end

feature -- Own appearance (a style over the theme)

	style: detachable SW_WIDGET_STYLE
			-- This widget's own appearance; Void: the theme's.

	set_style (a_style: detachable SW_WIDGET_STYLE)
			-- Wear `a_style' (Void: the theme's own again). A font or a padding changes the
			-- preferred sizes, so the caller lays the window out again.
		do
			style := a_style
		ensure
			set: style = a_style
		end

	shows_style (a_part: INTEGER): BOOLEAN
			-- Has this widget's drawing a place for the style part `a_part' (an
			-- SW_WIDGET_STYLE Part_* code)? Nothing here: each class says what it shows, and
			-- its drawing takes every styled value through `shown_style', so what a class
			-- does not claim it cannot draw.
		require
			part_known: a_part >= {SW_WIDGET_STYLE}.Part_foreground and a_part <= {SW_WIDGET_STYLE}.Part_scroll_bars
		do
		end

	shown_style (a_part: INTEGER): detachable SW_WIDGET_STYLE
			-- `style' when it sets `a_part' and this widget shows that part; Void otherwise.
		require
			part_known: a_part >= {SW_WIDGET_STYLE}.Part_foreground and a_part <= {SW_WIDGET_STYLE}.Part_scroll_bars
		do
			if attached style as al_style and then al_style.has (a_part) and then shows_style (a_part) then
				Result := al_style
			end
		ensure
			only_set_and_shown: attached Result as al_shown implies
				(al_shown = style and al_shown.has (a_part) and shows_style (a_part))
		end

	styled_ink (a_own: NATURAL_32): NATURAL_32
			-- The text color: the style's foreground when shown, else `a_own'.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_foreground) as al_style then
				Result := al_style.foreground
			else
				Result := a_own
			end
		end

	styled_ground (a_own: NATURAL_32): NATURAL_32
			-- The fill behind the widget: the style's background when shown, else `a_own'.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_background) as al_style then
				Result := al_style.background
			else
				Result := a_own
			end
		end

	styled_placeholder (a_own: NATURAL_32): NATURAL_32
			-- The placeholder's color: the style's when shown, else `a_own'.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_placeholder) as al_style then
				Result := al_style.placeholder
			else
				Result := a_own
			end
		end

	styled_selection (a_own: NATURAL_32): NATURAL_32
			-- The fill behind what is selected: the style's when shown, else `a_own'.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_selection) as al_style then
				Result := al_style.selection
			else
				Result := a_own
			end
		end

	styled_size (a_own: REAL_64): REAL_64
			-- The type size: the style's when shown, else `a_own'.
		require
			positive: a_own > 0.0
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_size) as al_style then
				Result := al_style.size
			else
				Result := a_own
			end
		ensure
			positive: Result > 0.0
		end

	styled_weight (a_bold: BOOLEAN): INTEGER
			-- The weight: the style's when shown, else 700 for `a_bold' and 400 otherwise.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_weight) as al_style then
				Result := al_style.weight
			elseif a_bold then
				Result := 700
			else
				Result := 400
			end
		ensure
			in_range: Result >= 1 and Result <= 1000
		end

	styled_role (a_own: INTEGER): INTEGER
			-- The type role: the style's when it names one and the family part is shown,
			-- else `a_own'.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_family) as al_style and then al_style.font_role /= 0 then
				Result := al_style.font_role
			else
				Result := a_own
			end
		end

	styled_family: detachable STRING_32
			-- The family that leads the role's faces, when the style names one and it is shown.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_family) as al_style and then not al_style.family.is_empty then
				Result := al_style.family
			end
		ensure
			never_empty: attached Result as al_family implies not al_family.is_empty
		end

	styled_italic: BOOLEAN
			-- Is the text slanted by the style?
		do
			Result := attached shown_style ({SW_WIDGET_STYLE}.Part_italic) as al_style and then al_style.is_italic
		end

	has_styled_font: BOOLEAN
			-- Does the style change the font this widget's text is set in?
		do
			Result := attached shown_style ({SW_WIDGET_STYLE}.Part_family)
				or attached shown_style ({SW_WIDGET_STYLE}.Part_size)
				or attached shown_style ({SW_WIDGET_STYLE}.Part_weight)
				or attached shown_style ({SW_WIDGET_STYLE}.Part_italic)
		end

	use_font (a_p: SW_PAINTER; a_role: INTEGER; a_size: REAL_64; a_bold: BOOLEAN)
			-- Select into `a_p' the font this widget's text is drawn in: `a_role', `a_size'
			-- and `a_bold' as the class asks, with the style's family, size, weight and slant
			-- in their place where it sets them.
		require
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
			size_positive: a_size > 0.0
		do
			if has_styled_font then
				a_p.font_faced (styled_role (a_role), styled_size (a_size), styled_weight (a_bold),
					styled_italic, styled_family)
			else
				a_p.font (a_role, a_size, a_bold)
			end
		ensure
			faced_exactly_when_styled: a_p.is_font_faced = has_styled_font
		end

	style_inset_top: REAL_64
			-- The room the style's frame takes at the top: its padding plus its border.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_padding) as al_style then
				Result := al_style.padding_top
			end
			Result := Result + style_border
		ensure
			non_negative: Result >= 0.0
		end

	style_inset_bottom: REAL_64
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_padding) as al_style then
				Result := al_style.padding_bottom
			end
			Result := Result + style_border
		ensure
			non_negative: Result >= 0.0
		end

	style_inset_start: REAL_64
			-- At the side reading starts from.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_padding) as al_style then
				Result := al_style.padding_start
			end
			Result := Result + style_border
		ensure
			non_negative: Result >= 0.0
		end

	style_inset_end: REAL_64
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_padding) as al_style then
				Result := al_style.padding_end
			end
			Result := Result + style_border
		ensure
			non_negative: Result >= 0.0
		end

	style_inset_left: REAL_64
			-- The start side's room, or the end side's when this widget `mirrors_layout'.
		do
			if mirrors_layout then
				Result := style_inset_end
			else
				Result := style_inset_start
			end
		end

	style_inset_right: REAL_64
		do
			if mirrors_layout then
				Result := style_inset_start
			else
				Result := style_inset_end
			end
		end

	style_inset_width: REAL_64
			-- The frame's room on both sides together.
		do
			Result := style_inset_start + style_inset_end
		ensure
			definition: Result = style_inset_start + style_inset_end
		end

	style_inset_height: REAL_64
			-- The frame's room above and below together.
		do
			Result := style_inset_top + style_inset_bottom
		ensure
			definition: Result = style_inset_top + style_inset_bottom
		end

	style_radius: REAL_64
			-- The corner radius the style gives the frame, no more than half the smaller side.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_radius) as al_style then
				Result := al_style.radius.min (width.min (height) / 2.0)
			end
		ensure
			non_negative: Result >= 0.0
		end

	styled_scroll_bars: INTEGER
			-- When this widget's scroll bars show: the style's kind where it sets one and
			-- the widget shows it, else Scroll_bars_system. (An owner hands it to its bar:
			-- SW_SCROLLBAR.set_mode.)
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_scroll_bars) as al_style then
				Result := al_style.scroll_bars
			end
		ensure
			a_kind: Result >= {SW_WIDGET_STYLE}.Scroll_bars_system and Result <= {SW_WIDGET_STYLE}.Scroll_bars_hidden
		end

	has_style_frame: BOOLEAN
			-- Does the style draw anything on this widget's bounds: a shadow, a background
			-- or a border?
		do
			Result := attached shown_style ({SW_WIDGET_STYLE}.Part_shadow)
				or attached shown_style ({SW_WIDGET_STYLE}.Part_background)
				or (attached shown_style ({SW_WIDGET_STYLE}.Part_border) and style_border > 0.0)
		end

	draw_style_frame (a_p: SW_PAINTER)
			-- `draw_style_frame_rounded' at the style's own radius (square without one).
		do
			draw_style_frame_rounded (a_p, style_radius)
		end

	draw_style_frame_rounded (a_p: SW_PAINTER; a_radius: REAL_64)
			-- The shadow, the background and the border the style gives this widget, on its
			-- bounds, with corners of `a_radius' (a class with corners of its own passes
			-- them). A border without a color of its own (the style's colors are dropped
			-- under a contrast theme) takes the theme's ink.
		require
			radius_non_negative: a_radius >= 0.0
		do
			draw_style_shadow (a_p, a_radius)
			draw_style_ground (a_p, a_radius)
			draw_style_border (a_p, a_radius)
		end

	draw_style_shadow (a_p: SW_PAINTER; a_radius: REAL_64)
			-- The shadow the style casts from this widget's bounds; nothing without one.
		require
			radius_non_negative: a_radius >= 0.0
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_shadow) as al_style then
				a_p.shadow_rrect (x + al_style.shadow_x, y + al_style.shadow_y, width, height, a_radius,
					al_style.shadow_blur, (if al_style.has_shadow_color then al_style.shadow_color else {NATURAL_32} 0 end),
					al_style.shadow_alpha)
			end
		end

	draw_style_ground (a_p: SW_PAINTER; a_radius: REAL_64)
			-- The style's background over this widget's bounds; nothing without one.
		require
			radius_non_negative: a_radius >= 0.0
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_background) as al_style then
				a_p.set_color (al_style.background)
				a_p.rrect_fill (x, y, width, height, a_radius)
			end
		end

	draw_style_border (a_p: SW_PAINTER; a_radius: REAL_64)
			-- The style's border, inside this widget's bounds; nothing without one.
		require
			radius_non_negative: a_radius >= 0.0
		local
			l_bw: REAL_64
		do
			l_bw := style_border
			if l_bw > 0.0 and then attached shown_style ({SW_WIDGET_STYLE}.Part_border) as al_style
				and then width > l_bw and then height > l_bw
			then
				a_p.set_color (if al_style.has_border_color then al_style.border_color else a_p.theme.ink end)
				a_p.set_line_width (l_bw)
				a_p.rrect_stroke (x + l_bw / 2.0, y + l_bw / 2.0, width - l_bw, height - l_bw,
					(a_radius - l_bw / 2.0).max (0.0))
				a_p.set_line_width (1.0)
			end
		end

	within_style_frame (a_action: PROCEDURE)
			-- Run `a_action' with the bounds inset by the style's frame, then restore them.
		local
			l_x, l_y, l_w, l_h: REAL_64
		do
			if style_inset_width > 0.0 or style_inset_height > 0.0 then
				l_x := x
				l_y := y
				l_w := width
				l_h := height
				set_bounds (l_x + style_inset_left, l_y + style_inset_top,
					(l_w - style_inset_width).max (0.0), (l_h - style_inset_height).max (0.0))
				a_action.call
				set_bounds (l_x, l_y, l_w, l_h)
			else
				a_action.call
			end
		ensure
			bounds_kept: x = old x and y = old y and width = old width and height = old height
		end

feature {NONE} -- Own appearance: parts by kind

	style_border: REAL_64
			-- The width of the border the style gives this widget, 0 without one.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_border) as al_style then
				Result := al_style.border_width
			end
		ensure
			non_negative: Result >= 0.0
		end

	is_text_style_part (a_part: INTEGER): BOOLEAN
			-- Is `a_part' one of the parts text is drawn with: its color and its font?
		do
			Result := a_part = {SW_WIDGET_STYLE}.Part_foreground
				or (a_part >= {SW_WIDGET_STYLE}.Part_family and a_part <= {SW_WIDGET_STYLE}.Part_italic)
		end

	is_frame_style_part (a_part: INTEGER): BOOLEAN
			-- Is `a_part' one of the parts `draw_style_frame' and `within_style_frame' show:
			-- background, padding, border, radius or shadow?
		do
			Result := a_part = {SW_WIDGET_STYLE}.Part_background
				or (a_part >= {SW_WIDGET_STYLE}.Part_padding and a_part <= {SW_WIDGET_STYLE}.Part_shadow)
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- Natural width; 0.0 means "give me what you have".
		do
			Result := 0.0
		ensure
			non_negative: Result >= 0.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- Natural height when laid out `a_width' wide.
		deferred
		ensure
			non_negative: Result >= 0.0
		end

	arrange (a_p: SW_PAINTER)
			-- Place children (containers); leaves need nothing.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		deferred
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- Deepest widget under the point, if any.
		do
			if contains (a_px, a_py) then
				Result := Current
			end
		ensure
			inside_when_found: Result = Current implies contains (a_px, a_py)
		end

feature -- Input

	accepts_focus: BOOLEAN
			-- Should a click here move the keyboard focus?
		do
			Result := False
		end

	wants_tab: BOOLEAN
			-- Does this widget consume the Tab CHARACTER itself
			-- (spreadsheet cell-advance)? When False, Tab traverses
			-- window focus instead of arriving here.
		do
			Result := False
		end

	cursor_kind: INTEGER
			-- The pointer shape over this widget: 0 arrow, 1 ibeam,
			-- 2 hand, 3 size-we, 4 size-ns, 5 cross, 6 wait
			-- (SHELL_WINDOW's cursor vocabulary).
		do
			Result := 0
		end

	is_focused: BOOLEAN
			-- Does this widget hold the keyboard focus?
			-- Maintained by the window; drawn by the widget.

	is_hovered: BOOLEAN
			-- Is the pointer over this widget? Window-maintained.

	is_pressed: BOOLEAN
			-- Is the pointer held down on this widget? Window-maintained.

	is_enabled: BOOLEAN
			-- Does this widget accept input? Disabled widgets draw muted
			-- and are skipped by dispatch.
		do
			Result := not is_disabled
		end

	set_focused (a_focused: BOOLEAN)
		do
			if is_focused /= a_focused then
				is_focused := a_focused
				if attached focus_event as e then
					e.call ([a_focused])
				end
			end
		ensure
			set: is_focused = a_focused
		end

	hover_px: REAL_64
	hover_py: REAL_64
			-- Pointer position while hovered, for widgets that signal
			-- per-part hover (list rows, scrollbar thumbs, radio dots).

	shows_hover: BOOLEAN
			-- Should hover feedback draw right now? On by default;
			-- silence per widget with set_hover_signal (False).
		do
			Result := is_hovered and then is_enabled and then not is_hover_silenced
		end

	set_hover_signal (a_on: BOOLEAN)
		do
			is_hover_silenced := not a_on
		ensure
			set: shows_hover implies a_on
		end

	hover_silenced: like Current
			-- Fluent: Current with hover feedback off.
		do
			is_hover_silenced := True
			Result := Current
		ensure
			chained: Result = Current
		end

	is_hover_silenced: BOOLEAN
			-- Stored inverted: fresh widgets signal hover.

	wants_hover_point: BOOLEAN
			-- Should the window re-render on every pointer move over
			-- this widget (not only on enter/leave)?
		do
		end

	set_hover_point (a_px, a_py: REAL_64)
		do
			hover_px := a_px
			hover_py := a_py
		end

	dwell_ms: INTEGER
			-- How long the pointer must rest on this widget before the
			-- window calls `handle_dwell'; 0 (the default) never. The
			-- window times it with the shell's one-shot dwell timer,
			-- re-armed on every pointer move (GW-08).
		do
		ensure
			non_negative: Result >= 0
		end

	handle_dwell (a_px, a_py: REAL_64)
			-- The pointer has rested `dwell_ms' at (`a_px', `a_py').
		do
		end

	hover_card_at (a_px, a_py: REAL_64): detachable SW_HOVER_CARD
			-- The card this widget offers for the sub-region under
			-- (`a_px', `a_py'), asked by the window after a dwell (GW-09);
			-- Void (the default) offers none. A widget that offers cards
			-- also answers a positive `dwell_ms'.
		do
		end

	set_hovered (a_hovered: BOOLEAN)
		do
			if is_hovered /= a_hovered then
				is_hovered := a_hovered
				if attached hover_event as e then
					e.call ([a_hovered])
				end
			end
		ensure
			set: is_hovered = a_hovered
		end

	set_pressed (a_pressed: BOOLEAN)
		require
			only_enabled_press: a_pressed implies is_enabled
		do
			if is_pressed /= a_pressed then
				is_pressed := a_pressed
				if attached press_event as e then
					e.call ([a_pressed])
				end
			end
		ensure
			set: is_pressed = a_pressed
		end

	set_enabled (a_enabled: BOOLEAN)
			-- Accept input (`a_enabled') or not. Disabling a widget held down
			-- releases it first (a button whose own click disables the window's
			-- content, as Preview... does, is still pressed: 2026-11-12).
		do
			if is_disabled = a_enabled then
				if not a_enabled and is_pressed then
					set_pressed (False)
				end
				is_disabled := not a_enabled
				if attached enabled_event as e then
					e.call ([a_enabled])
				end
			end
		ensure
			set: is_enabled = a_enabled
		end

	on_focus_change: SW_EVENT [TUPLE [focused: BOOLEAN]]
			-- Fires when is_focused CHANGES (the datum is the new
			-- truth). Lazily allocated - unobserved widgets pay one
			-- Void test. With on_hover_change, on_press_change and
			-- on_enabled_change, the widget's own state machine is
			-- observable: subscribe permanents or kamikazes and the
			-- GUI state machine emerges by default (Larry's design).
		do
			if attached focus_event as e then
				Result := e
			else
				create Result.make
				focus_event := Result
			end
		end

	on_hover_change: SW_EVENT [TUPLE [hovered: BOOLEAN]]
			-- Fires when is_hovered changes.
		do
			if attached hover_event as e then
				Result := e
			else
				create Result.make
				hover_event := Result
			end
		end

	on_press_change: SW_EVENT [TUPLE [pressed: BOOLEAN]]
			-- Fires when is_pressed changes.
		do
			if attached press_event as e then
				Result := e
			else
				create Result.make
				press_event := Result
			end
		end

	on_enabled_change: SW_EVENT [TUPLE [enabled: BOOLEAN]]
			-- Fires when is_enabled changes - by hand or by an
			-- enabled_when condition; the sensitivity pass speaks
			-- through the same queue.
		do
			if attached enabled_event as e then
				Result := e
			else
				create Result.make
				enabled_event := Result
			end
		end

	enabled_when: detachable FUNCTION [BOOLEAN]
			-- The enabling condition: the window re-queries it after
			-- every user interaction and applies its verdict - state
			-- control by agent collection, the Vision2 sensitivity
			-- idiom (Larry's call). Void = enablement is manual.

	set_enabled_when (a_condition: FUNCTION [BOOLEAN])
			-- Install the condition and apply it immediately.
		do
			enabled_when := a_condition
			set_enabled (a_condition.item ([]))
		ensure
			installed: enabled_when = a_condition
			applied: is_enabled = a_condition.item ([])
		end

	refresh_enabling
			-- Re-query conditions down the whole subtree; sub_widgets
			-- is the spine (containers expose their children there),
			-- so one walk from the root refreshes the entire face.
		do
			if attached enabled_when as c then
				set_enabled (c.item ([]))
			end
			across
				sub_widgets as sw
			loop
				sw.refresh_enabling
			end
		end

	disabled: like Current
			-- Fluent: Current, disabled.
		do
			set_enabled (False)
			Result := Current
		ensure
			off: not is_enabled
			chained: Result = Current
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- React to a click; True when consumed. False lets the
			-- window bubble the click to the parent chain.
		do
		end

	perform_click
			-- Click this widget's middle as a user would (W11, simple_gui's test door): what
			-- `handle_click' does there, with no window, focus or keystrokes needed.
		do
			handle_click (x + width / 2.0, y + height / 2.0).do_nothing
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := handle_click (a_px, a_py)
		end

	handle_triple_click (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := handle_double_click (a_px, a_py)
		end

	handle_drag (a_px, a_py: REAL_64)
		do
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- React to a mouse-wheel turn; True when consumed.
		do
		end

	handle_context (a_px, a_py: REAL_64): BOOLEAN
			-- React to a right-click; True when consumed. Prefer
			-- declaring a menu via context_menu and letting the window
			-- present it; use this hook only for non-menu reactions.
		do
		end

	pebble: detachable ANY
			-- What a pick lifts from this widget; Void = not a source.
			-- Vision2's pick-and-drop, contract-checked: by default the
			-- stored pebble_item; redefine for position-dependent picks.
		do
			Result := pebble_item
		end

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
			-- The widgets this one owns, for tooling that walks the
			-- tree (the dev mesh, the coming inspector tree panel).
			-- Leaves answer empty; containers redefine.
		do
			create Result.make (0)
		ensure
			answered: Result /= Void
		end

	focusables (a_acc: ARRAYED_LIST [SW_WIDGET])
			-- Append, in tree order, every enabled widget below (and
			-- including) this one that accepts keyboard focus - the
			-- window's Tab ring, collected purely so a headless
			-- assault can hold it to account.
		do
			if not is_hidden then
				if accepts_focus and is_enabled then
					a_acc.extend (Current)
				end
				across
					sub_widgets as sw
				loop
					sw.focusables (a_acc)
				end
			end
		ensure
			grew_or_not: a_acc.count >= old a_acc.count
		end

	dev_note: detachable STRING_32
			-- Creator-supplied provenance for the dev-mode inspector:
			-- intent, wiring rationale - what reflection cannot know.

	set_dev_note (a_note: READABLE_STRING_GENERAL)
		do
			create dev_note.make_from_string_general (a_note)
		ensure
			noted: dev_note /= Void
		end

	with_dev_note (a_note: READABLE_STRING_GENERAL): like Current
		do
			set_dev_note (a_note)
			Result := Current
		ensure
			chained: Result = Current
		end

	accepts_files: BOOLEAN
			-- Does this widget welcome files dropped from the shell?
			-- The pebble protocol's file-shaped sibling. By default: when
			-- it has a `files_hook'.
		do
			Result := files_hook /= Void
		end

	receive_files (a_paths: ARRAYED_LIST [STRING_32]; a_px, a_py: REAL_64)
			-- Take the dropped paths (drop point in widget space). By
			-- default `files_hook' takes them.
		require
			welcome: accepts_files
			something: not a_paths.is_empty
		do
			if attached files_hook as al_hook then
				al_hook.call ([a_paths])
			end
		end

	files_hook: detachable PROCEDURE [ARRAYED_LIST [STRING_32]]
			-- Takes files dropped from the shell, for a client that composes
			-- widgets rather than redefining them (simple_gui 1q-b).

	set_files_hook (a_hook: like files_hook)
		do
			files_hook := a_hook
		ensure
			set: files_hook = a_hook
		end

	accepts_text: BOOLEAN
			-- Does this widget welcome text dragged in from other programs? By default: when
			-- it has a `text_drop_hook'. The window takes text only after
			-- `SHELL_WINDOW.set_accepts_text'.
		do
			Result := text_drop_hook /= Void
		end

	receive_text (a_text: STRING_32; a_px, a_py: REAL_64)
			-- Take text dragged in (drop point in widget space). By default `text_drop_hook'
			-- takes it.
		require
			welcome: accepts_text
		do
			if attached text_drop_hook as al_hook then
				al_hook.call ([a_text])
			end
		end

	text_drop_hook: detachable PROCEDURE [STRING_32]
			-- Takes text other programs drag in, for a composing client (simple_gui 1q-c).

	set_text_drop_hook (a_hook: like text_drop_hook)
		do
			text_drop_hook := a_hook
		ensure
			set: text_drop_hook = a_hook
		end

	drag_out_data: detachable TUPLE [text, paths: STRING_32]
			-- What a drag out of this widget gives other programs: text, and file paths one
			-- per line (simple_gui 1q-c). The client keeps it current.

	has_drag_out: BOOLEAN
			-- Does a drag out of this widget carry something?
		do
			Result := drag_out_data /= Void
		end

	set_drag_out (a_text, a_paths: READABLE_STRING_GENERAL)
			-- Drag `a_text' and the newline-separated `a_paths' out of this widget (both empty:
			-- nothing). A press that moves starts the drag; with a pebble too, the pick runs
			-- inside the window and becomes this drag when the pointer leaves it.
		do
			if a_text.is_empty and a_paths.is_empty then
				drag_out_data := Void
			else
				drag_out_data := [create {STRING_32}.make_from_string_general (a_text),
					create {STRING_32}.make_from_string_general (a_paths)]
			end
		ensure
			none_when_empty: (a_text.is_empty and a_paths.is_empty) = not has_drag_out
		end

	drag_out_ended_hook: detachable PROCEDURE [INTEGER]
			-- Told how a drag out of this widget ended: `SHELL_WINDOW.Drag_copied',
			-- `Drag_refused', or `Drag_landed_here'.

	set_drag_out_ended_hook (a_hook: like drag_out_ended_hook)
		do
			drag_out_ended_hook := a_hook
		ensure
			set: drag_out_ended_hook = a_hook
		end

	pebble_at (a_px, a_py: REAL_64): detachable ANY
			-- The pebble offered at a specific point - by default
			-- `pebble_hook''s answer when there is one, else the
			-- widget-wide `pebble'. Virtualized widgets redefine this
			-- to offer per-row or per-cell pebbles.
		do
			if attached pebble_hook as al_hook then
				Result := al_hook.item ([a_px, a_py])
			else
				Result := pebble
			end
		end

	pebble_hook: detachable FUNCTION [TUPLE [x, y: REAL_64], detachable ANY]
			-- Answers the pebble at a point (window space), for a client
			-- that composes widgets rather than redefining them (simple_gui
			-- 1q); Void: `pebble'.

	accepts_hook: detachable FUNCTION [TUPLE [pebble: ANY; x, y: REAL_64], BOOLEAN]
			-- Answers whether a pebble may land at a point; Void: `accepts_pebble'.

	receive_hook: detachable PROCEDURE [TUPLE [pebble: ANY; x, y: REAL_64]]
			-- Takes a pebble landing at a point; Void: `receive_pebble'.

	picks_on_drag: BOOLEAN
			-- Does a press that moves a few pixels on this widget lift its
			-- pebble (and the release drop it)?

	picks_on_secondary: BOOLEAN
			-- Does a secondary click on this widget lift its pebble (a line
			-- follows the pointer, a click drops), before any context menu?

	set_pebble_hook (a_hook: like pebble_hook)
		do
			pebble_hook := a_hook
		ensure
			set: pebble_hook = a_hook
		end

	set_drop_hooks (an_accepts: like accepts_hook; a_receive: like receive_hook)
			-- Decide and take drops with agents (both, or neither).
		require
			both_or_neither: (an_accepts = Void) = (a_receive = Void)
		do
			accepts_hook := an_accepts
			receive_hook := a_receive
		ensure
			accepts_set: accepts_hook = an_accepts
			receive_set: receive_hook = a_receive
		end

	set_pick_gestures (a_drag, a_secondary: BOOLEAN)
			-- Which gestures lift this widget's pebble.
		do
			picks_on_drag := a_drag
			picks_on_secondary := a_secondary
		ensure
			drag_set: picks_on_drag = a_drag
			secondary_set: picks_on_secondary = a_secondary
		end

	set_pebble (a_pebble: detachable ANY)
		do
			pebble_item := a_pebble
		ensure
			set: pebble_item = a_pebble
		end

	with_pebble (a_pebble: ANY): like Current
			-- Fluent pick-source declaration.
		do
			pebble_item := a_pebble
			Result := Current
		ensure
			chained: Result = Current
		end

	accepts_pebble (a_pebble: ANY): BOOLEAN
			-- Would this widget welcome `a_pebble'? The hole's type
			-- check, as an honest query.
		do
		end

	receive_pebble (a_pebble: ANY)
			-- Accept the drop.
		require
			welcome: accepts_pebble (a_pebble)
			enabled: is_enabled
		do
		end

	accepts_pebble_at (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- Would this widget welcome `a_pebble' dropped at the point
			-- (window space)? By default the pointless `accepts_pebble'; a
			-- hole whose answer depends on the point (a tree row, a folder)
			-- redefines this AND `receive_pebble_at' together (0.55.0).
			-- `accepts_hook' answers instead when there is one.
		do
			if attached accepts_hook as al_hook then
				Result := al_hook.item ([a_pebble, a_px, a_py])
			else
				Result := accepts_pebble (a_pebble)
			end
		end

	receive_pebble_at (a_pebble: ANY; a_px, a_py: REAL_64)
			-- Accept the drop at the point (window space). By default the
			-- pointless `receive_pebble'.
		require
			welcome: accepts_pebble_at (a_pebble, a_px, a_py)
			enabled: is_enabled
		do
			if attached receive_hook as al_hook then
				al_hook.call ([a_pebble, a_px, a_py])
			elseif accepts_pebble (a_pebble) then
				receive_pebble (a_pebble)
			end
		end

	pebble_card_at (a_px, a_py: REAL_64): STRING_32
			-- A few words that travel beside the pointer with the pebble
			-- offered at the point (the quote's opening words and its
			-- source); empty for none (0.55.0).
		do
			create Result.make_empty
		ensure
			answered: Result /= Void
		end

	responds_to_pick (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- Does this widget act while a pebble passes over the point,
			-- though it may not take it (a tab that springs open, a
			-- folder's arrow)? The window sends `pick_hover', `pick_tick'
			-- and `pick_click' to the first widget, leaf upward, that
			-- responds. By default: if it would take the pebble there.
		do
			Result := accepts_pebble_at (a_pebble, a_px, a_py)
		end

	pick_hover (a_pebble: ANY; a_px, a_py: REAL_64)
			-- A pebble is over the point (window space): light the spot it
			-- would land on. Called on every move while this widget
			-- responds.
		do
		end

	pick_tick (a_pebble: ANY): BOOLEAN
			-- The window's heartbeat while a pebble rests over this widget:
			-- time a spring-open or scroll near an edge. True when it
			-- changed what it shows.
		do
		end

	pick_click (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- A press at the point while picking: True when this widget used
			-- the press for itself (opened a folder by its arrow, chose a
			-- tab) and the pebble stays in flight; False lets it drop.
		do
		end

	pick_ended
			-- The pick that passed over this widget dropped or was
			-- canceled: put away what it sprang open or lit.
		do
		end

	pick_request: detachable TUPLE [pebble: ANY; card: STRING_32]
			-- A pick this widget asked to start (a drag out of a
			-- selection), consumed by the window after the event that
			-- raised it - the handshake `pending_menu' uses (0.55.0).

	request_pick (a_pebble: ANY; a_card: READABLE_STRING_GENERAL)
			-- Ask the window to lift `a_pebble' under the pointer; it drops
			-- where the button is released.
		do
			pick_request := [a_pebble, a_card.to_string_32]
		ensure
			asked: attached pick_request as al_asked and then al_asked.pebble = a_pebble
		end

	take_pick_request: detachable TUPLE [pebble: ANY; card: STRING_32]
			-- One-shot: the pending pick request, consumed on read.
		do
			Result := pick_request
			pick_request := Void
		ensure
			consumed: pick_request = Void
		end

	takes_typing: BOOLEAN
			-- Holding the keyboard, does this widget keep Ctrl+Z, Ctrl+Y and
			-- their kin for its own typing (an editable text box)? A window's
			-- yielding accelerators step aside for it (0.56.0).
		do
		end

	Drag_distance: INTEGER = 4
			-- Pixels the pointer must move with the button held before a
			-- press becomes a drag: Windows' default SM_CXDRAG and
			-- SM_CYDRAG.

	pebble_item: detachable ANY
			-- Stored pebble behind the default `pebble'.

	focus_event: detachable SW_EVENT [TUPLE [focused: BOOLEAN]]
			-- Backing store for on_focus_change; Void until observed.

	hover_event: detachable SW_EVENT [TUPLE [hovered: BOOLEAN]]

	press_event: detachable SW_EVENT [TUPLE [pressed: BOOLEAN]]

	enabled_event: detachable SW_EVENT [TUPLE [enabled: BOOLEAN]]

	pending_popover: detachable SW_WIDGET
			-- A widget tree this widget wants presented as an
			-- anchored popover at its foot - the pending-menu
			-- handshake's sibling. The window takes it after the
			-- click that set it.

	pending_popover_width: REAL_64

	take_pending_popover: detachable SW_WIDGET
		do
			Result := pending_popover
			pending_popover := Void
		ensure
			taken: pending_popover = Void
		end

	requests_sheet_close: BOOLEAN
			-- Has this widget asked the window to close the overlay
			-- it lives in (a popover picker completing its pick)?

	request_sheet_close
			-- Ask the window to close the overlay after this
			-- interaction; consumed by `take_sheet_close_request'.
		do
			requests_sheet_close := True
		ensure
			asked: requests_sheet_close
		end

	take_sheet_close_request: BOOLEAN
			-- One-shot: the pending close request, consumed on read.
		do
			Result := requests_sheet_close
			requests_sheet_close := False
		ensure
			consumed: not requests_sheet_close
		end

	pending_menu: detachable SW_MENU
			-- A menu this widget wants presented after its click was
			-- handled - the dropdown handshake: the widget declares
			-- during handle_click, the window presents and clears.

	take_pending_menu: detachable SW_MENU
			-- The pending menu, consumed.
		do
			Result := pending_menu
			pending_menu := Void
		ensure
			consumed: pending_menu = Void
		end

	menu_left: REAL_64
			-- Where a menu this widget offers (`take_pending_menu') drops: its left edge. A widget
			-- that offers menus from parts of itself says which part (SW_MENU_BAR, 0.51.0).
		do
			Result := x
		end

	menu_top: REAL_64
			-- Where that menu's top edge goes: just under the widget. A widget that offers it
			-- from a part of itself (a table's cell, simple_gui 1s) says which.
		do
			Result := y + height + 2.0
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- The menu this widget offers at the point, if any. The
			-- window presents it; every widget is right-clickable, and
			-- the only question is whether something is defined here.
		do
		end

	menu_extension: detachable PROCEDURE [SW_MENU, REAL_64, REAL_64]
			-- A client's own items for this widget's right-click menu:
			-- called with an empty menu and the point, after the widget's
			-- `context_menu' was asked (so a grid has already noted the
			-- row under the pointer); what it adds stands first.

	set_menu_extension (a_action: detachable PROCEDURE [SW_MENU, REAL_64, REAL_64])
		do
			menu_extension := a_action
		ensure
			set: menu_extension = a_action
		end

	menu_extension_replaces: BOOLEAN
			-- Do the client's `menu_extension' items stand in for the widget's
			-- own `context_menu' (as AppKit's and GTK's context menus replace a
			-- control's defaults), rather than come before them?

	set_menu_extension_replaces (a_on: BOOLEAN)
		do
			menu_extension_replaces := a_on
		ensure
			set: menu_extension_replaces = a_on
		end

	offered_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- What a right-click at the point presents: the client's
			-- `menu_extension' items, a separator, then the widget's own
			-- `context_menu' (left out when `menu_extension_replaces');
			-- Void when nothing offers an item.
		local
			l_own: detachable SW_MENU
		do
			l_own := context_menu (a_px, a_py)
			if attached menu_extension as al_extension then
				create Result.make
				al_extension.call ([Result, a_px, a_py])
				if not menu_extension_replaces and then attached l_own as al_own and then not al_own.items.is_empty then
					if not Result.items.is_empty then
						Result.add_separator
					end
					Result.append_items (al_own)
				end
				if Result.items.is_empty then
					Result := Void
				end
			else
				Result := l_own
			end
		ensure
			extended_never_empty: (menu_extension /= Void and attached Result as al_result) implies not al_result.items.is_empty
		end

	handle_char (a_code: INTEGER)
		do
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
		end

	handle_release (a_x, a_y: INTEGER)
			-- The pointer let go while this widget held the capture.
			-- No-op by default; press-and-hold interactions (a brake
			-- pedal, a scrub) redefine it.
		do
		end

feature -- Accessibility (GW-14)

	accessible_name: STRING_32
			-- What a screen reader announces for this widget: the name given
			-- with `set_accessible_name', else `default_accessible_name'.
		do
			if attached accessible_name_override as al_name then
				Result := al_name
			else
				Result := default_accessible_name
			end
		end

	default_accessible_name: STRING_32
			-- The widget's own name: its label or text where it has one.
		do
			create Result.make_empty
		end

	accessible_role: INTEGER
			-- Its UI Automation control type (a {SW_ACCESSIBILITY} `Role_'
			-- constant): a pane when it holds widgets, else custom. Widgets
			-- with a standard role redefine it.
		do
			if accessible_children.is_empty then
				Result := {SW_ACCESSIBILITY}.Role_custom
			else
				Result := {SW_ACCESSIBILITY}.Role_pane
			end
		end

	accessible_value: detachable READABLE_STRING_32
			-- Its current value, read-only, when it has one (a text box's
			-- text, a progress percentage); Void for none. A long value is
			-- best handed over as one IMMUTABLE_STRING_32 for as long as it
			-- stands: SW_ACCESSIBILITY converts such an object once.
		do
		end

	accessible_children: ARRAYED_LIST [SW_WIDGET]
			-- The widgets a screen reader can reach below this one: those it
			-- shows (`sub_widgets' by default, without hidden ones; a notebook
			-- redefines it to its shown page only).
		do
			create Result.make (sub_widgets.count)
			across sub_widgets as ic loop
				if not ic.is_hidden then
					Result.extend (ic)
				end
			end
		end

	shared_role_name: detachable STRING_32
			-- This widget's role in the shared vocabulary (GTK 4's role names, which
			-- simple_gui's tests read on every platform) when UI Automation's control type
			-- cannot say it: a switch is a check box to UI Automation, a radio group a group.
			-- Void: named from `accessible_role'.
		do
		end

	accessible_item_count: INTEGER
			-- Nodes this widget publishes below its own that are not widgets (a list's rows).
		do
		ensure
			non_negative: Result >= 0
		end

	accessible_item_id (a_k: INTEGER): INTEGER
			-- The node id of this widget's `a_k'th item: a block of 2,048 ids per widget, below
			-- `SW_WINDOW.Floating_ids' (the scheme SW_LIST's rows use).
		require
			in_block: a_k >= 1 and a_k < 2_048
		do
			Result := 500_000_000 + (accessible_node_id \\ 200_000) * 2_048 + a_k
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
			-- Add those `accessible_item_count' nodes under this widget's node (W6).
		do
		end

	set_accessible_name (a_name: READABLE_STRING_GENERAL)
			-- Name this widget for screen readers (an icon button, a field
			-- whose label is drawn beside it).
		do
			create accessible_name_override.make_from_string_general (a_name)
		ensure
			named: accessible_name.same_string_general (a_name)
		end

	accessible_name_override: detachable STRING_32
			-- The name given with `set_accessible_name'.

	accessible_description: STRING_32
			-- What a screen reader says after the name (W10: UI Automation's HelpText,
			-- simple_gui's accessible description). Empty by default.
		attribute
			create Result.make_empty
		end

	set_accessible_description (a_text: READABLE_STRING_GENERAL)
		do
			create accessible_description.make_from_string_general (a_text)
		ensure
			set: accessible_description.same_string_general (a_text)
		end

	accessible_node_id: INTEGER
			-- This widget's node id for UI Automation: given once, the first
			-- time it is published, and kept for its life - so a screen
			-- reader's reference survives widgets added before it (scan 13:
			-- ids were tree positions and shifted).
		do
			if accessible_node_id_cache = 0 then
				accessible_node_id_counter.put (accessible_node_id_counter.item + 1)
				accessible_node_id_cache := accessible_node_id_counter.item
			end
			Result := accessible_node_id_cache
		ensure
			positive: Result > 0
		end

feature {NONE} -- Implementation

	accessible_node_id_cache: INTEGER

	accessible_node_id_counter: CELL [INTEGER]
			-- The last node id given, per processor: a window's widgets all live on its one processor,
			-- so ids stay unique where UI Automation reads them. Not once ("PROCESS"): a process-wide
			-- once of a non-separate type is rejected under SCOOP (VFFD(8)), and every SCOOP app
			-- failed to compile from 0.34.1 (2026-10-25) until this (simple_bible's window, 2026-10-26).
		once
			create Result.put (0)
		end

	is_disabled: BOOLEAN
			-- Stored inverted so a fresh widget is enabled by default.

feature -- Printing (GW-20)

	print_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- How tall all of this is at `a_width', to be printed: its
			-- preferred height (a widget that scrolls answers all of its
			-- content).
		require
			positive_width: a_width > 0.0
		do
			Result := preferred_height (a_p, a_width)
		ensure
			non_negative: Result >= 0.0
		end

	clean_break (a_y: REAL_64): REAL_64
			-- Where a page may end at or above `a_y' without cutting through
			-- a line of text. A widget without parts keeps itself whole (its
			-- top, when `a_y' falls inside it); one with parts asks the parts
			-- `a_y' falls in. Valid after `arrange'.
		local
			l_inside: BOOLEAN
		do
			Result := a_y
			if a_y > y and a_y < y + height then
				across
					sub_widgets as al_part
				loop
					if a_y > al_part.y and a_y < al_part.y + al_part.height then
						Result := Result.min (al_part.clean_break (a_y))
						l_inside := True
					end
				end
				if not l_inside and sub_widgets.is_empty then
					Result := y
				end
			end
		ensure
			no_lower: Result <= a_y
		end

invariant
	sane_size: width >= 0.0 and height >= 0.0
	pressed_only_when_enabled: is_pressed implies is_enabled
	grow_non_negative: grow >= 0.0
	anchors_sane: min_width >= 0.0 and min_height >= 0.0
		and max_width >= 0.0 and max_height >= 0.0

end
