note
	description: "[
		A delegate-drawn surface: the host paints through an agent
		and hears about pointer activity through agents. The escape
		valve for custom drawing that stays inside the painter
		monopoly - the host receives an SW_PAINTER, never a context.
	]"

class
	SW_CANVAS

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag, context_menu, wants_hover_point,
			accepts_focus, handle_key, handle_char, handle_release,
			accepts_files, receive_files, set_hover_point, set_bounds, arrange
		end

create
	make

feature {NONE} -- Initialization

	make (a_height: REAL_64)
		require
			positive: a_height > 0.0
		do
			canvas_height := a_height
			image_scale := 1.0
			device_scale := 1.0
		ensure
			kept: canvas_height = a_height
		end

feature -- Access

	canvas_height: REAL_64

	on_paint: detachable PROCEDURE [SW_PAINTER, REAL_64, REAL_64, REAL_64, REAL_64]
			-- (painter, x, y, width, height) - clipped to the canvas.

	on_press: detachable PROCEDURE [REAL_64, REAL_64]
			-- Left click at canvas-relative (x, y).

	on_sweep: detachable PROCEDURE [REAL_64, REAL_64]
			-- Drag at canvas-relative (x, y).

	menu_provider: detachable FUNCTION [REAL_64, REAL_64, detachable SW_MENU]
			-- Builds the right-click menu for canvas-relative (x, y).

	on_key: detachable PROCEDURE [INTEGER, BOOLEAN]
			-- Virtual key (vk, shift) while this canvas holds focus.
			-- Setting it (or on_char) makes the canvas focusable.

	on_char: detachable PROCEDURE [INTEGER]
			-- Character code while this canvas holds focus.

	on_release: detachable PROCEDURE [INTEGER, INTEGER]
			-- The pointer let go while this canvas held the capture
			-- (window coordinates) - press-and-hold interactions.

	on_files: detachable PROCEDURE [ARRAYED_LIST [STRING_32]]
			-- Files dropped from the shell onto this canvas.
			-- Setting it makes the canvas a drop target.

	on_hover: detachable PROCEDURE [REAL_64, REAL_64]
			-- The resting pointer at canvas-relative (x, y) - hosts
			-- with zoned surfaces retarget their tooltip here.

feature -- Element change

	set_on_paint (a_agent: PROCEDURE [SW_PAINTER, REAL_64, REAL_64, REAL_64, REAL_64])
		do
			on_paint := a_agent
		ensure
			set: on_paint = a_agent
		end

	set_on_press (a_agent: PROCEDURE [REAL_64, REAL_64])
		do
			on_press := a_agent
		ensure
			set: on_press = a_agent
		end

	set_on_sweep (a_agent: PROCEDURE [REAL_64, REAL_64])
		do
			on_sweep := a_agent
		ensure
			set: on_sweep = a_agent
		end

	set_menu_provider (a_agent: FUNCTION [REAL_64, REAL_64, detachable SW_MENU])
		do
			menu_provider := a_agent
		ensure
			set: menu_provider = a_agent
		end

	set_on_key (a_agent: PROCEDURE [INTEGER, BOOLEAN])
		do
			on_key := a_agent
		ensure
			set: on_key = a_agent
		end

	set_on_char (a_agent: PROCEDURE [INTEGER])
		do
			on_char := a_agent
		ensure
			set: on_char = a_agent
		end

	set_on_release (a_agent: PROCEDURE [INTEGER, INTEGER])
		do
			on_release := a_agent
		ensure
			set: on_release = a_agent
		end

	set_on_files (a_agent: PROCEDURE [ARRAYED_LIST [STRING_32]])
		do
			on_files := a_agent
		ensure
			set: on_files = a_agent
		end

	set_on_hover (a_agent: PROCEDURE [REAL_64, REAL_64])
		do
			on_hover := a_agent
		ensure
			set: on_hover = a_agent
		end

	set_hover_point (a_px, a_py: REAL_64)
		do
			Precursor (a_px, a_py)
			if attached on_hover as al_h then
				al_h.call (a_px - x, a_py - y)
			end
			tell_pointer (Pointer_motion, a_px - x, a_py - y, 0)
		end

