note
	description: "[
		The fixed-pitch faces that stand behind a theme's mono face
		(0.57.0), for the two classes that turn the mono role into a
		face: SW_PAINTER on Cairo's own text path, SW_SHAPING on the
		shaped path.

		Why they exist: every platform silently puts a proportional face
		in place of a family it lacks, so on a machine without the theme's
		mono face (IBM Plex Mono by default) the mono role drew
		proportional text. Code, columns of figures and tab stops all
		count on one advance for every character.
	]"
	author: "Larry Rix"

class
	SW_FIXED_PITCH_FACES

feature -- Faces

	mono_anchors: ARRAY [STRING_32]
			-- Fixed-pitch faces that stand behind the theme's mono face, in order. Every
			-- Windows has both; off Windows simple_shaping maps both to the system's
			-- monospace font, so the shaped path needs no others.
		once
			Result := <<{STRING_32} "Consolas", {STRING_32} "Courier New">>
		ensure
			not_empty: not Result.is_empty
		end

	mono_system_faces: ARRAY [STRING_32]
			-- Fixed-pitch faces Cairo's own text path can ask macOS and Linux for by name,
			-- tried after `mono_anchors' where neither of those is installed.
		once
			Result := <<{STRING_32} "Menlo", {STRING_32} "DejaVu Sans Mono", {STRING_32} "monospace">>
		ensure
			not_empty: not Result.is_empty
		end

end
