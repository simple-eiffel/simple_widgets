note
	description: "[
		Windows' inbox spell checker (ISpellChecker, Windows 8+) as a
		SURFACE-layer service - the zero-model, zero-license AI-assist.
		The COM machinery lives in simple_shell (SHELL_SPELLER); this
		facade keeps the toolkit vocabulary. Absent language support
		degrades to no findings, never to failure. WINDOWS-ONLY by the
		toolkit's charter; any port must treat this seam as a seam.
	]"

class
	SW_SPELLER

inherit
	SHELL_SPELLER

end
