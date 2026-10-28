note
	description: "[
		The toolkit's one way to put text on the system clipboard (design
		scan 55): a parentless mixin a widget inherits beside its other
		abilities, so a menu's Copy item, Ctrl+C and Cut all go through
		`copy_text' and SW_CLIPBOARD. Five widgets had grown a private
		copy of these four lines in 0.46.0, and four more wrote the
		clipboard inline before that.
	]"
	author: "Larry Rix"

deferred class
	SW_COPYING

feature -- Copying

	copy_text (a_text: READABLE_STRING_GENERAL)
			-- `a_text' onto the system clipboard.
		local
			l_clip: SW_CLIPBOARD
		do
			create l_clip
			l_clip.set_text (a_text)
		end

end
