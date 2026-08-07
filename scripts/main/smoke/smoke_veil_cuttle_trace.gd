extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CUTTLE_SCENE := preload("res://scenes/companion/VeilCuttleCompanion.tscn")
const VeilCuttleControlRuntime := preload("res://scripts/companion/veil_cuttle_control_runtime.gd")
const MovingHazardController := preload("res://scripts/main/moving_hazard_controller.gd")
const ScannerSubjectCatalog := preload("res://scripts/main/scanner_subject_catalog.gd")
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const TRACE_ID := "southwest_bloom_migration_trace"
const TRACE_SCAN_ID := "identify_ecological_trace_southwest_bloom_migration_trace"
const CONDITION_ID := "southwest_jellyfish_bloom"
const HAZARD_ID := "southwest_bloom_jellyfish_patrol"

var _failures: Array[String] = []
var _status_notes: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	player.global_position = world.spawn_position
	var cuttle := CUTTLE_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(cuttle)
	cuttle.configure(world, player, Callable(), {
		"individual_id": "veil_cuttle_juvenile_01",
		"species_id": "veil_cuttle",
		"callsign": "Mica",
	})
	cuttle.set_physics_process(false)
	var control := VeilCuttleControlRuntime.new()
	get_root().add_child(control)
	var moving_hazards := MovingHazardController.new()
	moving_hazards.reset(world, [CONDITION_ID])
	control.bind_interface(Callable(self, "_record_status"), Callable(self, "_control_allowed"))
	control.bind_map(world, player, cuttle, moving_hazards)
	await physics_frame

	var trace := _trace_by_id(world, TRACE_ID)
	_expect(not trace.is_empty(), "authored Veil Cuttle trace was unavailable to the runtime")
	_expect(str(trace.get("state", "")) == "hidden", "authored trace did not begin hidden")
	_expect(not _trace_marker(world).visible, "hidden trace marker was visible")
	_expect(world.get_node_or_null("Markers/veil_cuttle_rescue_01/VeilCuttleMantle") != null, "Mica rescue retained the Spark Ray silhouette")
	_expect(world.get_node_or_null("Markers/spark_ray_rescue_01/JuvenileBody") != null, "species-specific Mica art changed the Spark Ray rescue")
	_expect(not _subject_ids(world).has(TRACE_SCAN_ID), "scanner catalog exposed the trace before Mica revealed it")

	_test_palette_and_range_miss(world, control)
	_test_deliberate_reveal(world, player, cuttle, control)
	_finish(world, player, cuttle, control)


func _test_palette_and_range_miss(world, control) -> void:
	var before_time_scale := Engine.time_scale
	var open_report: Dictionary = control.begin_command_mode()
	var commands: Array = open_report.get("context_commands", [])
	var ids := _command_ids(commands)
	_expect(ids == ["recall", "reveal_trace"], "Mica BOND palette drifted: %s" % [ids])
	_expect(not ids.has("mount") and not ids.has("dismount"), "Mica BOND palette exposed riding")
	_expect(is_equal_approx(Engine.time_scale, 0.2), "Mica BOND mode did not use shared slow time")
	_expect(bool(open_report.get("palette", {}).get("visible", false)), "Mica BOND palette was not visible")
	control.cycle_context_command()
	var miss: Dictionary = control.confirm_context_command()
	_expect(str(miss.get("reason", "")) == "out_of_range", "out-of-range Reveal Trace did not report its bounded range")
	_expect(str(_trace_by_id(world, TRACE_ID).get("state", "")) == "hidden", "range miss revealed the trace")
	_expect(is_equal_approx(Engine.time_scale, before_time_scale), "closing Mica BOND mode did not restore time")


