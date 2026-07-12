extends "res://scripts/main/smoke/smoke_check_base.gd"

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CURRENT_GATE_ID := "upper_right_current_pocket_gate"
const EXPECTED_PROMPT := "Strong east current - need propulsion fins | swim through after upgrade"


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

	_player.global_position = gate["center"]
	_player.reset_motion()
	var oxygen_before: float = _oxygen_seconds
	var x_before: float = _player.global_position.x
	_process(0.25)
	var pushed_delta: float = _player.global_position.x - x_before
	if _status_text().find(EXPECTED_PROMPT) == -1:
		_fail("missing blocked prompt: %s" % _status_text())
		return
	if pushed_delta >= -1.0:
		_fail("current did not push left before fins, delta=%.2f" % pushed_delta)
		return
	if _oxygen_seconds >= oxygen_before:
		_fail("oxygen did not drain while blocked")
		return

	var profile = _main._anomaly_survey.profile_state()
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
	_player.global_position = gate["center"]
	_player.reset_motion()
	var unlocked_x: float = _player.global_position.x
	_process(0.25)
	if absf(_player.global_position.x - unlocked_x) > 0.1:
		_fail("owned fins still allowed current pushback")
		return
	var map_before := str(_world.map_id)
	if _main._try_world_connector_transition() or str(_world.map_id) != map_before:
		_fail("E triggered a transition at the standard current")
		return

	var gate_rect: Rect2 = gate["rect"]
	_player.global_position = Vector2(gate_rect.position.x + 8.0, gate_rect.get_center().y)
	_player.reset_motion()
	var swim_motion := Vector2(gate_rect.size.x + 1.0, 0.0)
	if _player.test_move(_player.global_transform, swim_motion):
		_fail("player collision envelope cannot traverse the authored current corridor")
		return
	_player.global_position += swim_motion
	_process(1.0 / 60.0)
	if _player.global_position.x <= gate_rect.end.x + 8.0:
		_fail("passive traversal probe did not finish beyond the current")
		return

	print("Current-gate smoke passed: gate=%s requirement=propulsion_fins blocked_before=true push_delta=%.2f passive_after=true player_collision_sweep=clear crossed_by_movement=true e_required=false map=%s wallet_unchanged=true." % [
		CURRENT_GATE_ID,
		pushed_delta,
		_world.map_id,
	])
	get_tree().quit(0)


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
