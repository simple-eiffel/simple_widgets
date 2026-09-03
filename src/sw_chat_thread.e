note
	description: "[
		Wave 6 conversational: the thread - bubbles by ROLE (mine
		right in accent wash, theirs left on quiet surface, system
		centred and muted), word-wrapped inside their bubbles,
		wheel-scrolled, and STICKY to the bottom: adding a message
		follows the conversation unless the reader has scrolled
		back up (the rule every chat client honours). The model
		(roles, append_to_last for streaming, stickiness law) is
		public and assaulted headless.

		SHAPED TEXT (simple_shaping). When the painter carries a
		SW_SHAPING kit, a bubble is laid out by the shaping library
		instead of by the greedy word wrap below: bidi so Hebrew reads
		right-to-left inside a left-to-right pane, script itemization and
		font fallback so Greek and Hebrew find faces the theme face does
		not have, and emoji as the SAME Noto picture on every member's
		screen. The bubble's height is then `layout.total_height' and
		never a line count times a constant - which is the only honest
		measurement once a line may mix a 128-pixel emoji box with 13
		pixel text.

		THE OLD PATH IS STILL SELECTABLE, and it is the DEFAULT. Without
		a kit (`SW_PAINTER.has_shaping' False) this widget behaves exactly
		as it always has, down to the pixel: same `wrapped', same
		`Line_h', same bubble arithmetic. Nothing in the public model -
		`add_message', `append_to_last', `is_sticky', `content_h',
		`handle_wheel' - changes in either mode.

		R10, RE-LAYOUT AT RESIZE END. Shaping a paragraph is not free, and
		a drag delivers a resize every few milliseconds. So a WIDTH change
		waits for `SW_PAINTER.is_resize_storm' to clear (SW_WINDOW sets it
		from its own `busy_ticks' debounce) and the bubbles keep the
		layouts they have while the frame moves. A CONTENT change never
		waits: a message that arrives mid-drag still has to appear.

		THE SCROLL-CLAMP DEFECT (0.5.0) AND THE FIX. `draw' used to clamp
		`scroll_y' once PER BUBBLE, against `content_h' while it was still
		mid-accumulation (`content_h' starts the frame at 8.0 and only
		reaches its true total at the LAST bubble). Bubble 1's clamp saw a
		content height of 8.0 - far short of the real total - so on any
		pane taller than 8 pixels it collapsed `scroll_y' to 0 EVERY
		FRAME, before a single pixel had been measured honestly. The tail
		could never scroll into view, and no wheel delta or drag survived
		the next repaint: the thread looked permanently pinned to its
		top. `draw' now runs two passes - PASS 1 measures every bubble's
		height with no drawing and no dependence on `scroll_y' at all, so
		`content_h' is the true total before anything is clamped; PASS 2
		draws at the one scroll offset the frame settled on. Every
		scroll-changing entry point (`handle_wheel', a scrollbar drag or
		track click, PageUp/PageDown/Home/End) funnels through `scroll_to',
		so the same [0, max_scroll] law applies everywhere, not just here.

		THE SCROLLBAR (0.5.0). A vertical track along the right edge,
		visible only when `max_scroll' > 0.0 (`scrollbar_visible'), sized
		from SW_THEME's `text_scale' the way every other themed dimension
		in this toolkit scales. The thumb's height and position come from
		the same `thumb_height' / `thumb_top' queries `draw' paints with
		and `handle_click' / `handle_drag' hit-test with - one geometry,
		never two formulas that can drift apart. Dragging the thumb,
		clicking the bare track to page, the wheel, and (once the pane
		holds focus - it accepts it) PageUp/PageDown/Home/End all funnel
		through `scroll_to', which is where the follow-the-tail law now
		lives: sticky while within 2 px of the bottom, broken by scrolling
		up, restored by scrolling or dragging back down. Bubble wrap width
		reserves the scrollbar's gutter UNCONDITIONALLY (whether or not it
		is drawn this frame), matching SW_SCROLL_AREA's own convention -
		so text never reflows the instant the thread crosses the overflow
		line.
	]"

class
	SW_CHAT_THREAD

inherit
	SW_WIDGET
		redefine
			handle_wheel, handle_click, handle_drag, handle_release,
			handle_key, accepts_focus
		end

create
	make

feature -- Roles

	Role_mine: INTEGER = 1
	Role_theirs: INTEGER = 2
	Role_system: INTEGER = 3

feature {NONE} -- Initialization

	make
		do
			create messages.make (16)
			create shaped_layouts.make (16)
			is_sticky := True
			scrollbar_width := Scrollbar_w
			last_text_scale := 1.0
		ensure
			nothing_laid_out: shaped_layouts.is_empty
		end

feature -- Access

	messages: ARRAYED_LIST [TUPLE [role: INTEGER; text: STRING_32]]

	scroll_y: REAL_64

	is_sticky: BOOLEAN
			-- Following the conversation's tail? Adding messages
			-- auto-scrolls only while True; scrolling up breaks it,
			-- scrolling back to the bottom restores it.

	content_h: REAL_64
			-- Measured during draw; 0 before the first frame.

	shaped_layouts: ARRAYED_LIST [SHAPED_LAYOUT]
			-- One SHAPED_LAYOUT per message, in `messages' order, once a
			-- shaped frame has been drawn; empty on the toy path and
			-- before the first frame. Public because it is the widget's
			-- measurement of itself: `shaped_layouts [i].lines.count' is
			-- how many lines message `i' really needs at the width it was
			-- last laid out to.

	laid_out_width: INTEGER
			-- Bubble INNER width, in pixels, the current `shaped_layouts'
			-- were built for; 0 before the first shaped frame.

	laid_out_size: INTEGER
			-- Pixel size the current `shaped_layouts' were built at.

	revision: INTEGER
			-- Bumped by every content change. `laid_out_revision' lags it
			-- exactly when the layouts are stale.

	laid_out_revision: INTEGER
			-- `revision' as of the last re-layout.

	count: INTEGER
		do
			Result := messages.count
		end

	last_text: STRING_32
		require
			aboard: count > 0
		do
			Result := messages.last.text.twin
		end

