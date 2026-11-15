note
	description: "[
		Where the tests write their evidence images (rendered frames for a person to look at).
		By default a folder of its own under the system's temporary folder, so a test run leaves
		the repository as it is (simple_widgets #90: a run rewrote some 60 committed PNGs). With
		SW_UPDATE_EVIDENCE set, the repository's evidence/ folder, to refresh the committed
		images on purpose.
	]"

class
	SW_TEST_EVIDENCE

feature -- Access

	path (a_name: STRING): STRING_32
			-- `<repo>/evidence/<a_name>', where `<repo>' is the first
			-- ancestor of the working directory or of the exe's own folder
			-- that holds `simple_widgets.ecf'. Empty when the repository is
			-- not underfoot, which simply means no evidence file is written.
		require
			name_not_empty: not a_name.is_empty
		local
			env: EXECUTION_ENVIRONMENT
			starts: ARRAYED_LIST [PATH]
			base, marker, dir: PATH
			d: DIRECTORY
			i, step: INTEGER
			found: BOOLEAN
		do
			create Result.make_empty
			create env
			if not attached env.item ("SW_UPDATE_EVIDENCE") then
					-- port-coordination #17 and simple_widgets #90: a test run leaves the repository as
					-- it is; its evidence goes to a folder of its own under the temporary folder
				found := True
				dir := (create {PATH}.make_from_string (temporary_folder)).extended ("simple_widgets_evidence")
				if not directory_exists (dir.name) then
					create d.make_with_path (dir)
					d.recursive_create_dir
				end
				if directory_exists (dir.name) then
					Result := dir.extended (a_name).name.to_string_32
				end
			end
			create starts.make (2)
			starts.extend (env.current_working_path)
			starts.extend ((create {PATH}.make_from_string (env.arguments.command_name)).parent)
			from i := 1 until i > starts.count or found loop
				base := starts [i]
				from step := 0 until step > 6 or found loop
					marker := base.extended ("simple_widgets.ecf")
					if file_exists (marker.name) then
						dir := base.extended ("evidence")
						if not directory_exists (dir.name) then
							create d.make_with_path (dir)
							d.recursive_create_dir
						end
						if directory_exists (dir.name) then
							Result := dir.extended (a_name).name.to_string_32
						end
						found := True
					else
						base := base.parent
					end
					step := step + 1
				end
				i := i + 1
			end
		end

	temporary_folder: STRING_32
			-- TMPDIR, else TEMP, else /tmp.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("TMPDIR") as al_t and then not al_t.is_empty then
				Result := al_t.to_string_32
			elseif attached env.item ("TEMP") as al_t and then not al_t.is_empty then
				Result := al_t.to_string_32
			else
				Result := {STRING_32} "/tmp"
			end
		end

feature {NONE} -- Implementation

	file_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			f: RAW_FILE
		do
			create f.make_with_name (a_path)
			Result := f.exists
		end

	directory_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			d: DIRECTORY
		do
			create d.make_with_name (a_path)
			Result := d.exists
		end

end
