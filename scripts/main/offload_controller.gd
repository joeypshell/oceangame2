extends RefCounted


static func try_offload(main) -> bool:
	if (
		main == null
		or main._world == null
		or main._player == null
		or main._sortie_state.held_salvage <= 0
		or not main._world.is_inside_extraction(main._player.global_position)
	):
		return false

	var held_count: int = main._sortie_state.held_salvage
	var held_score: int = main._sortie_state.held_salvage_score
	var held_ids: Array[String] = main._sortie_state.held_salvage_ids.duplicate()
	var banked_cue_key := "%d:%s" % [main._banked_salvage + held_count, str(held_ids)]
	main._banked_salvage += held_count
	main._banked_score += held_score
	main._record_session_payout(held_score)
	main._record_banked_route_outcomes(held_ids)
	main._banked_salvage_ids.append_array(held_ids)
	var relay_note: String = main._relay_follow_through_feedback.banked_feedback(held_ids)
	var final_dive_note: String = main._final_dive_objective_seed.banked_feedback(held_ids)
	main._anomaly_survey.activate_lead_from_banked_ids(held_ids)
	main._expedition_day_state.record_bank(held_count, held_score)
	main._cutter_salvage.mark_banked(held_ids)
	main._sortie_state.clear_held()

	if main._should_complete_run_after_banking():
		main._run_complete = true
		main._completion_oxygen_bonus = main._calculate_oxygen_completion_bonus()
		main._record_session_best_score()
		main._last_status_note = "Run complete"
	elif not relay_note.is_empty():
		main._last_status_note = relay_note
		if not final_dive_note.is_empty():
			main._last_status_note = "%s\n%s" % [relay_note, final_dive_note]
	elif not final_dive_note.is_empty():
		main._last_status_note = final_dive_note
	else:
		main._last_status_note = "Banked salvage"
	main._play_feedback_cue("salvage_bank", banked_cue_key)
	return true
