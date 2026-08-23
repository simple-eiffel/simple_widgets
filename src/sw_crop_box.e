note
	description: "[
		Wave 6 image tools: the crop marquee - an SW_IMAGE under a
		drag rectangle, the selection reported as NORMALIZED
		fractions of the widget's face (0..1 each way), on_crop
		firing when the mouse lets go. The normalization math
		(crop_rect from raw drag corners, any drag direction) is
		public and assaulted; mapping through the image's own
		letterboxing is the stated next step.
	]"

class
	SW_CROP_BOX

inherit
	SW_WIDGET
		redefine
			handle_click, handle_drag
		end

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
		do
			create image.make_from_file (a_path)
		end

feature -- Access

	image: SW_IMAGE

	drag_x0, drag_y0, drag_x1, drag_y1: REAL_64
			-- Raw marquee corners in surface space; any direction.

	has_selection: BOOLEAN

	on_crop: detachable PROCEDURE [REAL_64, REAL_64, REAL_64, REAL_64]
			-- Fired with (fx, fy, fw, fh), each 0..1 of the face.

	crop_rect: TUPLE [fx, fy, fw, fh: REAL_64]
			-- The marquee normalized to the face, corners sorted,
			-- clamped inside; zero-extent when nothing selected.
		local
			lx0, ly0, lx1, ly1: REAL_64
		do
			if has_selection and then width > 0.0 and then height > 0.0 then
				lx0 := ((drag_x0.min (drag_x1) - x) / width).max (0.0).min (1.0)
				ly0 := ((drag_y0.min (drag_y1) - y) / height).max (0.0).min (1.0)
				lx1 := ((drag_x0.max (drag_x1) - x) / width).max (0.0).min (1.0)
				ly1 := ((drag_y0.max (drag_y1) - y) / height).max (0.0).min (1.0)
				Result := [lx0, ly0, lx1 - lx0, ly1 - ly0]
			else
				Result := [0.0, 0.0, 0.0, 0.0]
			end
		ensure
			unit_box: Result.fx >= 0.0 and Result.fy >= 0.0
				and Result.fx + Result.fw <= 1.000_001
				and Result.fy + Result.fh <= 1.000_001
		end

feature -- Element change

	set_on_crop (a_action: PROCEDURE [REAL_64, REAL_64, REAL_64, REAL_64])
		do
			on_crop := a_action
		ensure
			set: on_crop = a_action
		end

	clear_selection
		do
			has_selection := False
		ensure
			bare: not has_selection
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 220.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			r: TUPLE [fx, fy, fw, fh: REAL_64]
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			image.set_bounds (x + 2.0, y + 2.0, (width - 4.0).max (2.0), (height - 4.0).max (2.0))
			image.draw (a_p)
			if has_selection then
				r := crop_rect
				a_p.set_color_alpha (t.accent, 0.18)
				a_p.fill_rect (x + r.fx * width, y + r.fy * height,
					(r.fw * width).max (1.0), (r.fh * height).max (1.0))
				a_p.set_color (t.accent)
				a_p.rrect_stroke (x + r.fx * width + 0.5, y + r.fy * height + 0.5,
					(r.fw * width).max (1.0), (r.fh * height).max (1.0), 1.0)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				drag_x0 := a_px
				drag_y0 := a_py
				drag_x1 := a_px
				drag_y1 := a_py
				has_selection := True
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		local
			r: TUPLE [fx, fy, fw, fh: REAL_64]
		do
			drag_x1 := a_px
			drag_y1 := a_py
			r := crop_rect
			if r.fw > 0.0 and then r.fh > 0.0 and then attached on_crop as a then
				a.call (r.fx, r.fy, r.fw, r.fh)
			end
		end

invariant
	image_attached: image /= Void

end
