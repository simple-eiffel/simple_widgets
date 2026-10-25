note
	description: "[
		Markdown as SW_DOCUMENT_VIEW's live-preview source (GW-13): a
		block shows as the Markdown simple_markdown writes for it
		(MD_DOCUMENT_WRITER.write_block) and the edited Markdown is read
		back (MD_DOCUMENT_READER) - the round trip the two are tested to
		keep. The note store's format, so what the reader types is what
		is saved.
	]"
	author: "Larry Rix"

class
	SW_MARKDOWN_CODEC

inherit
	SW_DOCUMENT_CODEC

create
	make

feature {NONE} -- Initialization

	make
		do
			create reader.make
			create writer.make
		end

feature -- Conversion

	block_source (a_document: SIMPLE_DOCUMENT; a_i: INTEGER): STRING_32
		do
			Result := writer.write_block (a_document, a_i)
		end

	blocks_from (a_source: READABLE_STRING_GENERAL): LIST [DOC_BLOCK]
		local
			d: SIMPLE_DOCUMENT
			l_list: ARRAYED_LIST [DOC_BLOCK]
			i: INTEGER
		do
			d := reader.read (a_source)
			create l_list.make (d.count)
			from
				i := 1
			until
				i > d.count
			loop
				l_list.extend (d.block (i))
				i := i + 1
			end
			Result := l_list
		end

feature {NONE} -- Implementation

	reader: MD_DOCUMENT_READER
	writer: MD_DOCUMENT_WRITER

end
