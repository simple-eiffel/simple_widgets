note
	description: "[
		Push-to-talk into any text box - Larry's standing 'Do it',
		done with the ecosystem's own organs: simple_audio records
		the microphone, simple_speech (whisper.cpp under the
		ecosystem wrapper) transcribes, and the words land wherever
		the host points them. A SERVICE, not a widget - it lives in
		the speechkit cluster, added only by targets that want the
		dependency (the library core stays lean, the devkit lesson
		applied to packaging). HONEST ABSENCE: a missing model file
		leaves is_ready False with every state queryable - hosts
		grey their mic buttons through set_enabled_when instead of
		crashing. transcribe_wav is the file-shaped half (assaulted
		against a real sample); the microphone half is
		start_listening / stop_and_deliver.
	]"

class
	SW_DICTATION

create
	make

feature {NONE} -- Initialization

	make (a_model_path: READABLE_STRING_GENERAL)
			-- Load whisper's model when the file exists; stay
			-- honestly unready when it does not.
		local
			probe: PLAIN_TEXT_FILE
		do
			create model_path.make_from_string_general (a_model_path)
			create last_transcript.make_empty
			create recorder.make
			create probe.make_with_name (a_model_path)
			if probe.exists then
				create speech.make (a_model_path)
			end
		ensure
			path_kept: model_path.same_string_general (a_model_path)
		end

feature -- Access

	model_path: STRING_32

	is_ready: BOOLEAN
			-- Model loaded and the engine standing?
		do
			Result := attached speech as s and then s.is_valid
		end

	is_listening: BOOLEAN

	last_transcript: STRING_32
			-- What the most recent delivery said.

	Temp_wav: STRING = "sw_dictation_tmp.wav"

feature -- Commands

	start_listening
			-- Open the microphone; the buffer accumulates.
		require
			ready: is_ready
			idle: not is_listening
		do
			recorder.start
			is_listening := True
		ensure
			listening: is_listening
		end

	stop_and_deliver: STRING_32
			-- Close the microphone, transcribe what it heard, keep
			-- and return the words (empty when nothing was said or
			-- nothing survived the engine).
		require
			listening: is_listening
		do
			recorder.stop
			is_listening := False
			create Result.make_empty
			if attached recorder.buffer as buf
				and then buf.save_to_wav (Temp_wav)
			then
				Result := transcribe_wav (Temp_wav)
			end
			last_transcript := Result.twin
		ensure
			delivered: not is_listening
			kept: last_transcript.same_string (Result)
		end

	transcribe_wav (a_path: READABLE_STRING_GENERAL): STRING_32
			-- The file-shaped half: whisper over any wav on disk,
			-- segments joined with single spaces.
		require
			ready: is_ready
		do
			create Result.make (64)
			if attached speech as s then
				across
					s.transcribe_file (a_path) as seg
				loop
					if not Result.is_empty then
						Result.append_character (' ')
					end
					Result.append (seg.text)
				end
			end
		end

feature {NONE} -- Organs

	speech: detachable SIMPLE_SPEECH

	recorder: AUDIO_RECORDER

invariant
	organs: model_path /= Void and last_transcript /= Void and recorder /= Void
	listening_needs_readiness: is_listening implies is_ready

end
