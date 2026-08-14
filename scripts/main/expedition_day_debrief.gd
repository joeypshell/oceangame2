extends RefCounted

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")
const DailyConditionPresentation := preload("res://scripts/main/daily_condition_presentation.gd")
const OffloadController := preload("res://scripts/main/offload_controller.gd")
const PRODUCTION_LEVEL_MAP_ID := "production_level_01"
const RESULT_PANEL_POSITION := Vector2(12, 204)
const DEBRIEF_PANEL_POSITION := Vector2(12, 12)


static func update(main, delta: float) -> bool:
	if main == null or main._expedition_day_state == null:
		return false
	var day = main._expedition_day_state
	_sync_mobile_controls(main, "debrief" if day.phase == ExpeditionDayState.PHASE_DEBRIEF else "dive")
	if day.phase == ExpeditionDayState.PHASE_DEBRIEF:
		return true
	if day.phase == ExpeditionDayState.PHASE_END_REQUESTED:
		_enter_debrief(main, "voluntary")
		return true
	if day.phase == ExpeditionDayState.PHASE_NIGHTFALL_PENDING:
		_resolve_nightfall(main)
		return true
	if day.phase != ExpeditionDayState.PHASE_ACTIVE:
		return true

	var daylight_result: Dictionary = day.advance_daylight(delta)
	if bool(daylight_result.get("nightfall_triggered", false)):
		_resolve_nightfall(main)
		return true
	return false


static func handle_day_key(main) -> Dictionary:
	if main == null or main._expedition_day_state == null:
		return {"changed": false, "reason": "unavailable"}
	if main._expedition_day_state.phase != ExpeditionDayState.PHASE_DEBRIEF:
		return ExpeditionDayPresentation.try_request_voluntary_end(main)
	if main._wreck_network_investigation != null and main._wreck_network_investigation.requires_analysis():
		var analysis_result := resolve_wreck_network_night_payoff(main)
		if not bool(analysis_result.get("changed", false)):
			main._update_status_label()
			return {
				"changed": false,
				"reason": "analysis_save_failed",
				"note": main._last_status_note,
			}
	var companion_sortie = _companion_sortie_for(main)
	if companion_sortie != null and companion_sortie.requires_adaptation_selection():
		main._last_status_note = "Consolidate one companion adaptation before starting the next day"
		main._update_status_label()
		return {
			"changed": false,
			"reason": "companion_adaptation_required",
			"note": main._last_status_note,
		}
	var plan_report: Dictionary = main._refresh_expedition_plan()
	if _planner_requires_selection(main, plan_report):
		main._last_status_note = "Pin an expedition plan before starting the next day"
		main._update_status_label()
		return {
			"changed": false,
			"reason": "plan_required",
			"note": main._last_status_note,
		}

	var restart_map_path := _restart_map_path(main)
	if companion_sortie != null:
		var nursery_day: Dictionary = companion_sortie.advance_signal_reef_journey_day(
			main._expedition_day_state.day_number + 1
		)
		if str(nursery_day.get("reason", "")) == "storage_error":
			main._last_status_note = "Signal Reef history could not be saved"
			main._update_status_label()
			return nursery_day
	main._expedition_day_state.begin_next_day()
	if companion_sortie != null:
		companion_sortie.end_debrief()
	main._load_playable_map(
		restart_map_path,
		main._debug_overlay_enabled,
		"surface_boat_entry",
		"New expedition day"
	)
	if main._player != null:
		main._player.set_physics_process(true)
	main._update_status_label()
	return {
		"changed": true,
		"reason": "next_day_started",
		"day_number": main._expedition_day_state.day_number,
	}


