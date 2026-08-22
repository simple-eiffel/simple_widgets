note
	description: "[
		The agent collection behind every on_[event] - ISE's
		ACTION_SEQUENCE architecture (base/ise/event, read from the
		25.02 source at Larry's direction), distilled: one ordered
		roll where kamikaze subscribers sit BESIDE permanents and
		fire in subscription order, pruned before their bodies run;
		an abort protocol so any action can stop the rest of its
		round (reentrancy tracked by a stack); and the state trio -
		Normal calls through, Paused buffers event data and resume
		replays the backlog, Blocked drops calls cold. Firing works
		a snapshot, so subscribing and pruning mid-round never
		corrupts the round. Vocabulary is double-salted: Vision2's
		call / extend / extend_kamikaze / prune beside our
		fire / subscribe / kamikaze / unsubscribe.
	]"

class
	SW_EVENT [ARGS -> TUPLE]

create
	make

feature {NONE} -- Initialization

	make
		do
			create roll.make (2)
			create call_buffer.make (0)
			create aborted.make (2)
			state := Normal_state
		ensure
			normal: state = Normal_state
		end

feature -- Access

	count: INTEGER
			-- Subscribers still on the roll, both kinds.
		do
			Result := roll.count
		end

	is_empty: BOOLEAN
		do
			Result := roll.is_empty
		end

	call_is_underway: BOOLEAN
			-- Is a round executing right now (possibly nested)?
		do
			Result := not aborted.is_empty
		end

feature -- States

	state: INTEGER
			-- One of Normal_state, Paused_state, Blocked_state.

	Normal_state: INTEGER = 1
	Paused_state: INTEGER = 2
	Blocked_state: INTEGER = 3

	block
			-- Ignore subsequent calls entirely.
		do
			state := Blocked_state
		ensure
			blocked: state = Blocked_state
		end

	pause
			-- Buffer subsequent calls; `resume' replays them.
		do
			state := Paused_state
		ensure
			paused: state = Paused_state
		end

	resume
			-- Back to normal, replaying any buffered calls in order.
		do
			state := Normal_state
			from
			until
				call_buffer.is_empty
			loop
				call (call_buffer.first)
				call_buffer.start
				call_buffer.remove
			end
		ensure
			normal: state = Normal_state
			drained: call_buffer.is_empty
		end

	flush
			-- Discard the buffered calls unreplayed.
		do
			call_buffer.wipe_out
		ensure
			discarded: call_buffer.is_empty
		end

feature -- Subscription

	subscribe, extend (a_action: PROCEDURE [ARGS])
			-- Fire `a_action' on every event from now on.
		do
			roll.extend ([a_action, False])
		ensure
			grew: count = old count + 1
		end

	subscribe_once, kamikaze, extend_kamikaze (a_action: PROCEDURE [ARGS])
			-- Fire `a_action' on the next event only - in subscription
			-- order beside the permanents, and off the roll before its
			-- body runs.
		do
			roll.extend ([a_action, True])
		ensure
			grew: count = old count + 1
		end

	unsubscribe, prune (a_action: PROCEDURE [ARGS])
			-- Forget every entry carrying `a_action' (identity: pass
			-- the same agent object you subscribed).
		local
			i: INTEGER
		do
			from
				i := roll.count
			until
				i < 1
			loop
				if roll.i_th (i).action = a_action then
					roll.go_i_th (i)
					roll.remove
				end
				i := i - 1
			end
		end

	wipe_out
		do
			roll.wipe_out
		ensure
			empty: is_empty
		end

feature -- Firing

	call, fire (a_args: ARGS)
			-- One round over a snapshot of the roll, in subscription
			-- order; kamikazes are pruned before they run; `abort'
			-- inside any action stops the remainder of THIS round.
			-- Paused: `a_args' is buffered. Blocked: dropped.
		local
			snapshot: ARRAYED_LIST [TUPLE [action: PROCEDURE [ARGS]; once_only: BOOLEAN]]
			i: INTEGER
		do
			inspect state
			when Normal_state then
				snapshot := roll.twin
				aborted.extend (False)
				from
					i := 1
				until
					i > snapshot.count or else aborted.item
				loop
					if snapshot.i_th (i).once_only then
						prune (snapshot.i_th (i).action)
					end
					snapshot.i_th (i).action.call (a_args)
					i := i + 1
				end
				aborted.remove
			when Paused_state then
				call_buffer.extend (a_args)
			when Blocked_state then
					-- dropped cold
			end
		end

	abort
			-- Stop the current round after the running action returns.
		require
			call_is_underway: call_is_underway
		do
			aborted.replace (True)
		end

feature {NONE} -- The roll and the round

	roll: ARRAYED_LIST [TUPLE [action: PROCEDURE [ARGS]; once_only: BOOLEAN]]
			-- Subscribers in order; once_only marks the kamikazes.

	call_buffer: ARRAYED_LIST [ARGS]
			-- Event data queued while Paused.

	aborted: ARRAYED_STACK [BOOLEAN]
			-- One frame per nested round; True = this round aborted.

invariant
	organs_attached: roll /= Void and call_buffer /= Void and aborted /= Void
	state_known: state = Normal_state or state = Paused_state or state = Blocked_state

end
