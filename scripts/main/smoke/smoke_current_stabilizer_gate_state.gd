extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const CurrentGateController := preload("res://scripts/main/current_gate_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const TEST_PATH := "user://oceangame2_current_stabilizer_gate_test.json"
const SLICE_01 := "res://maps/production_slice_01.greybox.json"
const STANDARD_GATE_ID := "upper_right_current_pocket_gate"
const ADVANCED_GATE_ID := "lower_left_loop_current"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world = WORLD_SCENE.instantiate()
	world.map_path = SLICE_01
	get_root().add_child(world)
	world.load_greybox()
	var standard_gate := _gate_by_id(world, STANDARD_GATE_ID)
	var advanced_gate := _gate_by_id(world, ADVANCED_GATE_ID)
	_expect(not standard_gate.is_empty(), "standard propulsion gate missing")
	_expect(not advanced_gate.is_empty(), "advanced current gate missing")
	_expect(str(standard_gate.get("required_capability_id", "")) == ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID, "standard gate requirement drifted")
	_expect(str(advanced_gate.get("required_capability_id", "")) == ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID, "advanced gate requirement drifted")

	var profile := ExpansionProfileState.new(TEST_PATH)
	profile.load_profile()
	var controller := CurrentGateController.new()
	var player := Node2D.new()
	get_root().add_child(player)
	player.global_position = advanced_gate["center"]
	var durable_x_before: float = player.global_position.x
	var blocked: Dictionary = controller.update(
		world,
		player,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		0.25
	)
	_expect(bool(blocked.get("blocked", false)), "durable gate allowed passage before capability")
	_expect(str(blocked.get("requirement_kind", "")) == "capability", "durable gate did not resolve capability owner")
	_expect(player.global_position.x > durable_x_before + 1.0, "advanced gate did not apply authored right pushback")
	_expect(controller.current_prompt() == "Ripping relay current - need current stabilizer | advanced current", "advanced gate prompt drifted")
	player.global_position = world.spawn_position
	controller.update(world, player, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"), 0.5)
	_expect(not controller.current_prompt().is_empty(), "current rejection disappeared immediately after pushback")
	controller.update(world, player, Callable(self, "_has_no_upgrade"), Callable(profile, "has_capability"), 1.1)
	_expect(controller.current_prompt().is_empty(), "current rejection did not clear after its readability hold")
	player.global_position = standard_gate["center"]
	var propulsion_blocked: Dictionary = controller.update(
		world,
		player,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		0.0
	)
	_expect(bool(propulsion_blocked.get("blocked", false)), "propulsion gate allowed passage before fins project")

	_build_projects(world, profile)
	controller.reset()
	player.global_position = advanced_gate["center"]
	var unlocked: Dictionary = controller.update(
		world,
		player,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		0.25
	)
	_expect(bool(unlocked.get("inside", false)) and not bool(unlocked.get("blocked", true)), "durable gate stayed blocked after stabilizer")
	_expect(player.global_position == advanced_gate["center"], "unlocked advanced gate still moved player")
	_expect(profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID), "controller reset removed durable capability")

	player.global_position = standard_gate["center"]
	var propulsion_unlocked: Dictionary = controller.update(
		world,
		player,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		0.0
	)
	_expect(not bool(propulsion_unlocked.get("blocked", true)), "recipe-built propulsion fins did not unlock gate")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") == "loaded", "stabilizer profile did not reload")
	player.global_position = advanced_gate["center"]
	var after_reload: Dictionary = CurrentGateController.new().update(
		world,
		player,
		Callable(self, "_has_no_upgrade"),
		Callable(reloaded, "has_capability"),
		0.25
	)
	_expect(not bool(after_reload.get("blocked", true)), "profile reload lost durable gate access")

	player.queue_free()
	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Current stabilizer gate state smoke failed: %s" % failure)
		quit(1)
		return
	print("Current stabilizer gate state smoke passed: standard_gate=propulsion_fins advanced_gate=current_stabilizer blocked_push=authored passive_after_unlock=true prompt_hold=true reset_persistent=true reload_persistent=true.")
	quit(0)


func _build_projects(world, profile) -> void:
	profile.complete_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID, false)
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, false)
	profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 6,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
		ExpansionProfileState.COIL_MATERIAL_ID: 2,
	}, false)
	for project in world.get_material_projects():
		var project_id := str(project.get("id", ""))
		if project_id not in [ExpansionProfileState.PROPULSION_FINS_PROJECT_ID, ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID, ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID]:
			continue
		var result: Dictionary = profile.complete_material_project(project, true)
		_expect(bool(result.get("changed", false)), "project %s did not complete: %s" % [project_id, str(result)])


func _gate_by_id(world, gate_id: String) -> Dictionary:
	for gate in world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
