extends RefCounted

const OffloadController := preload("res://scripts/main/offload_controller.gd")
const ScannerCutterJourneyPresentation := preload("res://scripts/main/scanner_cutter_journey_presentation.gd")

var _main
var _scanner_cutter_presentation := ScannerCutterJourneyPresentation.new()


func _init(main) -> void:
	_main = main


func update(delta: float) -> void:
	var biological_result: Dictionary = _main._biological_resources.update(
		_main._world,
		_main._hostiles,
		_main._material_runtime,
		_main._player.global_position,
		_main.SALVAGE_COLLECTION_RADIUS,
		delta,
		_main._sortie_state.held_salvage + _main._navigation_core.held_count(),
		_main._held_salvage_capacity()
	)
	if biological_result.has("note") and not str(biological_result.get("note", "")).is_empty():
		_main._last_status_note = str(biological_result["note"])
	if bool(biological_result.get("collected", false)):
		_main._play_feedback_cue("material_pickup", str(biological_result.get("id", "biological_material")))
	if bool(biological_result.get("handled", false)):
		_main._cutter_salvage.reset()
		_main._timed_salvage.reset()
		_main._pry_salvage.reset()
	else:
		_update_non_biological_collection(delta)
	OffloadController.try_offload(_main)
	var material_commit: Dictionary = _main._material_runtime.try_commit_at_boat(
		_main._world,
		_main._player.global_position
	)
	if material_commit.has("note"):
		_main._last_status_note = str(material_commit["note"])


func _update_non_biological_collection(delta: float) -> void:
	var material_result: Dictionary = _main._material_runtime.update_collection(
		_main._world,
		_main._player.global_position,
		_main.SALVAGE_COLLECTION_RADIUS,
		_main._expedition_day_state,
		_main._sortie_state.held_salvage + _main._navigation_core.held_count(),
		_main._held_salvage_capacity()
	)
	if material_result.has("note"):
		_main._last_status_note = str(material_result["note"])
	if bool(material_result.get("changed", false)):
		var candidate: Dictionary = material_result.get("candidate", {})
		_main._play_feedback_cue("material_pickup", str(candidate.get("id", "material")))
	if bool(material_result.get("changed", false)) or bool(material_result.get("blocked", false)):
		_main._cutter_salvage.reset()
	elif not _update_tool_target(delta):
		_update_salvage(delta)


func _update_tool_target(delta: float) -> bool:
	var target: Dictionary = _main._world.get_tool_target_near(
		_main._player.global_position,
		_main.SALVAGE_COLLECTION_RADIUS
	)
	var result: Dictionary = _main._cutter_salvage.update(
		target,
		delta,
		_main._held_cargo_count(),
		_main._held_salvage_capacity()
	)
	if target.is_empty():
		if str(result.get("state", "")) == "canceled":
			_main._last_status_note = str(result.get("note", "Cutter interrupted"))
		return false

	_main._timed_salvage.update({}, delta)
	_main._pry_salvage.update({}, delta)
	if str(result.get("state", "")) == "complete":
		var target_id := str(result.get("id", ""))
		var reward: Dictionary = _main._anomaly_survey.record_tool_target_reward(target, _main._world)
		if not bool(reward.get("allow_collection", false)):
			_main._last_status_note = str(reward.get("note", "Wreck data unavailable"))
			return true
		if _main._world.collect_tool_target(target_id):
			_main._anomaly_survey.record_tool_target_clearance(target, _main._world)
			if _main._navigation_core.handles(target):
				var secured: Dictionary = _main._navigation_core.secure(
					target,
					str(_main._world.map_id),
					reward
				)
				if bool(secured.get("changed", false)):
					_main._last_status_note = str(secured.get("note", "Navigation core secured | Return to the boat"))
					_main._play_feedback_cue("salvage_pickup", target_id)
				else:
					_main._world.restore_salvage([target_id])
					_main._anomaly_survey.clear_unbanked("navigation_core_secure_failed", _main._world)
					_main._last_status_note = str(secured.get("note", "Navigation core could not be secured"))
				return true
			var score: int = int(_main._world.get_salvage_score(target_id))
			var note: String = _scanner_cutter_presentation.completion_note(target, score, bool(reward.get("pending", false)))
			if note.is_empty():
				note = "%s opened +%d" % [_display_label(str(result.get("label", "sealed wreck"))), score]
			_main._collect_salvage_into_cargo(target_id, note)
		elif bool(reward.get("changed", false)):
			_main._anomaly_survey.clear_unbanked("tool_target_collect_failed", _main._world)
			_main._last_status_note = "Wreck data could not be secured"
	elif str(result.get("state", "")) == "ready" and _main._active_tools.selected_tool_id() != _main.ActiveToolController.CUTTER_TOOL_ID:
		_main._last_status_note = "%s | Tab Cutter | Space/USE" % _display_label(str(result.get("label", "sealed wreck")))
	elif result.has("note"):
		_main._last_status_note = str(result["note"])
	return true


