note
	description: "[
		Tasks as bars on a day axis: each row a task with a start
		day and a duration, the x axis run through SW_SCALE's
		ladder, dependencies drawn as elbow connectors from a
		task's end to its successor's start, and a TODAY line when
		told where today stands. The geometry (bar_x, bar_w via the
		scale; row_y) is public and assaulted; add_dependency
		refuses unknown tasks and self-loops by contract.
	]"

class
	SW_GANTT

inherit
	SW_CHART
		redefine
			draw
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create tasks.make (8)
			create dependencies.make (8)
			today_day := -1
		end

feature -- Access

	tasks: ARRAYED_LIST [TUPLE [label: STRING_32; start_day, duration: INTEGER]]

	dependencies: ARRAYED_LIST [TUPLE [before, after: INTEGER]]

	today_day: INTEGER
			-- Where the today line stands; -1 = no line.

	horizon: INTEGER
			-- The last day any task touches; at least 1.
		local
			i: INTEGER
		do
			Result := 1
			from
				i := 1
			until
				i > tasks.count
			loop
				Result := Result.max (tasks.i_th (i).start_day + tasks.i_th (i).duration)
				i := i + 1
			end
		ensure
			positive: Result >= 1
		end

	Row_h: REAL_64 = 28.0

	row_y (a_task: INTEGER): REAL_64
		require
			known: a_task >= 1 and a_task <= tasks.count
		do
			Result := plot_y + (a_task - 1) * Row_h
		end

	bar_x (a_task: INTEGER): REAL_64
		require
			known: a_task >= 1 and a_task <= tasks.count
		do
			Result := x_scale.position (tasks.i_th (a_task).start_day.to_double)
		end

	bar_w (a_task: INTEGER): REAL_64
		require
			known: a_task >= 1 and a_task <= tasks.count
		do
			Result := x_scale.position ((tasks.i_th (a_task).start_day
				+ tasks.i_th (a_task).duration).to_double) - bar_x (a_task)
		ensure
			positive: Result > 0.0
		end

feature -- Element change

	add_task (a_label: READABLE_STRING_GENERAL; a_start_day, a_duration: INTEGER): INTEGER
		require
			sane_start: a_start_day >= 0
			some_length: a_duration >= 1
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			tasks.extend ([l, a_start_day, a_duration])
			Result := tasks.count
		ensure
			grew: tasks.count = old tasks.count + 1
		end

	add_dependency (a_before, a_after: INTEGER)
		require
			before_known: a_before >= 1 and a_before <= tasks.count
			after_known: a_after >= 1 and a_after <= tasks.count
			no_self_loop: a_before /= a_after
		do
			dependencies.extend ([a_before, a_after])
		ensure
			grew: dependencies.count = old dependencies.count + 1
		end

	set_today (a_day: INTEGER)
		require
			sane: a_day >= 0
		do
			today_day := a_day
		ensure
			set: today_day = a_day
		end

feature -- Data

	refresh_domains
		do
			x_scale.set_domain (0.0, horizon.to_double)
			x_scale.nice_domain (6)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			bx, bw, ry, ex, sy2: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			refresh_domains
			x_scale.set_range (plot_x, plot_x + plot_w)
			a_p.font ({SW_PAINTER}.Role_mono, 10.0, False)
			across
				x_scale.ticks (6) as v
			loop
				a_p.set_color (t.outline)
				a_p.vline (x_scale.position (v), plot_y, plot_h)
				a_p.set_color (t.ink_muted)
				a_p.text (x_scale.position (v) - 4.0, y + height - 9.0, label_of (v))
			end
			from
				i := 1
			until
				i > tasks.count
			loop
				ry := row_y (i)
				if i \\ 2 = 0 then
					a_p.set_color_alpha (t.surface_variant, 0.5)
					a_p.fill_rect (plot_x, ry, plot_w, Row_h)
				end
				bx := bar_x (i)
				bw := bar_w (i)
				a_p.set_color (t.accent)
				a_p.rrect_fill (bx, ry + 6.0, bw, Row_h - 12.0, 3.0)
				a_p.font ({SW_PAINTER}.Role_ui, 11.5, False)
				a_p.set_color (t.ink)
				a_p.text ((bx + 6.0).min (x + width - 60.0), ry + Row_h - 10.0,
					tasks.i_th (i).label)
				i := i + 1
			end
				-- elbow connectors: end of before, into start of after
			a_p.set_color (t.ink_muted)
			across
				dependencies as dep
			loop
				ex := bar_x (dep.before) + bar_w (dep.before)
				ry := row_y (dep.before) + Row_h / 2.0
				sy2 := row_y (dep.after) + Row_h / 2.0
				a_p.line (ex, ry, ex + 6.0, ry, 1.2)
				a_p.line (ex + 6.0, ry, ex + 6.0, sy2, 1.2)
				a_p.line (ex + 6.0, sy2, bar_x (dep.after), sy2, 1.2)
			end
			if today_day >= 0 then
				a_p.set_color (t.danger)
				a_p.vline (x_scale.position (today_day.to_double), plot_y, plot_h)
			end
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature {NONE} -- Chassis contract

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	organs: tasks /= Void and dependencies /= Void
	deps_bounded: across dependencies as d all
		d.before >= 1 and d.before <= tasks.count
		and d.after >= 1 and d.after <= tasks.count end

end