func _test_deliberate_reveal(world, player, cuttle, control) -> void:
	var trace := _trace_by_id(world, TRACE_ID)
	var center: Vector2 = trace.get("center", Vector2.ZERO)
	cuttle.global_position = center + Vector2(-48.0, 0.0)
	player.global_position = cuttle.global_position + Vector2(-24.0, 0.0)
	cuttle.advance(0.0)
	var open_report: Dictionary = control.begin_command_mode()
	var commands: Array = open_report.get("context_commands", [])
	_expect(commands.size() > 1 and str((commands[1] as Dictionary).get("id", "")) == "reveal_trace", "number 2 did not map to Reveal Trace")
	_expect(str(open_report.get("palette", {}).get("commands", [])[1].get("label", "")) == "Reveal Trace", "palette did not label number 2 as Reveal Trace")
	_expect(control.handle_input(_action(&"companion_action_2")), "number 2 did not dispatch Reveal Trace")
	var result: Dictionary = control.trace_runtime().report().get("last_result", {})
	_expect(bool(result.get("changed", false)) and str(result.get("reason", "")) == "revealed", "deliberate Reveal Trace did not reveal its authored target")
	_expect(str(result.get("target_id", "")) == TRACE_ID, "Reveal Trace affected an unexpected target")
	_expect(not bool(result.get("identified", true)), "Mica identified the trace without the scanner")
	_expect((result.get("reward_ids", []) as Array).is_empty(), "Reveal Trace granted a reward")
	_expect(str(result.get("progression_effect", "")) == "none", "Reveal Trace changed progression")
	_expect(not bool(result.get("gate_access_changed", true)), "Reveal Trace changed equipment-gate access")
	_expect(str(_trace_by_id(world, TRACE_ID).get("state", "")) == "revealed", "trace runtime state did not retain the reveal")
	_expect(_trace_marker(world).visible, "revealed trace marker remained concealed")
	var migration_line := _trace_marker(world).get_node("MigrationPath") as Line2D
	var linked_hazard := _hazard_by_id(world, HAZARD_ID)
	_expect(migration_line.points.size() == (linked_hazard.get("path", []) as Array).size(), "revealed trace did not draw the linked patrol path")
	if migration_line.points.size() >= 2:
		var first_world_point: Vector2 = migration_line.points[0] + center
		_expect(first_world_point.is_equal_approx(linked_hazard.get("path", [Vector2.ZERO])[0]), "migration path projection drifted from linked hazard source")
	_expect(_subject_ids(world).has(TRACE_SCAN_ID), "scanner catalog did not expose the revealed trace for identification")
	var presentation: Dictionary = cuttle.report().get("presentation", {})
	_expect(str(presentation.get("trace_state", "")) == "revealed", "Mica did not show readable Reveal Trace result feedback")
	_expect(int(presentation.get("trace_path_point_count", 0)) >= 2, "Mica retained the generic Reveal Trace ring instead of the linked trail")
	_expect(float(presentation.get("trace_range_px", 0.0)) == float(trace.get("reveal_radius_tiles", 0.0)) * float(world.tile_size), "Reveal Trace presentation range drifted from source")
	_expect(_status_notes.has("Mica revealed an ecological trace | Scanner required"), "Reveal Trace omitted scanner-required feedback")


func _trace_by_id(world, trace_id: String) -> Dictionary:
	for trace in world.get_ecological_traces():
		if str(trace.get("id", "")) == trace_id:
			return trace
	return {}


func _trace_marker(world) -> CanvasItem:
	return world.get_node("Markers/%s" % TRACE_ID) as CanvasItem


func _hazard_by_id(world, hazard_id: String) -> Dictionary:
	for hazard in world.get_moving_hazards():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _subject_ids(world) -> Array[String]:
	var ids: Array[String] = []
	for subject in ScannerSubjectCatalog.new().subjects(world, "identify"):
		ids.append(str(subject.get("id", "")))
	return ids


func _command_ids(commands: Array) -> Array[String]:
	var ids: Array[String] = []
	for command in commands:
		ids.append(str((command as Dictionary).get("id", "")))
	return ids


func _record_status(note: String) -> void:
	_status_notes.append(note)


func _action(action: StringName, pressed := true) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _control_allowed() -> bool:
	return true


func _finish(world, player, cuttle, control) -> void:
	control.clear_map()
	control.queue_free()
	cuttle.queue_free()
	player.queue_free()
	world.queue_free()
	Engine.time_scale = 1.0
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Veil Cuttle trace smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Veil Cuttle BOND commands=recall,reveal_trace mount=false range=source trail=linked_patrol_path generic_ring=false direction=visible result=visible authored_target=1 scanner_required=true reward=false progression=false gate_bypass=false.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
