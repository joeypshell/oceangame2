extends RefCounted

const CompanionAnchorFinsRuntime := preload("res://scripts/companion/companion_anchor_fins_runtime.gd")
const CompanionGuardianPulseRuntime := preload("res://scripts/companion/companion_guardian_pulse_runtime.gd")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const LivingExpedition01CaptureRenderer := preload("res://scripts/main/captures/living_expedition_01_capture_renderer.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const RESCUE_ID := "spark_ray_rescue_01"
const BOAT_ENTRY_ID := "surface_boat_entry"
const FLOW_GATE_ID := "lower_right_west_current_gate"
const ANCHOR_GATE_ID := "lower_right_east_current_gate"
const HOSTILE_ID := "deep_cache_territorial_eel"
const CAPTURE_STATES := [
	{"id": "rescue", "camera": "living_expedition_01_rescue"},
	{"id": "follow", "camera": "living_expedition_01_follow"},
	{"id": "command_palette", "camera": "living_expedition_01_mounted_route"},
	{"id": "base_riding", "camera": "living_expedition_01_mounted_route"},
	{"id": "held_the_flow", "camera": "living_expedition_01_held_the_flow"},
	{"id": "stood_ground", "camera": "living_expedition_01_stood_ground"},
	{"id": "night_choice", "camera": "living_expedition_01_night_choice"},
	{"id": "anchor_independent", "camera": "living_expedition_01_anchor_payoff"},
	{"id": "anchor_mounted", "camera": "living_expedition_01_anchor_payoff"},
	{"id": "guardian_independent", "camera": "living_expedition_01_guardian_payoff"},
	{"id": "guardian_mounted", "camera": "living_expedition_01_guardian_payoff"},
]

var _main
var _renderer


class HostileFixture:
	extends RefCounted
	var state := {}

	func state_for(_hostile_id: String) -> Dictionary:
		return state.duplicate(true)


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_main():
		return
	_renderer = LivingExpedition01CaptureRenderer.new(_main)
	if not _prepare_rescue() or not await _capture(capture_dir, "rescue"):
		return
	if not _complete_rescue_for_follow() or not await _capture(capture_dir, "follow"):
		return
	if not _commit_and_launch_day_two():
		return
	if not _prepare_command_palette() or not await _capture(capture_dir, "command_palette", "palette"):
		return
	if not _prepare_base_riding() or not await _capture(capture_dir, "base_riding", "action_hud"):
		return
	if not _prepare_flow_memory() or not await _capture(capture_dir, "held_the_flow"):
		return
	if not _prepare_ground_memory() or not await _capture(capture_dir, "stood_ground"):
		return
	if not _prepare_night_choice() or not await _capture(capture_dir, "night_choice"):
		return
	if not _prepare_anchor(false) or not await _capture(capture_dir, "anchor_independent"):
		return
	if not _prepare_anchor(true) or not await _capture(capture_dir, "anchor_mounted", "action_hud"):
		return
	if not _reset_for_guardian_branch():
		return
	if not _prepare_guardian(false) or not await _capture(capture_dir, "guardian_independent"):
		return
	if not _prepare_guardian(true) or not await _capture(capture_dir, "guardian_mounted", "action_hud"):
		return
	if not _write_manifest(capture_dir):
		return
	print("Saved Living Expedition 01 captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_main() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_level_01":
		return _fail("requires production_level_01")
	if (
		_main._review_checkpoint_id != ReviewCheckpointFixture.LIVING_EXPEDITION_01_START
		or not bool(_main._review_checkpoint_report.get("ready", false))
	):
		return _fail("requires the isolated living_expedition_01_start checkpoint")
	_disable_live_processing()
	return true


func _prepare_rescue() -> bool:
	var rescue := _rescue()
	if rescue.is_empty():
		return _fail("source-authored Spark Ray rescue is unavailable")
	_main._player.global_position = rescue.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	_main._last_status_note = ""
	if not _select_tool("salvage_cutter"):
		return false
	_main._update_status_label()
	return _expect(_main._companion_rescue.prompt().find("Hold Space/USE") != -1, "rescue did not present deliberate Cutter aid")


func _complete_rescue_for_follow() -> bool:
	var used: Dictionary = _main._active_tool_runtime.use()
	if str(used.get("status", "")) != "used":
		return _fail("Cutter did not begin the rescue: %s" % str(used))
	_main._companion_rescue.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	_main._active_tool_runtime.release_use()
	var ray = _main._companion_rescue.pending_companion()
	if ray == null:
		return _fail("completed rescue did not create a return companion")
	ray.set_physics_process(false)
	var focus := _camera_world_position("living_expedition_01_follow")
	_place_pair(_main._player, ray, focus)
	_main._player.global_position += Vector2(88.0, 0.0)
	ray.advance(0.0)
	_main._last_status_note = "Kite freed | Return together to the surface boat"
	_main._update_status_label()
	return true


func _commit_and_launch_day_two() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._cargo_collection.update(0.0)
	if not _main._anomaly_survey.profile_state().has_committed_companion():
		return _fail("canonical boat did not commit the rescued Spark Ray")
	_main._expedition_day_state.begin_next_day()
	_main._player.global_position += Vector2(100.0, 80.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	_main._companion_sortie.sync_spawn()
	var ray = _main._companion_sortie.companion()
	if ray == null:
		return _fail("following sortie did not unlock the committed bond")
	_disable_companion(ray)
	return true


func _prepare_command_palette() -> bool:
	var ray = _main._companion_sortie.companion()
	_place_pair(_main._player, ray, _camera_world_position("living_expedition_01_mounted_route"))
	var opened: Dictionary = _main._companion_sortie.control_runtime().begin_command_mode()
	_main._last_status_note = "Hold BOND | Choose how Kite helps"
	_main._update_status_label()
	return _expect(
		is_equal_approx(Engine.time_scale, 0.2)
		and (opened.get("context_commands", []) as Array).size() <= 3,
		"command palette did not own bounded slow time"
	)


func _prepare_base_riding() -> bool:
	var control = _main._companion_sortie.control_runtime()
	control.end_command_mode()
	if not bool(control.request_mount().get("changed", false)):
		return _fail("base riding could not mount")
	control.activate_mounted_action()
	_main._last_status_note = "Mounted with Kite | Glide Surge"
	_main._update_status_label()
	return _expect(control.report().get("selected_action_id") == "glide_surge", "base mounted hotbar omitted Glide Surge")


func _prepare_flow_memory() -> bool:
	var control = _main._companion_sortie.control_runtime()
	control.request_dismount()
	var ray = _main._companion_sortie.companion()
	var gate := _gate_by_id(FLOW_GATE_ID)
	var rect: Rect2 = gate.get("rect", Rect2())
	var push := _direction_vector(str(gate.get("current_direction", "")))
	var half_span := rect.size.x * 0.5 if absf(push.x) > 0.0 else rect.size.y * 0.5
	var entry := rect.get_center() + push * (half_span + 12.0)
	var exit := rect.get_center() - push * (half_span + 12.0)
	_place_pair(_main._player, ray, entry)
	_main._companion_sortie.observe_current({})
	_place_pair(_main._player, ray, rect.get_center())
	_main._companion_sortie.observe_current({"inside": true, "blocked": false, "id": FLOW_GATE_ID})
	_place_pair(_main._player, ray, exit)
	var result: Dictionary = _main._companion_sortie.observe_current({})
	ray.show_context_response("memory", rect.get_center())
	_main._last_status_note = str(result.get("note", "Kite remembered: Held the Flow"))
	_main._update_status_label()
	return _expect(result.get("memory_id") == "held_the_flow", "current crossing did not qualify Held the Flow")


func _prepare_ground_memory() -> bool:
	var ray = _main._companion_sortie.companion()
	var hostiles := HostileFixture.new()
	var territory := Rect2(_camera_world_position("living_expedition_01_stood_ground") - Vector2(120.0, 90.0), Vector2(240.0, 180.0))
	_place_pair(_main._player, ray, territory.get_center())
	hostiles.state = {"id": HOSTILE_ID, "phase": "warning", "territory_rect": territory}
	_main._companion_sortie.observe_hostiles(hostiles, {"id": HOSTILE_ID, "kind": "warning"})
	hostiles.state["phase"] = "lunge"
	_main._companion_sortie.observe_hostiles(hostiles, {"id": HOSTILE_ID, "kind": "lunge"})
	var result: Dictionary = _main._companion_sortie.observe_hostiles(hostiles, {"id": HOSTILE_ID, "kind": "contact"})
	ray.show_context_response("memory", territory.get_center() + Vector2.RIGHT * 70.0)
	_main._last_status_note = str(result.get("note", "Kite remembered: Stood Ground"))
	_main._update_status_label()
	return _expect(result.get("memory_id") == "stood_ground", "territorial cycle did not qualify Stood Ground")


func _prepare_night_choice() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	var committed: Dictionary = _main._companion_sortie.commit_memories_at_boat()
	if not bool(committed.get("changed", false)):
		return _fail("boat did not secure both memories")
	_main._expedition_day_state.request_end_day("voluntary")
	ExpeditionDayDebrief.update(_main, 0.0)
	return _expect(
		_main._companion_sortie.requires_adaptation_selection()
		and _main._result_label.text.find("Anchor Fins") != -1
		and _main._result_label.text.find("Guardian Pulse") != -1,
		"night choice did not compare both earned adaptations"
	)


func _prepare_anchor(mounted: bool) -> bool:
	if _main._expedition_day_state.phase == "debrief":
		var use := InputEventAction.new()
		use.action = "active_tool_use"
		use.pressed = true
		var selected: Dictionary = ExpeditionDayDebrief.handle_debrief_input(_main, use)
		if selected.get("adaptation_id") != "anchor_fins":
			return _fail("night did not select Anchor Fins")
		_begin_day_three()
	var ray = _main._companion_sortie.companion()
	var gate := _gate_by_id(ANCHOR_GATE_ID)
	_place_pair(_main._player, ray, gate.get("center", Vector2.ZERO))
	var runtime = _main._companion_sortie.adaptation_runtime()
	runtime.reset("capture_role")
	var role := "mounted" if mounted else "independent"
	if mounted:
		var control = _main._companion_sortie.control_runtime()
		if not control.is_mounted() and not bool(control.request_mount().get("changed", false)):
			return _fail("Anchor Fins mounted capture could not mount")
		if not _select_mounted_action(CompanionAnchorFinsRuntime.ACTION_ID):
			return false
		control.activate_mounted_action()
	else:
		_main._companion_sortie.control_runtime().request_dismount()
		runtime.dispatch(role, CompanionAnchorFinsRuntime.ACTION_ID)
	runtime.advance(0.65, mounted)
	_main._last_status_note = "Kite braces the current | %s" % role
	_main._update_status_label()
	return _expect(float(runtime.report().get("progress", 0.0)) > 0.3, "Anchor Fins capture omitted visible progress")


func _reset_for_guardian_branch() -> bool:
	Engine.time_scale = 1.0
	var profile = _main._anomaly_survey.profile_state()
	profile.load_profile()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.LIVING_EXPEDITION_01_START, profile)
	if not bool(applied.get("ready", false)):
		return _fail("could not reset isolated Guardian branch")
	profile.commit_companion_rescue("spark_ray_juvenile_01", "spark_ray", "Kite", false)
	profile.earn_companion_memory("stood_ground", false)
	profile.select_companion_adaptation("guardian_pulse", false)
	_main._expedition_day_state.begin_day(3)
	_main._load_playable_map(_main.PRODUCTION_LEVEL_MAP_PATH, false, BOAT_ENTRY_ID, "Guardian Pulse branch")
	_disable_live_processing()
	_main._player.global_position += Vector2(100.0, 80.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	_main._companion_sortie.sync_spawn()
	var ray = _main._companion_sortie.companion()
	if ray == null:
		return _fail("Guardian branch did not spawn Kite")
	_disable_companion(ray)
	return true


func _prepare_guardian(mounted: bool) -> bool:
	var ray = _main._companion_sortie.companion()
	var runtime = _main._companion_sortie.guardian_pulse_runtime()
	runtime.reset("capture_role")
	_main._hostiles.reset_for_failure(_main._world)
	var home: Vector2 = _main._hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	_place_pair(_main._player, ray, home + Vector2(-100.0, 0.0))
	_main._hostiles.update(_main._world, _main._player.global_position, 0.0)
	var role := "mounted" if mounted else "independent"
	if mounted:
		var control = _main._companion_sortie.control_runtime()
		if not control.is_mounted() and not bool(control.request_mount().get("changed", false)):
			return _fail("Guardian Pulse mounted capture could not mount")
		if not _select_mounted_action(CompanionGuardianPulseRuntime.ACTION_ID):
			return false
		control.activate_mounted_action()
	else:
		_main._companion_sortie.control_runtime().request_dismount()
		runtime.dispatch(role, CompanionGuardianPulseRuntime.ACTION_ID)
	runtime.advance(0.2, mounted)
	_main._last_status_note = "Kite charges Guardian Pulse | %s" % role
	_main._update_status_label()
	return _expect(float(runtime.report().get("progress", 0.0)) > 0.35, "Guardian Pulse capture omitted visible charge")


func _begin_day_three() -> void:
	_main._companion_sortie.end_debrief()
	_main._expedition_day_state.begin_next_day()
	_main._load_playable_map(_main.PRODUCTION_LEVEL_MAP_PATH, false, BOAT_ENTRY_ID, "Kite adapted")
	_disable_live_processing()
	_main._player.global_position += Vector2(100.0, 80.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	_main._companion_sortie.sync_spawn()
	_disable_companion(_main._companion_sortie.companion())


func _disable_live_processing() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _disable_companion(ray) -> void:
	if ray == null:
		return
	ray.set_physics_process(false)
	_main._companion_sortie.set_process(false)
	var control = _main._companion_sortie.control_runtime()
	control.set_process(false)
	control.set_physics_process(false)


func _place_pair(player, ray, position: Vector2) -> void:
	ray.set_external_control_active(true)
	ray.global_position = position
	player.global_position = position
	ray.set_external_control_active(false)
	ray.advance(0.0)


func _capture(capture_dir: String, state_id: String, expected_ui := "") -> bool:
	var camera_test := _camera_test(_state_camera(state_id))
	if camera_test.is_empty():
		return _fail("missing authored camera for %s" % state_id)
	return await _renderer.capture_pair(capture_dir, state_id, camera_test, expected_ui)


func _state_camera(state_id: String) -> String:
	for state in CAPTURE_STATES:
		if str(state.get("id", "")) == state_id:
			return str(state.get("camera", ""))
	return ""


func _camera_test(camera_id: String) -> Dictionary:
	for camera_test in _main._world.camera_tests:
		if str(camera_test.get("id", "")) == camera_id:
			return camera_test
	return {}


func _camera_world_position(camera_id: String) -> Vector2:
	var camera := _camera_test(camera_id)
	return Vector2(float(camera.get("center_x", 0.0)), float(camera.get("center_y", 0.0))) * float(_main._world.tile_size)


func _rescue() -> Dictionary:
	for rescue in _main._world.get_creature_rescues():
		if str(rescue.get("id", "")) == RESCUE_ID:
			return rescue
	return {}


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _main._world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _step in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	return _fail("could not select %s" % tool_id)


func _select_mounted_action(action_id: String) -> bool:
	var control = _main._companion_sortie.control_runtime()
	for _step in range(3):
		if control.report().get("selected_action_id") == action_id:
			return true
		control.cycle_mounted_action()
	return _fail("mounted hotbar omitted %s" % action_id)


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
	return Vector2.ZERO


func _write_manifest(capture_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var file := FileAccess.open("%s/capture_manifest.json" % capture_dir, FileAccess.WRITE)
	if file == null:
		return _fail("could not write capture manifest")
	file.store_string(JSON.stringify({
		"capture_runner": "res://scripts/main/captures/living_expedition_01_capture_runner.gd",
		"review_checkpoint": ReviewCheckpointFixture.LIVING_EXPEDITION_01_START,
		"baseline_accepted": false,
		"states": CAPTURE_STATES,
		"sizes": ["1280x720", "mobile_844x390"],
		"controls": "Shift/BOND + Tab/TOOL + Space/USE",
	}, "  ") + "\n")
	file.close()
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 01 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
