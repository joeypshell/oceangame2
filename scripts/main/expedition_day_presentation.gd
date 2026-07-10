extends RefCounted

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const DUSK_WARNING_SECONDS := 60.0
const NIGHT_SOON_SECONDS := 30.0


static func decorate_status(main, status_text: String) -> String:
	var line := overlay_line(main)
	return status_text if line.is_empty() else "%s\n%s" % [line, status_text]


static func overlay_line(main) -> String:
	if main == null or main._expedition_day_state == null:
		return ""
	var day = main._expedition_day_state
	var phase := str(day.phase)
	var dive_count := int(day.sortie_count)
	if phase == ExpeditionDayState.PHASE_NIGHTFALL_PENDING:
		return "Day %d | NIGHTFALL | Dive %d | Return boat" % [day.day_number, dive_count]
	if phase == ExpeditionDayState.PHASE_END_REQUESTED:
		return "Day %d | ENDING | Dive %d | Boat" % [day.day_number, dive_count]
	if phase == ExpeditionDayState.PHASE_DEBRIEF:
		return "Day %d | DEBRIEF | Dive %d" % [day.day_number, dive_count]

	var remaining := int(ceil(float(day.daylight_remaining_seconds)))
	var time_text := "%02d:%02d" % [remaining / 60, remaining % 60]
	if remaining <= int(NIGHT_SOON_SECONDS):
		time_text += " NIGHT SOON"
	elif remaining <= int(DUSK_WARNING_SECONDS):
		time_text += " DUSK"
	var line := "Day %d | %s | Dive %d" % [day.day_number, time_text, dive_count]
	var context := _location_context(main)
	return line if context.is_empty() else "%s | %s" % [line, context]


static func try_request_voluntary_end(main) -> Dictionary:
	if main == null or main._expedition_day_state == null or main._world == null or main._player == null:
		return _request_result(false, "unavailable", "End day unavailable")
	var day = main._expedition_day_state
	var result := {}
	if str(day.phase) != ExpeditionDayState.PHASE_ACTIVE:
		result = _request_result(false, "day_not_active", "Day already ending")
	elif not main._world.is_inside_boat(main._player.global_position):
		result = _request_result(false, "boat_required", "End day at boat")
	elif main._sortie_state.failed:
		result = _request_result(false, "sortie_failed", "Recover before ending day")
	elif main._sortie_state.held_salvage > 0:
		result = _request_result(false, "cargo_held", "Offload cargo first")
	elif main._anomaly_survey.has_pending_discovery():
		result = _request_result(false, "discovery_pending", "Commit discovery first")
	elif day.request_end_day("voluntary"):
		result = _request_result(true, "requested", "Day ending")
	else:
		result = _request_result(false, "request_rejected", "End day unavailable")
	main._last_status_note = str(result["note"])
	main._update_status_label()
	return result


static func _location_context(main) -> String:
	if main._world == null or main._player == null:
		return ""
	var position: Vector2 = main._player.global_position
	if main._world.is_inside_boat(position):
		if main._sortie_state.failed:
			return "Boat: Recover"
		if main._sortie_state.held_salvage > 0:
			return "Boat: Offload"
		if main._anomaly_survey.has_pending_discovery():
			return "Boat: Commit"
		return "Boat N End"
	if main._world.is_at_open_surface(position):
		return "Surface O2"
	return ""


static func _request_result(requested: bool, reason: String, note: String) -> Dictionary:
	return {"requested": requested, "reason": reason, "note": note}
