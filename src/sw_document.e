note
	description: "[
		A rich document as a widget sees it (GW-13): an ordered list of
		SW_DOC_BLOCKs - paragraphs, headings, list items, quotes, rules
		and tables - each holding SW_RICH_TEXT with inline bold, italic,
		small capitals, superscript and links. SW_DOCUMENT_VIEW shows
		one; commentaries, lexicon entries, dictionary articles and
		notes are all built as one.

		The model knows no markup. A host that reads Markdown or a
		commentary's HTML builds the blocks with the add_* features; each
		returns the new block's text so its spans can be added at once:

		    doc.add_paragraph ("For God so loved").add_link (1, 16, "John 3:16")

		`plain_text' is what Copy puts on the clipboard.
	]"
	author: "Larry Rix"

class
	SW_DOCUMENT

create
	make

feature {NONE} -- Initialization

	make
			-- No blocks.
		do
			create blocks.make (16)
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
			-- Blocks.
		do
			Result := blocks.count
		end

	block (a_i: INTEGER): SW_DOC_BLOCK
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := blocks.i_th (a_i)
		end

	revision: INTEGER
			-- Grows when blocks are added or removed (a block's own text
			-- changes show in SW_DOC_BLOCK.revision).

	number_of (a_i: INTEGER): INTEGER
			-- The number numbered item `a_i' shows: one more than the item
			-- above it at its depth, counting from 1 after anything that is
			-- not a list item or deeper. 0 for a block that is not a
			-- numbered item.
		require
			in_range: a_i >= 1 and a_i <= count
		local
			j: INTEGER
			l_done: BOOLEAN
		do
			if blocks.i_th (a_i).kind = {SW_DOC_BLOCK}.Kind_numbered then
				Result := 1
				from
					j := a_i - 1
				until
					j < 1 or l_done
				loop
					if not blocks.i_th (j).is_list_item or else blocks.i_th (j).level < blocks.i_th (a_i).level then
						l_done := True
					elseif blocks.i_th (j).level = blocks.i_th (a_i).level then
						if blocks.i_th (j).kind = {SW_DOC_BLOCK}.Kind_numbered then
							Result := Result + 1
						else
							l_done := True
						end
					end
					j := j - 1
				end
			end
		ensure
			numbered_only: (Result > 0) = (block (a_i).kind = {SW_DOC_BLOCK}.Kind_numbered)
		end

	plain_text: STRING_32
			-- Every block as a line of plain text: items with their bullet
			-- or number, a table's cells joined by tabs, a rule as an empty
			-- line.
		local
			i: INTEGER
		do
			create Result.make (256)
			from
				i := 1
			until
				i > count
			loop
				if i > 1 then
					Result.append_character ('%N')
				end
				Result.append (block_text (i))
				i := i + 1
			end
		end

	block_text (a_i: INTEGER): STRING_32
			-- Block `a_i' as plain text (see `plain_text').
		require
			in_range: a_i >= 1 and a_i <= count
		local
			b: SW_DOC_BLOCK
			r, c: INTEGER
		do
			b := blocks.i_th (a_i)
			create Result.make (b.content.count + 4)
			inspect b.kind
			when {SW_DOC_BLOCK}.Kind_bullet then
				Result.append_code (0x2022)
				Result.append_character (' ')
				Result.append (b.content.text)
			when {SW_DOC_BLOCK}.Kind_numbered then
				Result.append_integer (number_of (a_i))
				Result.append ({STRING_32} ". ")
				Result.append (b.content.text)
			when {SW_DOC_BLOCK}.Kind_rule then
			when {SW_DOC_BLOCK}.Kind_table then
				from
					r := 1
				until
					r > b.row_count
				loop
					if r > 1 then
						Result.append_character ('%N')
					end
					from
						c := 1
					until
						c > b.column_count
					loop
						if c > 1 then
							Result.append_character ('%T')
						end
						Result.append (b.cell (r, c).text)
						c := c + 1
					end
					r := r + 1
				end
			else
				Result.append (b.content.text)
			end
		end

feature -- Element change

	add_paragraph (a_text: READABLE_STRING_GENERAL): SW_RICH_TEXT
			-- A paragraph reading `a_text'; its text, for spans.
		do
			Result := add_text_block ({SW_DOC_BLOCK}.Kind_paragraph, 1, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_heading (a_level: INTEGER; a_text: READABLE_STRING_GENERAL): SW_RICH_TEXT
			-- A heading at `a_level' (1 the largest).
		require
			level_valid: a_level >= 1 and a_level <= {SW_DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({SW_DOC_BLOCK}.Kind_heading, a_level, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_bullet (a_depth: INTEGER; a_text: READABLE_STRING_GENERAL): SW_RICH_TEXT
			-- A bulleted item at `a_depth'.
		require
			depth_valid: a_depth >= 1 and a_depth <= {SW_DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({SW_DOC_BLOCK}.Kind_bullet, a_depth, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_numbered (a_depth: INTEGER; a_text: READABLE_STRING_GENERAL): SW_RICH_TEXT
			-- A numbered item at `a_depth'.
		require
			depth_valid: a_depth >= 1 and a_depth <= {SW_DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({SW_DOC_BLOCK}.Kind_numbered, a_depth, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_quote (a_depth: INTEGER; a_text: READABLE_STRING_GENERAL): SW_RICH_TEXT
			-- A block quote at `a_depth'.
		require
			depth_valid: a_depth >= 1 and a_depth <= {SW_DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({SW_DOC_BLOCK}.Kind_quote, a_depth, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_rule
			-- A horizontal rule.
		do
			blocks.extend (create {SW_DOC_BLOCK}.make ({SW_DOC_BLOCK}.Kind_rule, 1, {STRING_32} ""))
			revision := revision + 1
		ensure
			one_more: count = old count + 1
			rule: block (count).kind = {SW_DOC_BLOCK}.Kind_rule
		end

	add_table (a_header: ARRAY [READABLE_STRING_GENERAL]): SW_DOC_BLOCK
			-- A table headed `a_header'; the block, for its rows.
		require
			has_columns: a_header.count > 0
		do
			create Result.make_table (a_header)
			blocks.extend (Result)
			revision := revision + 1
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count)
		end

	remove (a_i: INTEGER)
			-- Block `a_i' goes; the ones after it move up.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			blocks.go_i_th (a_i)
			blocks.remove
			revision := revision + 1
		ensure
			one_fewer: count = old count - 1
		end

	wipe_out
		do
			blocks.wipe_out
			revision := revision + 1
		ensure
			empty: count = 0
		end

feature {NONE} -- Implementation

	blocks: ARRAYED_LIST [SW_DOC_BLOCK]

	add_text_block (a_kind, a_level: INTEGER; a_text: READABLE_STRING_GENERAL): SW_RICH_TEXT
		require
			text_kind: a_kind /= {SW_DOC_BLOCK}.Kind_rule and a_kind /= {SW_DOC_BLOCK}.Kind_table
			level_valid: a_level >= 1 and a_level <= {SW_DOC_BLOCK}.Max_level
		local
			b: SW_DOC_BLOCK
		do
			create b.make (a_kind, a_level, a_text)
			blocks.extend (b)
			revision := revision + 1
			Result := b.content
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

invariant
	blocks_attached: blocks /= Void
	revision_non_negative: revision >= 0

end
