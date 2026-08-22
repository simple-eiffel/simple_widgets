note
	description: "[
		A time field with culture: 24-hour locales read and write
		HH:MM; 12-hour locales read and write H:MM AM/PM (both
		accept either on input - generous in, exact out).
		Ill-formed times wear the invalid tint.
	]"

class
	SW_TIME_PICKER

inherit
	SW_TEXT_BOX
		redefine
			draw, changed
		end

create
	make_picker

feature {NONE} -- Initialization

	make_picker
		do
			make_single_line ("")
			set_spellcheck (False)
			create shown_locale_probe.make_us
		end

feature -- Access

	hour: INTEGER
	minute: INTEGER

	has_time: BOOLEAN

	on_time_change: detachable PROCEDURE [INTEGER, INTEGER]

	locale_override: detachable SW_LOCALE

feature -- Element change

	set_on_time_change (a_action: PROCEDURE [INTEGER, INTEGER])
		do
			on_time_change := a_action
		ensure
			set: on_time_change = a_action
		end

	set_picker_locale (a_locale: SW_LOCALE)
		do
			locale_override := a_locale
		ensure
			set: locale_override = a_locale
		end

	with_picker_locale (a_locale: SW_LOCALE): like Current
		do
			locale_override := a_locale
			Result := Current
		ensure
			chained: Result = Current
		end

	set_time (a_hour, a_minute: INTEGER)
		require
			sane: a_hour >= 0 and a_hour <= 23 and a_minute >= 0 and a_minute <= 59
		do
			hour := a_hour
			minute := a_minute
			has_time := True
			set_text (effective_locale_now.format_time (a_hour, a_minute))
			set_invalid (False)
		ensure
			timed: has_time
		end

feature -- Culture

	effective_locale_now: SW_LOCALE
		do
			if attached locale_override as lo then
				Result := lo
			else
				Result := shown_locale_probe
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			if locale_override = Void then
				shown_locale_probe := a_p.theme.locale
			end
			Precursor (a_p)
		end

feature {NONE} -- Engine

	shown_locale_probe: SW_LOCALE
		attribute
			create Result.make_us
		end

	changed
		local
			loc: SW_LOCALE
		do
			Precursor
			loc := effective_locale_now
			if text.is_empty then
				set_invalid (False)
				has_time := False
			elseif attached loc.parsed_time (text) as tm then
				hour := tm.hour
				minute := tm.minute
				has_time := True
				set_invalid (False)
				if attached on_time_change as tc then
					tc.call (hour, minute)
				end
			else
				has_time := False
				set_invalid (True)
			end
		end

invariant
	time_sane: hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59

end
