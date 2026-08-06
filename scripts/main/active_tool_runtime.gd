extends RefCounted

const ActiveToolController := preload("res://scripts/main/active_tool_controller.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")

var _main
var _selection


func _init(main_node, selection_controller) -> void:
	_main = main_node
	_selection = selection_controller


func refresh() -> Dictionary:
	if _selection == null:
		return {}
	var previous_tool_id: String = _selection.selected_tool_id()
	var report: Dictionary = _selection.refresh_ownership(_capability_query())
	var selected_tool_id := str(report.get("selected_tool_id", ""))
	if previous_tool_id != selected_tool_id:
		_cancel_interaction(previous_tool_id)
	return report


func report() -> Dictionary:
	return refresh()


func combat_prompt() -> String:
	var hostile_prompt := str(_main._hostiles.prompt()) if _main._hostiles != null else ""
	if (
		_selection == null
		or _main._material_project == null
		or not _main._material_project.has_shock_prod()
		or _main._hostiles == null
		or hostile_prompt.is_empty()
		or hostile_prompt.begins_with("Territory clear")
	):
		return ""
	if _selection.selected_tool_id() != ActiveToolController.SHOCK_PROD_TOOL_ID:
		return "Eel active | Tab/TOOL select Shock prod | Space/USE"
	if _hostile_target().is_empty():
		return "Shock prod selected | move close and face eel | Space/USE"
	return "Eel in Shock prod range | Space/USE discharge"


func cycle() -> Dictionary:
	var previous_tool_id: String = _selection.selected_tool_id()
	var report: Dictionary = _selection.cycle_next(_capability_query())
	var selected_tool_id := str(report.get("selected_tool_id", ""))
	if previous_tool_id != selected_tool_id:
		_cancel_interaction(previous_tool_id)
	_main._last_status_note = "Active tool: %s" % str(report.get("selected_label", "None")) if not selected_tool_id.is_empty() else "No active tool equipped"
	_main._update_status_label()
	return report


func use() -> Dictionary:
	var result: Dictionary = _selection.use_selected(_capability_query(), Callable(self, "_dispatch"))
	if str(result.get("status", "")) == "no_tool" and _main._anomaly_survey != null:
		var scanner_guidance: Dictionary = _main._anomaly_survey.scanner_action(_main._world, _main._player)
		result["note"] = str(scanner_guidance.get("note", "No active tool equipped"))
	if result.has("note"):
		_main._last_status_note = str(result["note"])
	elif str(result.get("status", "")) == "no_tool":
		_main._last_status_note = "No active tool equipped"
	_main._update_status_label()
	return result


func release_use() -> Dictionary:
	if _selection == null:
		return {"changed": false, "reason": "idle"}
	var selected_tool_id: String = _selection.selected_tool_id()
	var result: Dictionary = {}
	if selected_tool_id == ActiveToolController.CUTTER_TOOL_ID and _main._companion_rescue != null:
		result = _main._companion_rescue.release_use()
	elif selected_tool_id == ActiveToolController.SCANNER_TOOL_ID and _main._anomaly_survey != null:
		result = _main._anomaly_survey.scanner_release(_main._world)
		_main._player.sync_scanner_presentation(_main._anomaly_survey.report())
	else:
		return {"changed": false, "reason": "idle"}
	if bool(result.get("changed", false)):
		_main._last_status_note = str(result.get("note", "Tool interaction interrupted"))
		_main._update_status_label()
	return result


func use_shock_prod() -> Dictionary:
	if _main._shock_prod == null or _main._hostiles == null or _main._world == null or _main._player == null or _main._run_complete or _main._sortie_state.failed:
		return {"status": "unavailable", "note": "Shock prod unavailable", "changed": false}
	if not _main._material_project.has_shock_prod():
		_main._last_status_note = _main._material_project.shock_prod_guidance()
		_main._combat_feedback_seconds = _main.COMBAT_FEEDBACK_SECONDS
		return {"status": "unavailable", "note": _main._last_status_note, "changed": false}
	var facing_sign: float = float(_main._player.get_facing_sign()) if _main._player.has_method("get_facing_sign") else 1.0
	var result: Dictionary = _main._shock_prod.try_attack(
		_main._hostiles,
		_main._world,
		_main._player.global_position,
		facing_sign,
		_main._material_project.has_shock_prod(),
		_main._material_project.has_shock_prod_capacitor()
	)
	if _main._player.has_method("show_shock_prod_action"):
		_main._player.show_shock_prod_action(result, facing_sign)
	_main._last_status_note = str(result.get("note", _main._last_status_note))
	_main._combat_feedback_seconds = _main.COMBAT_FEEDBACK_SECONDS
	result["status"] = "unavailable" if str(result.get("reason", "")) == "cooldown" else "used"
	return result