feature -- Element change

	add_message (a_role: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			role_known: a_role >= Role_mine and a_role <= Role_system
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			messages.extend ([a_role, s])
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
					-- clamped to the true bottom at next draw
			end
		ensure
			grew: count = old count + 1
		end

	append_to_last (a_text: READABLE_STRING_GENERAL)
			-- Streaming: grow the last message in place.
		require
			aboard: count > 0
		do
			messages.last.text.append_string_general (a_text)
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 260.0
		end

feature -- Scrollbar

	Scrollbar_w: REAL_64 = 12.0
			-- Track width at 1x text.

	scrollbar_width: REAL_64
			-- `Scrollbar_w' times the theme's `text_scale' as of the most
			-- recent `draw' - cached because hit-testing (`handle_click',
			-- `handle_drag') has no painter/theme of its own to read
			-- `text_scale' from. `Scrollbar_w' (1x), set by `make', before
			-- the first frame - REAL_64 is expanded, so (unlike a
			-- reference attribute) an `attribute...end' body here would
			-- never run; `make' is where the honest default lives.

	last_text_scale: REAL_64
			-- The theme's `text_scale' as of the most recent `draw'; 1.0,
			-- set by `make', before the first frame.

	max_scroll: REAL_64
			-- How far `scroll_y' can go before the tail is showing.
		do
			Result := (content_h - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	scrollbar_visible: BOOLEAN
			-- Drawn - and hit-testable - only when the thread overflows
			-- its own pane.
		do
			Result := max_scroll > 0.0
		end

	track_x: REAL_64
		do
			Result := x + width - scrollbar_width
		end

	track_y: REAL_64
		do
			Result := y + 2.0
		end

	track_h: REAL_64
		do
			Result := (height - 4.0).max (1.0)
		end

	Min_thumb_h: REAL_64 = 24.0
			-- Smallest the thumb ever draws at 1x, so it stays
			-- grabbable over a very long thread.

	thumb_height: REAL_64
			-- The thumb's height: the pane's share of the content,
			-- never smaller than `Min_thumb_h' (scaled) nor larger than
			-- the track itself.
		do
			if content_h > 0.0 then
				Result := height / content_h * track_h
			end
			Result := Result.max (Min_thumb_h * last_text_scale).min (track_h)
		ensure
			fits_track: Result > 0.0 and Result <= track_h
		end

	thumb_top: REAL_64
			-- The thumb's Y, from `scroll_y''s fraction of `max_scroll'.
		do
			if max_scroll > 0.0 then
				Result := track_y + (scroll_y / max_scroll) * (track_h - thumb_height)
			else
				Result := track_y
			end
		ensure
			within_track: Result >= track_y - 0.001
				and Result <= track_y + (track_h - thumb_height) + 0.001
		end

	is_dragging_thumb: BOOLEAN
			-- Is the pointer holding the thumb down right now? Drives
			-- the thumb's drag colour and gates `handle_drag'.

	scroll_to (a_y: REAL_64)
			-- The one door every scroll-changing entry point uses -
			-- `handle_wheel', a scrollbar drag or track click,
			-- PageUp/PageDown/Home/End, and `draw''s own once-per-frame
			-- clamp: land at `a_y', clamped to [0, `max_scroll'], and
			-- update `is_sticky' the same way everywhere.
		do
			scroll_y := a_y.max (0.0).min (max_scroll)
			is_sticky := scroll_y >= max_scroll - 2.0
		ensure
			clamped_low: scroll_y >= 0.0
			clamped_high: scroll_y <= max_scroll
			sticky_law: is_sticky = (scroll_y >= max_scroll - 2.0)
		end

feature -- Drawing

	Bubble_pad: REAL_64 = 10.0

	Line_h: REAL_64 = 19.0

	Text_size: REAL_64 = 13.0
			-- The bubble's type size, in points on the toy path and (after
			-- the theme's scale) in PIXELS on the shaped path.

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, j, px: INTEGER
			by, bw, bx, bh, max_w, inner_w, usable_w, sb_gutter, total_h: REAL_64
			lines: detachable ARRAYED_LIST [STRING_32]
			all_lines: ARRAYED_LIST [detachable ARRAYED_LIST [STRING_32]]
			heights, widths: ARRAYED_LIST [REAL_64]
			is_shaped: BOOLEAN
		do
			t := a_p.theme
			scrollbar_width := Scrollbar_w * t.text_scale
			last_text_scale := t.text_scale
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- the gutter is reserved whether or not the bar draws
				-- this frame, so crossing the overflow line never
				-- reflows a bubble that was already on screen
			sb_gutter := scrollbar_width + 4.0
			usable_w := (width - sb_gutter).max (40.0)
			max_w := (usable_w * 0.72).max (60.0)
			inner_w := (max_w - 2.0 * Bubble_pad).max (16.0)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
			px := (Text_size * t.text_scale).rounded.max (1)
			if attached a_p.shaping as al_kit then
					-- One measurement pass for the whole thread: unchanged
					-- messages come back from the layout cache having shaped
					-- nothing, so this is cheap on a still frame.
				refresh_layouts (al_kit, inner_w, px, a_p.is_resize_storm)
				is_shaped := shaped_layouts.count = messages.count
			end

				-- PASS 1: measure every bubble - no drawing, no scroll
				-- dependence - so `content_h' is the real total BEFORE
				-- anything gets clamped against it. See the class note.
			create heights.make (messages.count)
			create widths.make (messages.count)
			create all_lines.make (messages.count)
			total_h := 8.0
			from
				i := 1
			until
				i > messages.count
			loop
				lines := Void
				if is_shaped then
					bh := shaped_layouts [i].total_height + 2.0 * Bubble_pad
					bw := (shaped_layouts [i].total_width + 2.0 * Bubble_pad).min (max_w)
				else
					lines := wrapped (a_p, messages.i_th (i).text, inner_w)
					if attached lines as al_measured then
						bh := al_measured.count * Line_h + 2.0 * Bubble_pad - 4.0
						bw := widest (a_p, al_measured) + 2.0 * Bubble_pad
					end
				end
				heights.extend (bh)
				widths.extend (bw)
				all_lines.extend (lines)
				total_h := total_h + bh + 8.0
				i := i + 1
			end
			content_h := total_h

				-- THE FIX: one clamp for the whole frame, against the
				-- true total - not one per bubble against a running sum.
			scroll_to (scroll_y)

				-- PASS 2: draw, at the now-stable offset.
			from
				i := 1
				by := y + 8.0 - scroll_y
			until
				i > messages.count
			loop
				bh := heights [i]
				bw := widths [i]
				inspect messages.i_th (i).role
				when Role_mine then
					bx := x + usable_w - bw - 10.0
				when Role_theirs then
					bx := x + 10.0
				else
					bx := x + (usable_w - bw) / 2.0
				end
				if by + bh > y and then by < y + height then
					inspect messages.i_th (i).role
					when Role_mine then
						a_p.set_color (t.wash_accent)
					when Role_theirs then
						a_p.set_color (t.surface_variant)
					else
						a_p.set_color_alpha (t.surface_variant, 0.5)
					end
					a_p.rrect_fill (bx, by, bw, bh, 7.0)
					if messages.i_th (i).role = Role_system then
						a_p.set_color (t.ink_muted)
					else
						a_p.set_color (t.ink)
					end
					if is_shaped then
							-- (x, y) here is a TOP-LEFT, not a baseline: the
							-- layout already knows each line's ascent.
						a_p.draw_shaped_layout (shaped_layouts [i],
							bx + Bubble_pad, by + Bubble_pad)
					elseif attached all_lines [i] as al_lines then
						from
							j := 1
						until
							j > al_lines.count
						loop
							a_p.text (bx + Bubble_pad, by + Bubble_pad + (j - 1) * Line_h + 9.0,
								al_lines.i_th (j))
							j := j + 1
						end
					end
				end
				by := by + bh + 8.0
				i := i + 1
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)

			if scrollbar_visible then
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (track_x, track_y, scrollbar_width - 2.0, track_h, 4.0 * last_text_scale)
				if is_dragging_thumb then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (track_x + 1.5, thumb_top, scrollbar_width - 5.0, thumb_height,
					3.0 * last_text_scale)
			end
		end

	refresh_layouts (a_kit: SW_SHAPING; a_inner_width: REAL_64; a_pixel_size: INTEGER;
			a_resize_storm: BOOLEAN)
			-- Bring `shaped_layouts' in step with `messages' at
			-- `a_inner_width' x `a_pixel_size'.
			--
			-- R10 lives in the first branch: while the frame is being
			-- dragged, a WIDTH change is ignored and the bubbles keep the
			-- layouts they have, so a drag costs zero shaping calls. A
			-- CONTENT change (a new message, a streamed token) is honoured
			-- immediately at the width already in force - a reply that
			-- arrives mid-drag must still appear.
		require
			width_positive: a_inner_width > 0.0
			size_positive: a_pixel_size > 0
		local
			w, i: INTEGER
		do
			if a_resize_storm and then not shaped_layouts.is_empty then
				w := laid_out_width
			else
				w := a_inner_width.floor.max (16)
			end
			if w /= laid_out_width or a_pixel_size /= laid_out_size
				or revision /= laid_out_revision
			then
				shaped_layouts.wipe_out
				from
					i := 1
				until
					i > messages.count
				loop
					shaped_layouts.extend (
						a_kit.layout_for (messages.i_th (i).text, w, a_pixel_size))
					i := i + 1
				end
				laid_out_width := w
				laid_out_size := a_pixel_size
				laid_out_revision := revision
			end
		ensure
			one_layout_per_message: shaped_layouts.count = messages.count
			width_recorded: laid_out_width > 0
			content_current: laid_out_revision = revision
		end

feature -- Input

	accepts_focus: BOOLEAN
			-- Yes: once the pane has been clicked, PageUp/PageDown/
			-- Home/End move it, the same ring SW_LIST joins.
		do
			Result := True
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			scroll_to (scroll_y - a_delta / 120.0 * 48.0)
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- The scrollbar only. Press the thumb to start a drag; press
			-- the bare track to page toward the click. A bubble click is
			-- not consumed here - this widget has never made bubbles
			-- clickable - so it bubbles up per the base default.
		do
			if scrollbar_visible and then a_px >= track_x then
				if a_py >= thumb_top and a_py <= thumb_top + thumb_height then
					is_dragging_thumb := True
					drag_grab_offset := a_py - thumb_top
				elseif a_py < thumb_top then
					scroll_to (scroll_y - height)
				else
					scroll_to (scroll_y + height)
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		local
			span: REAL_64
		do
			if is_dragging_thumb then
				span := (track_h - thumb_height).max (1.0)
				scroll_to (((a_py - drag_grab_offset - track_y) / span) * max_scroll)
			end
		end

	handle_release (a_x, a_y: INTEGER)
		do
			is_dragging_thumb := False
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- PageDown 34, PageUp 33, Home 36, End 35 - SW_LIST's own
			-- virtual-key vocabulary (Win32 VK_NEXT/VK_PRIOR/VK_HOME/VK_END).
		do
			inspect a_vk
			when 34 then
				scroll_to (scroll_y + height)
			when 33 then
				scroll_to (scroll_y - height)
			when 36 then
				scroll_to (0.0)
			when 35 then
				scroll_to (max_scroll)
			else
			end
		end

feature {NONE} -- Drag state

	drag_grab_offset: REAL_64
			-- Where inside the thumb the press landed, so a drag keeps
			-- the pointer over the same spot on the thumb instead of
			-- snapping its top to the cursor.

feature {NONE} -- Text machinery

	wrapped (a_p: SW_PAINTER; a_text: STRING_32; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- Greedy word wrap in the current font.
		local
			words: LIST [STRING_32]
			line: STRING_32
			cx, ww: REAL_64
		do
			create Result.make (4)
			words := a_text.split (' ')
			create line.make (48)
			across
				words as w
			loop
				ww := a_p.advance (w)
				if line.is_empty then
					line := w.twin
					cx := ww
				elseif cx + 4.5 + ww > a_width then
					Result.extend (line)
					line := w.twin
					cx := ww
				else
					line.append_character (' ')
					line.append (w)
					cx := cx + 4.5 + ww
				end
			end
			Result.extend (line)
		ensure
			at_least_one: not Result.is_empty
		end

	widest (a_p: SW_PAINTER; a_lines: ARRAYED_LIST [STRING_32]): REAL_64
		do
			across
				a_lines as l
			loop
				Result := Result.max (a_p.advance (l))
			end
		end

invariant
	messages_attached: messages /= Void
	layouts_attached: shaped_layouts /= Void
	layouts_match_when_present: not shaped_layouts.is_empty implies
		shaped_layouts.count = messages.count
	revision_non_negative: revision >= 0 and laid_out_revision >= 0
	scrollbar_width_positive: scrollbar_width > 0.0
	text_scale_recorded_positive: last_text_scale > 0.0

end
