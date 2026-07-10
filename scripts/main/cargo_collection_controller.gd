extends RefCounted

const OffloadController := preload("res://scripts/main/offload_controller.gd")

var _main


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
		_main._sortie_state.held_salvage,
		_main._held_salvage_capacity()
	)
	if biological_result.has("note") and not str(biological_result.get("note", "")).is_empty():
		_main._last_status_note = str(biological_result["note"])
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
		_main._sortie_state.held_salvage,
		_main._held_salvage_capacity()
	)
	if material_result.has("note"):
		_main._last_status_note = str(material_result["note"])
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
		if _main._world.collect_tool_target(target_id):
			var note := "%s opened +%d" % [
				_display_label(str(result.get("label", "sealed wreck"))),
				_main._world.get_salvage_score(target_id),
			]
			_main._collect_salvage_into_cargo(target_id, note)
	elif result.has("note"):
		_main._last_status_note = str(result["note"])
	return true


func _display_label(label: String) -> String:
	var value := label.strip_edges()
	return value.substr(0, 1).to_upper() + value.substr(1) if not value.is_empty() else "Sealed wreck"


func _update_salvage(delta: float) -> void:
	if _main._held_cargo_count() >= _main._held_salvage_capacity():
		var blocked_salvage: Dictionary = _main._world.get_available_salvage_near(
			_main._player.global_position,
			_main.SALVAGE_COLLECTION_RADIUS
		)
		_main._timed_salvage.reset()
		_main._pry_salvage.update({}, delta)
		if not blocked_salvage.is_empty():
			_main._last_status_note = _main._return_pressure_feedback.cargo_full_prompt(blocked_salvage)
		return

	var nearby_salvage: Dictionary = _main._world.get_available_salvage_near(
		_main._player.global_position,
		_main.SALVAGE_COLLECTION_RADIUS
	)
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
