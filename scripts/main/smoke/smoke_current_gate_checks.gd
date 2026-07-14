extends "res://scripts/main/smoke/smoke_check_base.gd"

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CURRENT_GATE_ID := "upper_right_current_pocket_gate"
const EXPECTED_PROMPT := "Strong east current - need propulsion fins | larger route beyond"
const PHYSICS_STEP := 1.0 / 60.0
const SWIM_HOLD_SECONDS := 2.0


func _smoke_current_gate_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("loaded unexpected map %s" % _world.map_id)
		return
	var gate := _gate_by_id(CURRENT_GATE_ID)
	if gate.is_empty():
		_fail("missing gate %s" % CURRENT_GATE_ID)
		return
	if _world.find_child("%sCurrentAffordance" % CURRENT_GATE_ID, true, false) == null:
		_fail("missing source-derived current affordance")
		return
	if not _world.get_world_connector_at(gate["center"]).is_empty():
		_fail("standard current overlaps an E connector")
		return
	if _main._has_propulsion_upgrade():
		_fail("fresh profile already owns propulsion fins")
		return
	var profile = _main._anomaly_survey.profile_state()
	var profile_status := str(profile.last_storage_report().get("status", ""))
	if profile_status != "memory":
		_fail("current smoke loaded a durable profile: %s" % profile_status)
		return
	_player.set_physics_process(false)
	_main.set_process(false)
	await get_tree().physics_frame

	var gate_rect: Rect2 = gate["rect"]
	var start_position := Vector2(gate_rect.position.x + 8.0, gate_rect.get_center().y)
	var crossed_x := gate_rect.end.x + 8.0
	_player.global_position = start_position
	_player.reset_motion()
	var oxygen_before: float = _oxygen_seconds
	var blocked_report: Dictionary = await _hold_eastward_swim(SWIM_HOLD_SECONDS)
	if not bool(blocked_report["saw_blocked_prompt"]):
		_fail("missing blocked prompt: %s" % _status_text())
		return
	if float(blocked_report["max_x"]) > crossed_x:
		_fail("fresh diver crossed current under sustained input: %s" % str(blocked_report))
		return
	if _oxygen_seconds >= oxygen_before:
		_fail("oxygen did not drain while blocked")
		return

	var wallet_before: int = _session_wallet()
	var blueprint: Dictionary = profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, false)
	var deposit: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false)
	var build: Dictionary = profile.complete_material_project(
		_project_by_id(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID),
		false
	)
	_main._material_project.on_map_loaded(_world)
	if not bool(blueprint.get("changed", false)) or not bool(deposit.get("changed", false)) or not bool(build.get("changed", false)):
		_fail("could not build recipe-backed fins: %s %s %s" % [str(blueprint), str(deposit), str(build)])
		return
	if not _main._has_propulsion_upgrade() or _session_wallet() != wallet_before:
		_fail("fins capability or wallet transaction drifted")
		return

	_main._current_gate.reset()
	_player.global_position = start_position
	_player.reset_motion()
	var unlocked_report: Dictionary = await _hold_eastward_swim(SWIM_HOLD_SECONDS)
	if float(unlocked_report["final_x"]) <= crossed_x:
		_fail("owned fins did not cross current under sustained input: %s" % str(unlocked_report))
		return
	var map_before := str(_world.map_id)
	if _main._try_world_connector_transition() or str(_world.map_id) != map_before:
		_fail("E triggered a transition at the standard current")
		return

	print("Current-gate smoke passed: gate=%s requirement=propulsion_fins fresh_review=%s profile_status=%s blocked_before=true blocked_max_x=%.2f passive_after=true crossed_by_input=true crossed_x=%.2f final_x=%.2f e_required=false map=%s wallet_unchanged=true." % [
		CURRENT_GATE_ID,
		str(_main._fresh_review_profile_enabled).to_lower(),
		profile_status,
		float(blocked_report["max_x"]),
		crossed_x,
		float(unlocked_report["final_x"]),
		_world.map_id,
	])
	get_tree().quit(0)


func _hold_eastward_swim(seconds: float) -> Dictionary:
	var start_x: float = _player.global_position.x
	var max_x := start_x
	var saw_blocked_prompt := false
	for _step in range(int(ceil(seconds / PHYSICS_STEP))):
		_player.swim_in_direction(Vector2.RIGHT, PHYSICS_STEP)
		_main._process(PHYSICS_STEP)
		max_x = maxf(max_x, _player.global_position.x)
		saw_blocked_prompt = saw_blocked_prompt or _status_text().find(EXPECTED_PROMPT) != -1
		await get_tree().physics_frame
	_player.reset_motion()
	return {
		"start_x": start_x,
		"max_x": max_x,
		"final_x": _player.global_position.x,
		"saw_blocked_prompt": saw_blocked_prompt,
	}


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""


func _fail(message: String) -> void:
	push_error("Current-gate smoke failed: %s." % message)
	get_tree().quit(1)