static func handle_debrief_input(main, event: InputEvent) -> Dictionary:
	if main == null or main._expedition_day_state == null:
		return {"changed": false, "reason": "unavailable"}
	if main._expedition_day_state.phase != ExpeditionDayState.PHASE_DEBRIEF:
		return {"changed": false, "reason": "wrong_phase"}
	var companion_sortie = _companion_sortie_for(main)
	if companion_sortie != null:
		var companion_result: Dictionary = companion_sortie.handle_debrief_input(event)
		if bool(companion_result.get("handled", false)):
			if companion_result.has("note"):
				main._last_status_note = str(companion_result["note"])
			main._update_status_label()
			return companion_result
	var repeated_key := event is InputEventKey and (event as InputEventKey).echo
	if event.is_action_pressed("active_tool_cycle_next") and not repeated_key:
		return _cycle_plan_highlight(main)
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			return handle_debrief_key(main, _supported_keycode(key_event))
	return {"changed": false, "reason": "ignored"}


static func _supported_keycode(event: InputEventKey) -> Key:
	for candidate in [KEY_TAB, KEY_E, KEY_N, KEY_P]:
		if event.keycode == candidate or event.physical_keycode == candidate:
			return candidate
	return event.keycode


static func handle_debrief_key(main, keycode: Key) -> Dictionary:
	if main == null or main._expedition_day_state == null:
		return {"changed": false, "reason": "unavailable"}
	if main._expedition_day_state.phase != ExpeditionDayState.PHASE_DEBRIEF:
		return {"changed": false, "reason": "wrong_phase"}
	if keycode == KEY_TAB:
		return _cycle_plan_highlight(main)
	if keycode == KEY_E:
		return _pin_highlighted_plan(main)
	if keycode == KEY_N:
		return handle_day_key(main)
	if keycode != KEY_P or main._material_project == null:
		return {"changed": false, "reason": "ignored"}
	var result: Dictionary = main._material_project.try_build(main._expedition_day_state.phase)
	if main.has_method("_refresh_expedition_plan"):
		main._refresh_expedition_plan()
	main._last_status_note = str(result.get("note", main._last_status_note))
	main._update_status_label()
	return result


static func _cycle_plan_highlight(main) -> Dictionary:
	var plan_report: Dictionary = main._refresh_expedition_plan()
	if main._expedition_plan_panel == null:
		return {"changed": false, "reason": "planner_unavailable"}
	var selection: Dictionary = (
		main._expedition_plan_state.report()
		if main._expedition_plan_state != null
		else {}
	)
	var result: Dictionary = main._expedition_plan_panel.cycle_highlight(
		plan_report,
		selection,
		str(main._expedition_day_state.phase)
	)
	main._update_status_label()
	return result


static func resolve_wreck_network_night_payoff(main) -> Dictionary:
	if main._wreck_network_investigation == null:
		return {"changed": false, "reason": "investigation_unavailable"}
	if not main._wreck_network_investigation.requires_analysis():
		return {"changed": false, "status": "not_ready"}
	var result: Dictionary = main._wreck_network_investigation.try_analyze(
		str(main._expedition_day_state.phase)
	)
	if str(result.get("status", "")) == "unavailable":
		return {"changed": false, "reason": "investigation_unavailable"}
	main._last_status_note = str(result.get("note", main._last_status_note))
	if bool(result.get("changed", false)):
		var state: Dictionary = result.get("state", {})
		main._expedition_day_state.record_discovery(str(state.get("analysis_discovery_id", "")))
	return result


static func _pin_highlighted_plan(main) -> Dictionary:
	var plan_report: Dictionary = main._refresh_expedition_plan()
	if (
		main._expedition_plan_panel == null
		or main._expedition_plan_state == null
		or str(plan_report.get("status", "")) != "choice_ready"
	):
		return {"changed": false, "reason": "planner_inactive"}
	main._expedition_plan_panel.refresh(
		plan_report,
		main._expedition_plan_state.report(),
		str(main._expedition_day_state.phase)
	)
	var lead_id: String = main._expedition_plan_panel.highlighted_lead_id()
	var eligible_ids: Array = plan_report.get("eligible_ids", [])
	var result: Dictionary
	if main._expedition_plan_state.has_selection():
		result = main._expedition_plan_state.replace(
			lead_id,
			eligible_ids,
			str(main._expedition_day_state.phase)
		)
	else:
		result = main._expedition_plan_state.select(
			lead_id,
			eligible_ids,
			str(main._expedition_day_state.phase)
		)
	main._refresh_expedition_plan()
	var label := _lead_label(plan_report, lead_id)
	main._last_status_note = "Plan pinned: %s" % label
	main._update_status_label()
	result["lead_id"] = lead_id
	result["label"] = label
	return result


