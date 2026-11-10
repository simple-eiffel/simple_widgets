note
	description: "[
		One cell of an SW_GRID_VIEW: a title, an optional subtitle, an icon name and a picture
		path, and the picture once it is decoded.
	]"

class
	SW_GRID_CELL

create
	make

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_GENERAL)
		do
			create title.make_from_string_general (a_title)
			create subtitle.make_empty
			create icon.make_empty
			create path.make_empty
		ensure
			titled: title.same_string_general (a_title)
			no_picture: not is_picture_wanted
		end

feature -- Access

	title: STRING_32

	subtitle: STRING_32

	icon: STRING_32
			-- An icon name; empty for none.

	path: STRING_32
			-- The picture file; empty for none.

	picture: detachable CAIRO_SURFACE
			-- The decoded picture; Void until it is ready (or when the file would not decode).

	is_picture_wanted: BOOLEAN
			-- Has this cell a picture file?
		do
			Result := not path.is_empty
		end

	is_picture_pending: BOOLEAN
			-- Is the picture file still to be decoded?
		do
			Result := is_picture_wanted and not is_decoded
		end

	is_picture_ready: BOOLEAN
			-- Is the picture decoded and drawable?
		do
			Result := attached picture
		end

	is_decoded: BOOLEAN
			-- Has decoding been tried (whether or not it gave a picture)?

feature -- Element change

	set_title (a_text: READABLE_STRING_GENERAL)
		do
			create title.make_from_string_general (a_text)
		end

	set_subtitle (a_text: READABLE_STRING_GENERAL)
		do
			create subtitle.make_from_string_general (a_text)
		ensure
			set: subtitle.same_string_general (a_text)
		end

	set_icon (a_name: READABLE_STRING_GENERAL)
		do
			create icon.make_from_string_general (a_name)
		ensure
			set: icon.same_string_general (a_name)
		end

	set_path (a_path: READABLE_STRING_GENERAL)
			-- Name the picture file; it is decoded later, not now.
		do
			create path.make_from_string_general (a_path)
			picture := Void
			is_decoded := False
		ensure
			set: path.same_string_general (a_path)
			pending: is_picture_wanted implies is_picture_pending
		end

	decode
			-- Decode the picture file; a file that is missing or will not decode leaves no picture.
		require
			wanted: is_picture_wanted
		local
			l_surface: CAIRO_SURFACE
		do
			create l_surface.make_from_png (path)
			if l_surface.is_valid and then l_surface.width > 0 and then l_surface.height > 0 then
				picture := l_surface
			else
				picture := Void
			end
			is_decoded := True
		ensure
			tried: is_decoded
			ready_means_drawable: attached picture as al_picture implies al_picture.width > 0
		end

end
