extends "res://scripts/main/smoke/smoke_check_base.gd"

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const CURRENT_GATE_ID := "lower_left_loop_current"
const CONNECTOR_ID := "lower_left_loop_connector"
const EXPECTED_PROMPT := "Lower-left relay current - need propulsion fins"


func _smoke_current_gate_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Current-gate smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _world.has_method("get_current_gates"):
		push_error("Current-gate smoke requires current gate runtime queries.")
		get_tree().quit(1)
		return

	var gate := _gate_by_id(CURRENT_GATE_ID)
	var connector := _connector_by_id(CONNECTOR_ID)
	if gate.is_empty() or connector.is_empty():
		push_error("Current-gate smoke requires gate %s and connector %s." % [CURRENT_GATE_ID, CONNECTOR_ID])
		get_tree().quit(1)
		return
	if _world.find_child("%sCurrentAffordance" % CURRENT_GATE_ID, true, false) == null:
		push_error("Current-gate smoke found no normal-world affordance for %s." % CURRENT_GATE_ID)
		get_tree().quit(1)
		return

	if _main._has_propulsion_upgrade():
		push_error("Current-gate smoke expected fresh propulsion state.")
		get_tree().quit(1)
		return

	_player.global_position = gate["center"]
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	var oxygen_before: float = _oxygen_seconds
	var x_before: float = _player.global_position.x
	_process(0.25)
	var oxygen_after_block: float = _oxygen_seconds
	var blocked_status := _status_text()
	var pushed_delta: float = _player.global_position.x - x_before
	if blocked_status.find(EXPECTED_PROMPT) == -1:
		push_error("Current-gate smoke missing blocked prompt: %s." % blocked_status)
		get_tree().quit(1)
		return
	if pushed_delta <= 1.0:
		push_error("Current-gate smoke expected rightward pushback, delta=%.2f." % pushed_delta)
		get_tree().quit(1)
		return
	if oxygen_after_block >= oxygen_before:
		push_error("Current-gate smoke expected oxygen to drain while blocked: before=%.1f after=%.1f." % [oxygen_before, oxygen_after_block])
		get_tree().quit(1)
		return

	_player.global_position = connector["center"]
	if _main._try_world_connector_transition():
		push_error("Current-gate smoke allowed connector transition before propulsion upgrade.")
		get_tree().quit(1)
		return
	if _status_text().find(EXPECTED_PROMPT) == -1:
		push_error("Current-gate smoke connector block did not show current prompt: %s." % _status_text())
		get_tree().quit(1)
		return

	var profile = _main._anomaly_survey.profile_state()
	var wallet_before: int = _session_wallet()
	var deposit: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	}, false)
	var project := _project_by_id(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID)
	var build: Dictionary = profile.complete_material_project(project, false)
	_main._material_project.on_map_loaded(_world)
	if not bool(deposit.get("changed", false)) or not bool(build.get("changed", false)) or not _main._has_propulsion_upgrade():
		push_error("Current-gate smoke could not build recipe-backed propulsion fins: %s %s." % [str(deposit), str(build)])
		get_tree().quit(1)
		return
	if _session_wallet() != wallet_before or not profile.material_inventory().is_empty():
		push_error("Current-gate smoke fins recipe changed wallet or did not consume exact ingredients.")
		get_tree().quit(1)
		return

	_player.global_position = connector["center"]
	if not _main._try_world_connector_transition():
		push_error("Current-gate smoke did not allow connector after propulsion upgrade: %s." % _status_text())
		get_tree().quit(1)
		return
	if _world.map_id != "production_slice_04":
		push_error("Current-gate smoke loaded wrong destination after upgrade: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _main._has_propulsion_upgrade():
		push_error("Current-gate smoke lost propulsion upgrade after connector transition.")
		get_tree().quit(1)
		return

	print("Current-gate smoke passed: gate=%s direction=%s strength=%.2f capability=%s recipe=ti2+rubber1 wallet_unchanged=true affordance=true pushed_delta=%.2f oxygen_before=%.1f oxygen_after=%.1f transition_after_upgrade=true." % [
		CURRENT_GATE_ID,
		str(gate.get("current_direction", "")),
		float(gate.get("current_strength", 0.0)),
		str(gate.get("required_capability_id", "")),
		pushed_delta,
		oxygen_before,
		oxygen_after_block,
	])
	get_tree().quit()


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _project_by_id(project_id: String) -> Dictionary:
	for project in _world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