static func _planner_requires_selection(main, plan_report: Dictionary) -> bool:
	if str(plan_report.get("status", "")) != "choice_ready":
		return false
	if main._expedition_plan_state == null:
		return true
	var selected_id := str(main._expedition_plan_state.selected_lead_id())
	return (
		selected_id.is_empty()
		or not plan_report.get("eligible_ids", []).has(selected_id)
	)


static func _lead_label(plan_report: Dictionary, lead_id: String) -> String:
	for value in plan_report.get("eligible_leads", []):
		if (
			typeof(value) == TYPE_DICTIONARY
			and str(value.get("lead_id", "")) == lead_id
		):
			return str(value.get("label", lead_id))
	return lead_id


static func apply_result_panel(main) -> bool:
	if main == null or main._result_panel == null or main._result_label == null:
		return false
	var is_debrief: bool = main._expedition_day_state != null and main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF
	var review_panel = main._review_canvas.get_node_or_null("ReviewPanel") if main._review_canvas != null else null
	if not is_debrief:
		main._result_panel.position = RESULT_PANEL_POSITION
		if review_panel != null:
			review_panel.visible = true
		return false

	if review_panel != null:
		review_panel.visible = false
	main._result_panel.position = DEBRIEF_PANEL_POSITION
	main._result_panel.visible = true
	var companion_sortie = _companion_sortie_for(main)
	main._result_label.text = build_text(
		main._expedition_day_state,
		main._material_project,
		main._daily_conditions,
		main._last_status_note,
		main._wreck_network_investigation,
		companion_sortie
	)
	return true


static func build_text(
	day,
	material_project = null,
	daily_conditions = null,
	debrief_feedback := "",
	wreck_network_investigation = null,
	companion_sortie = null
) -> String:
	var reason_text := "Day ended at boat"
	if day.end_reason == "nightfall":
		reason_text = "Returned at nightfall"
	elif day.end_reason == "nightfall_forced_recovery":
		reason_text = "Forced recovery at nightfall"
	var lines: Array[String] = [
		"Night %d" % day.day_number,
		reason_text,
		"Dives %d" % day.sortie_count,
		"Banked cargo %d" % day.banked_salvage,
		"Banked value %d" % day.banked_score,
		"Discoveries %d" % day.committed_discovery_ids.size(),
	]
	var failure_text := _failure_text(day.notable_failure_reason)
	if not failure_text.is_empty():
		lines.append("Recovery: %s" % failure_text)
	if material_project != null and material_project.has_method("debrief_lines"):
		for line in material_project.debrief_lines():
			lines.append(str(line))
	var wreck_lines: Array[String] = []
	if wreck_network_investigation != null and wreck_network_investigation.has_method("debrief_lines"):
		for line in wreck_network_investigation.debrief_lines():
			wreck_lines.append(str(line))
			lines.append(str(line))
	if companion_sortie != null and companion_sortie.has_method("debrief_lines"):
		for line in companion_sortie.debrief_lines():
			lines.append(str(line))
	var feedback := str(debrief_feedback).strip_edges()
	var wreck_owns_feedback: bool = (
		not wreck_lines.is_empty()
		and wreck_network_investigation != null
		and wreck_network_investigation.has_method("is_status_note")
		and wreck_network_investigation.is_status_note(feedback)
	)
	if (
		not feedback.is_empty()
		and feedback != "Day complete"
		and not feedback.begins_with("Plan pinned:")
		and not wreck_owns_feedback
		and not lines.has(feedback)
	):
		lines.append(feedback)
	var forecast_line := DailyConditionPresentation.forecast_line(daily_conditions)
	if not forecast_line.is_empty():
		lines.append(forecast_line)
	lines.append("N: Start day %d" % (day.day_number + 1))
	return "\n".join(lines)