func _display_label(label: String) -> String:
	var value := label.strip_edges()
	return value.substr(0, 1).to_upper() + value.substr(1) if not value.is_empty() else "Sealed wreck"


func _update_salvage(delta: float) -> void:
	var nearby_salvage: Dictionary = _main._world.get_available_salvage_near(
		_main._player.global_position,
		_main.SALVAGE_COLLECTION_RADIUS
	)
	if _main._held_cargo_count() >= _main._held_salvage_capacity():
		_main._timed_salvage.reset()
		_main._pry_salvage.update({}, delta)
		if not nearby_salvage.is_empty():
			_main._last_status_note = _main._return_pressure_feedback.cargo_full_prompt(nearby_salvage)
		return

	var interaction := str(nearby_salvage.get("interaction", "instant"))
	if not nearby_salvage.is_empty() and interaction == "timed_salvage":
		_update_timed(nearby_salvage, delta)
	elif not nearby_salvage.is_empty() and interaction == "pry_salvage":
		_update_pry(nearby_salvage, delta)
	else:
		_cancel_interactions_and_collect(delta)


func _update_timed(salvage: Dictionary, delta: float) -> void:
	_main._pry_salvage.update({}, delta)
	var result: Dictionary = _main._timed_salvage.update(salvage, delta)
	if str(result.get("state", "")) == "complete":
		var salvage_id := str(result.get("id", ""))
		if _main._world.collect_salvage_by_id(salvage_id):
			var note: String = _main._timed_salvage_completion_feedback(salvage_id, str(result.get("label", "")))
			_main._collect_salvage_into_cargo(salvage_id, note)
	elif result.has("note"):
		_main._last_status_note = str(result["note"])


func _update_pry(salvage: Dictionary, delta: float) -> void:
	_main._timed_salvage.update({}, delta)
	var result: Dictionary = _main._pry_salvage.update(salvage, delta)
	if str(result.get("state", "")) == "complete":
		var salvage_id := str(result.get("id", ""))
		if _main._world.collect_salvage_by_id(salvage_id):
			var note: String = _main._pry_salvage_completion_feedback(salvage_id, str(result.get("label", "")))
			_main._collect_salvage_into_cargo(salvage_id, note)
	elif result.has("note"):
		_main._last_status_note = str(result["note"])


func _cancel_interactions_and_collect(delta: float) -> void:
	var timed_cancel: Dictionary = _main._timed_salvage.update({}, delta)
	if str(timed_cancel.get("state", "")) == "canceled":
		_main._last_status_note = str(timed_cancel.get("note", "Salvage interrupted"))
	var pry_cancel: Dictionary = _main._pry_salvage.update({}, delta)
	if str(pry_cancel.get("state", "")) == "canceled":
		_main._last_status_note = str(pry_cancel.get("note", "Pry interrupted"))
	var salvage_id: String = _main._world.collect_salvage_near(
		_main._player.global_position,
		_main.SALVAGE_COLLECTION_RADIUS
	)
	if not salvage_id.is_empty():
		_main._collect_salvage_into_cargo(salvage_id)