feature -- Presented image (W7)

	image: detachable CAIRO_SURFACE
			-- A finished picture the host presented: drawn at the canvas's top-left, 1:1 in
			-- device pixels, under whatever `on_paint' draws.

	image_scale: REAL_64
			-- Device pixels per canvas unit in `image' (1 until an image is presented).

	device_scale: REAL_64
			-- Device pixels per canvas unit on the monitor the window was last laid out on
			-- (the theme's scale): what a host multiplies by to draw a sharp `image'.

	present_image (a_image: CAIRO_SURFACE; a_scale: REAL_64)
			-- Show `a_image', `a_scale' device pixels per canvas unit, from the next frame on.
			-- The canvas keeps the object until the next one; the host must not destroy it
			-- meanwhile (simple_gui's Windows backend holds its own cairo reference).
		require
			valid: a_image.is_valid
			sized: a_image.width > 0 and a_image.height > 0
			positive_scale: a_scale > 0.0
		do
			image := a_image
			image_scale := a_scale
		ensure
			kept: image = a_image and image_scale = a_scale
		end

feature -- Pointer and size (W7)

	on_pointer: detachable PROCEDURE [INTEGER, REAL_64, REAL_64, INTEGER, INTEGER]
			-- (kind, x, y, button, modifiers), x and y canvas-relative: simple_gui's pointer
			-- event. Kind `Pointer_press', `Pointer_release' or `Pointer_motion'; button 1 (the
			-- primary button, the only one a canvas hears, as on GTK) or 0 in motion; modifiers
			-- a sum of `Modifier_shift', `Modifier_control' and `Modifier_alt'.

	on_resize: detachable PROCEDURE [REAL_64, REAL_64]
			-- The canvas's new width and height, whenever layout changes them.

	Pointer_press: INTEGER = 1
	Pointer_release: INTEGER = 2
	Pointer_motion: INTEGER = 3

	Modifier_shift: INTEGER = 1
	Modifier_control: INTEGER = 2
	Modifier_alt: INTEGER = 4

	set_on_pointer (a_agent: PROCEDURE [INTEGER, REAL_64, REAL_64, INTEGER, INTEGER])
		do
			on_pointer := a_agent
		ensure
			set: on_pointer = a_agent
		end

	set_on_resize (a_agent: PROCEDURE [REAL_64, REAL_64])
		do
			on_resize := a_agent
		ensure
			set: on_resize = a_agent
		end

	modifiers: INTEGER
			-- The modifier keys held now, as `on_pointer' reports them.
		local
			l_keys: SW_KEYS
		do
			create l_keys
			if l_keys.shift_down then
				Result := Result + Modifier_shift
			end
			if l_keys.control_down then
				Result := Result + Modifier_control
			end
			if l_keys.alt_down then
				Result := Result + Modifier_alt
			end
		ensure
			in_range: Result >= 0 and Result <= 7
		end

	set_bounds (a_x, a_y, a_w, a_h: REAL_64)
			-- Place the canvas; tell `on_resize' when its size changed (not when it moved,
			-- and not when it vanished).
		local
			l_changed: BOOLEAN
		do
			l_changed := a_w /= width or a_h /= height
			Precursor (a_x, a_y, a_w, a_h)
			if l_changed and a_w > 0.0 and a_h > 0.0 and then attached on_resize as al_r then
				al_r.call (a_w, a_h)
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Learn the device scale from the theme.
		do
			device_scale := a_p.theme.text_scale
		end

feature -- Input

	accepts_focus: BOOLEAN
			-- Focusable exactly when the host listens for keys.
		do
			Result := on_key /= Void or on_char /= Void
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			if attached on_key as al_h then
				al_h.call (a_vk, a_shift)
			end
		end

	handle_char (a_code: INTEGER)
		do
			if attached on_char as al_h then
				al_h.call (a_code)
			end
		end

	handle_release (a_x, a_y: INTEGER)
		do
			if attached on_release as al_h then
				al_h.call (a_x, a_y)
			end
			tell_pointer (Pointer_release, a_x - x, a_y - y, 1)
		end

	accepts_files: BOOLEAN
			-- A drop target exactly when the host listens for drops.
		do
			Result := on_files /= Void
		end

	receive_files (a_paths: ARRAYED_LIST [STRING_32]; a_px, a_py: REAL_64)
		do
			if attached on_files as al_h then
				al_h.call (a_paths)
			end
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := canvas_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			a_p.push_clip (x, y, width, height)
			if attached image as al_img and then al_img.is_valid and then al_img.width > 0 and then al_img.height > 0 then
				a_p.draw_image (al_img, x, y, al_img.width / image_scale, al_img.height / image_scale)
			end
			if attached on_paint as pa then
				pa.call (a_p, x, y, width, height)
			end
			a_p.pop_clip
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if attached on_press as pr then
					pr.call (a_px - x, a_py - y)
				end
				tell_pointer (Pointer_press, a_px - x, a_py - y, 1)
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if attached on_sweep as sw then
				sw.call (a_px - x, a_py - y)
			end
			tell_pointer (Pointer_motion, a_px - x, a_py - y, 0)
		end

	tell_pointer (a_kind: INTEGER; a_x, a_y: REAL_64; a_button: INTEGER)
			-- Report one pointer event to `on_pointer', with the modifiers held now.
		do
			if attached on_pointer as al_p then
				al_p.call (a_kind, a_x, a_y, a_button, modifiers)
			end
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
		do
			if attached menu_provider as mp then
				Result := mp.item ([a_px - x, a_py - y])
			end
		end

invariant
	height_positive: canvas_height > 0.0
	image_scale_positive: image_scale > 0.0
	device_scale_positive: device_scale > 0.0

end