static func _resolve_nightfall(main) -> void:
	if main._world.is_inside_boat(main._player.global_position):
		_commit_boat_discovery(main)
		OffloadController.try_offload(main)
		_commit_boat_materials(main)
		_enter_debrief(main, "nightfall")
		return

	main._expedition_day_state.record_failure("nightfall_forced_recovery")
	main._anomaly_survey.clear_unbanked("nightfall", main._world)
	main._oxygen_rest_feedback.reset()
	main._current_gate.reset()
	main._moving_hazards.reset(main._world)
	main._pry_salvage.reset()
	main._timed_salvage.reset()
	main._cutter_salvage.reset()
	main._material_runtime.discard_unbanked("nightfall")
	if not main._sortie_state.held_salvage_ids.is_empty():
		main._world.restore_salvage(main._sortie_state.clear_held())
	main._load_playable_map(
		_restart_map_path(main),
		main._debug_overlay_enabled,
		"surface_boat_entry",
		"Nightfall recovery"
	)
	_enter_debrief(main, "nightfall_forced_recovery")


static func _commit_boat_discovery(main) -> void:
	var survey_result: Dictionary = main._anomaly_survey.update(main._world, main._player, 0.0)
	if bool(survey_result.get("committed", false)):
		main._expedition_day_state.record_discovery(str(survey_result.get("discovery_id", "")))


static func _commit_boat_materials(main) -> void:
	if main._material_runtime != null:
		main._material_runtime.try_commit_at_boat(main._world, main._player.global_position)


static func _enter_debrief(main, reason: String) -> void:
	if reason == "voluntary" and main._world != null and main._player != null and main._world.is_inside_boat(main._player.global_position):
		_commit_boat_materials(main)
	var companion_sortie = _companion_sortie_for(main)
	if companion_sortie != null:
		companion_sortie.commit_memories_at_boat(main._expedition_day_state.day_number)
	main._expedition_day_state.end_day(reason)
	if companion_sortie != null:
		companion_sortie.begin_debrief()
	var analysis_result := resolve_wreck_network_night_payoff(main)
	if main.has_method("_refresh_expedition_plan"):
		main._refresh_expedition_plan()
	main._run_complete = false
	main._sortie_state.failed = false
	main._sortie_state.failure_reason = ""
	main._sortie_state.active = false
	if not bool(analysis_result.get("changed", false)) and str(analysis_result.get("status", "")) != "storage_error":
		main._last_status_note = "Day complete"
	if main._player != null:
		main._player.set_physics_process(false)
		if main._player.has_method("reset_motion"):
			main._player.reset_motion()
	main._update_status_label()


static func _restart_map_path(main) -> String:
	if main._world != null and str(main._world.map_id) == PRODUCTION_LEVEL_MAP_ID:
		return main.PRODUCTION_LEVEL_MAP_PATH
	return main.PRODUCTION_SLICE_MAP_PATH


static func _sync_mobile_controls(main, context_mode: String) -> void:
	var controls = main.get_node_or_null("MobileTestControls")
	if controls != null and controls.has_method("set_context_mode"):
		controls.set_context_mode(context_mode)


static func _companion_sortie_for(main):
	if main == null or not main.has_method("get_property_list"):
		return null
	for property in main.get_property_list():
		if str(property.get("name", "")) == "_companion_sortie":
			return main.get("_companion_sortie")
	return null


static func _failure_text(reason: String) -> String:
	if reason == "nightfall_forced_recovery":
		return "Nightfall, unbanked progress lost"
	if reason == "oxygen_depleted":
		return "Oxygen depletion"
	return reason.replace("_", " ").capitalize() if not reason.is_empty() else ""
