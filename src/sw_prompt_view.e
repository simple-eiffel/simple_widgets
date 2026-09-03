note
	description: "[
		Wave 6 conversational: the AI prompt view - a chat thread
		above, a prompt box and Send below. Submitting posts the
		text as a MINE bubble, clears the box, and fires on_submit
		with the prompt; the answering side streams through
		begin_reply / append_token / end_reply, growing one THEIRS
		bubble token by token (the thread's append_to_last doing
		the work). The whole engine side is the host's - this is
		the face. Submit and streaming are assaulted headless.
	]"

class
	SW_PROMPT_VIEW

inherit
	SW_COLUMN
		rename
			make as make_column
		redefine
			default_gap
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_column
			create thread.make
			create prompt_box.make_single_line ("")
			create send_button.make ("Send", Void)
			put (thread.growing)
			build_input_row
			send_button.set_on_click (agent submit_now)
		end


feature -- Spacing (theme defaults; an explicit value still wins)

	default_gap (a_p: SW_PAINTER): REAL_64
			-- 6 px at 1x, as before, now scaled with the text.
		do
			Result := a_p.theme.padding * 0.75
		end

feature -- Access

	thread: SW_CHAT_THREAD

	prompt_box: SW_TEXT_BOX

	on_submit: detachable PROCEDURE [STRING_32]

	is_replying: BOOLEAN
			-- Between begin_reply and end_reply?

feature -- Element change

	set_on_submit (a_action: PROCEDURE [STRING_32])
		do
			on_submit := a_action
		ensure
			set: on_submit = a_action
		end

	submit_now
			-- Post the box as a mine-bubble, clear it, tell the host.
		local
			s: STRING_32
		do
			s := prompt_box.text.twin
			if not s.is_empty then
				thread.add_message (thread.Role_mine, s)
				prompt_box.set_text ("")
				if attached on_submit as a then
					a.call (s)
				end
			end
		ensure
			cleared: prompt_box.text.is_empty or old prompt_box.text.is_empty
		end

	begin_reply
			-- Open the streaming bubble.
		do
			thread.add_message (thread.Role_theirs, "")
			is_replying := True
		ensure
			replying: is_replying
		end

	append_token (a_text: READABLE_STRING_GENERAL)
		require
			replying: is_replying
		do
			thread.append_to_last (a_text)
		end

	end_reply
		do
			is_replying := False
		ensure
			done: not is_replying
		end

	say_system (a_text: READABLE_STRING_GENERAL)
		do
			thread.add_message (thread.Role_system, a_text)
		end

feature {NONE} -- Organs

	send_button: SW_BUTTON

	build_input_row
		local
			row: SW_ROW
		do
			create row.make
			row := row.with_gap (6.0)
			row.put (prompt_box.growing)
			row.put (send_button)
			put (row)
		end

invariant
	organs: thread /= Void and prompt_box /= Void and send_button /= Void

end