func _dispatch(tool_id: String) -> Dictionary:
	if not _has_context(tool_id):
		var wrong_context := _wrong_context(tool_id)
		if not wrong_context.is_empty():
			return wrong_context
	match tool_id:
		ActiveToolController.SCANNER_TOOL_ID:
			return _use_scanner()
		ActiveToolController.CUTTER_TOOL_ID:
			return _use_cutter()
		ActiveToolController.SHOCK_PROD_TOOL_ID:
			return use_shock_prod()
	return {"status": "no_tool", "note": "No active tool equipped"}


func _has_context(tool_id: String) -> bool:
	match tool_id:
		ActiveToolController.SCANNER_TOOL_ID:
			return not _main._anomaly_survey.active_tool_target(_main._world, _main._player).is_empty()
		ActiveToolController.CUTTER_TOOL_ID:
			return not _rescue_target().is_empty() or not _cutter_target().is_empty()
		ActiveToolController.SHOCK_PROD_TOOL_ID:
			return not _hostile_target().is_empty()
	return false


func _use_scanner() -> Dictionary:
	var result: Dictionary = _main._anomaly_survey.scanner_action(_main._world, _main._player)
	_main._player.show_scanner_action(result, _main._anomaly_survey.report())
	var reason := str(result.get("reason", ""))
	result["status"] = "used" if reason in ["activated", "identified"] else "wrong_context" if reason == "ready" else "unavailable"
	return result


func _use_cutter() -> Dictionary:
	if not _rescue_target().is_empty() and _main._companion_rescue != null:
		return _main._companion_rescue.activate()
	var result: Dictionary = _main._cutter_salvage.activate(
		_cutter_target(),
		_main._held_cargo_count(),
		_main._held_salvage_capacity()
	)
	var state := str(result.get("state", ""))
	result["status"] = "used" if state == "activated" else "wrong_context" if state in ["wrong_context", "blocked"] else "unavailable"
	return result


func _wrong_context(tool_id: String) -> Dictionary:
	if not _rescue_target().is_empty() and tool_id != ActiveToolController.CUTTER_TOOL_ID and _main._cutter_salvage.has_cutter():
		return {"status": "wrong_context", "note": _main._companion_rescue.prompt()}
	var cutter_target := _cutter_target()
	if not cutter_target.is_empty() and tool_id != ActiveToolController.CUTTER_TOOL_ID and _main._cutter_salvage.has_cutter():
		return {"status": "wrong_context", "note": "%s | Tab Cutter | Space/USE" % _target_label(cutter_target, "Sealed wreck")}

	if not _hostile_target().is_empty() and tool_id != ActiveToolController.SHOCK_PROD_TOOL_ID and _main._material_project.has_shock_prod():
		return {"status": "wrong_context", "note": "Eel in range | Tab Shock prod | Q Use"}

	var survey_target: Dictionary = _main._anomaly_survey.active_tool_target(_main._world, _main._player)
	if not survey_target.is_empty() and tool_id != ActiveToolController.SCANNER_TOOL_ID and _main._anomaly_survey.has_scanner():
		return {"status": "wrong_context", "note": "%s | Tab Scanner | Hold Space/USE" % _target_label(survey_target, "Survey signal")}
	return {}


func _cutter_target() -> Dictionary:
	return _main._world.get_tool_target_near(_main._player.global_position, _main.SALVAGE_COLLECTION_RADIUS)


func _rescue_target() -> Dictionary:
	if _main._companion_rescue == null:
		return {}
	return _main._companion_rescue.target_near()


func _hostile_target() -> Dictionary:
	var facing_sign: float = float(_main._player.get_facing_sign()) if _main._player.has_method("get_facing_sign") else 1.0
	return _main._hostiles.attack_target(
		_main._player.global_position,
		facing_sign,
		ShockProdController.ATTACK_RANGE_PX,
		ShockProdController.ATTACK_HALF_ANGLE_DEGREES
	)


func _target_label(target: Dictionary, fallback: String) -> String:
	var label := str(target.get("scan_subject_label", target.get("interaction_label", target.get("clue_label", "")))).replace("_", " ").strip_edges()
	if label.is_empty():
		return fallback
	return label.substr(0, 1).to_upper() + label.substr(1)


func _cancel_interaction(tool_id: String) -> void:
	if tool_id == ActiveToolController.SCANNER_TOOL_ID and _main._anomaly_survey != null:
		_main._anomaly_survey.cancel_active_interaction(_main._world)
	elif tool_id == ActiveToolController.CUTTER_TOOL_ID and _main._cutter_salvage != null:
		_main._cutter_salvage.reset()
		if _main._companion_rescue != null:
			_main._companion_rescue.cancel_interaction("tool_changed")


func _capability_query() -> Callable:
	if _main._anomaly_survey == null or _main._anomaly_survey.profile_state() == null:
		return Callable()
	return Callable(_main._anomaly_survey.profile_state(), "has_capability")
