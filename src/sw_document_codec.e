note
	description: "[
		How SW_DOCUMENT_VIEW's live preview turns one block into the
		source the reader edits, and the edited source back into blocks
		(GW-13). The view knows no markup; a codec does.
		SW_MARKDOWN_CODEC is the one the toolkit ships.
	]"
	author: "Larry Rix"

deferred class
	SW_DOCUMENT_CODEC

feature -- Conversion

	block_source (a_document: SIMPLE_DOCUMENT; a_i: INTEGER): STRING_32
			-- Block `a_i' of `a_document' as source text.
		require
			in_range: a_i >= 1 and a_i <= a_document.count
		deferred
		end

	blocks_from (a_source: READABLE_STRING_GENERAL): LIST [DOC_BLOCK]
			-- `a_source' read back as blocks: one, several (the reader
			-- typed a blank line), or none (the reader emptied it).
		deferred
		end

end
