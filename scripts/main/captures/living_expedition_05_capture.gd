extends RefCounted

const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const LivingExpedition05CaptureRenderer := preload("res://scripts/main/captures/living_expedition_05_capture_renderer.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const BOAT_ENTRY_ID := "surface_boat_entry"
const MARL_ID := "silt_hound_juvenile_01"
const RESCUE_ID := "silt_hound_rescue_01"
const TARGET_ID := "silt_hound_buried_titanium_01"
const MATERIAL_ID := "titanium_scrap"
const RESCUE_CAMERA_ID := "living_expedition_05_rescue_review_01"
const EXCAVATE_CAMERA_ID := "living_expedition_05_excavate_review_01"
const STEP_SECONDS := 1.0 / 30.0
const CAPTURE_STATES := [
	{"id": "rescue_cutting", "camera": RESCUE_CAMERA_ID},
	{"id": "pending_boat_return", "camera": RESCUE_CAMERA_ID},
	{"id": "three_partner_selection", "camera": RESCUE_CAMERA_ID},
	{"id": "marl_following", "camera": RESCUE_CAMERA_ID},
	{"id": "excavate_command", "camera": EXCAVATE_CAMERA_ID},
	{"id": "excavate_anticipation", "camera": EXCAVATE_CAMERA_ID},
	{"id": "excavate_impact", "camera": EXCAVATE_CAMERA_ID},
	{"id": "deposit_opened", "camera": EXCAVATE_CAMERA_ID},
	{"id": "cargo_full_preserved", "camera": EXCAVATE_CAMERA_ID},
	{"id": "titanium_held", "camera": EXCAVATE_CAMERA_ID},
]

var _main
var _renderer
var _positions := {}


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_main():
		return
	_renderer = LivingExpedition05CaptureRenderer.new(_main)
	if not _prepare_rescue_cutting() or not await _capture(capture_dir, "rescue_cutting", "rescue_cutting"):
		return
	if not _complete_rescue() or not await _capture(capture_dir, "pending_boat_return", "pending_return"):
		return
	if not _commit_and_open_habitat() or not await _capture(capture_dir, "three_partner_selection", "habitat"):
		return
	if not _confirm_marl_and_launch() or not await _capture(capture_dir, "marl_following", "following"):
		return
	if not _prepare_excavate_command() or not await _capture(capture_dir, "excavate_command", "command"):
		return
	if not _start_excavate() or not _advance_excavate_to("anticipating") or not await _capture(capture_dir, "excavate_anticipation", "anticipating"):
		return
	if not _advance_excavate_to("impact") or not await _capture(capture_dir, "excavate_impact", "impact"):
		return
	if not _advance_excavate_to("revealed") or not await _capture(capture_dir, "deposit_opened", "opened"):
		return
	if not _prepare_cargo_full() or not await _capture(capture_dir, "cargo_full_preserved", "cargo_full"):
		return
	if not _collect_titanium() or not await _capture(capture_dir, "titanium_held", "material_held"):
		return
	if not _write_manifest(capture_dir):
		return
	print("Saved Living Expedition 05 captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_main() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_level_01":
		return _fail("requires production_level_01")
	if (
		_main._review_checkpoint_id != ReviewCheckpointFixture.LIVING_EXPEDITION_05_START
		or not bool(_main._review_checkpoint_report.get("ready", false))
	):
		return _fail("requires the isolated living_expedition_05_start checkpoint")
	_disable_live_processing()
	var profile = _main._anomaly_survey.profile_state()
	var companions: Dictionary = profile.companion_report()
	var source: Dictionary = _main._world.get_material_candidate_state(TARGET_ID)
	return _expect(
		int(_main._expedition_day_state.day_number) == 4
		and (companions.get("individuals", []) as Array).size() == 2
		and not _has_individual(companions, MARL_ID)
		and bool(source.get("active", false))
		and bool(source.get("buried", false))
		and not bool(source.get("revealed", true)),
		"checkpoint did not begin with two partners and one closed active mound"
	)


func _prepare_rescue_cutting() -> bool:
	var rescue := _rescue()
	if rescue.is_empty():
		return _fail("source-authored Marl rescue is unavailable")
	_main._player.global_position = rescue.get("center", Vector2.ZERO) + Vector2(-26.0, 0.0)
	_main._player.reset_motion()
	if not _select_tool("salvage_cutter"):
		return false
	var started: Dictionary = _main._active_tool_runtime.use()
	if str(started.get("status", "")) != "used":
		return _fail("Cutter did not begin Marl's rescue: %s" % str(started))
	var progress: Dictionary = _main._companion_rescue.update(CompanionRescueRuntime.RELEASE_SECONDS * 0.5)
	_main._last_status_note = str(progress.get("note", "Freeing Marl"))
	_main._update_status_label()
	var report: Dictionary = _main._companion_rescue.report()
	return _expect(
		str(progress.get("state", "")) == "releasing"
		and float(report.get("release_progress", 0.0)) > 0.0
		and float(report.get("release_progress", 1.0)) < 1.0,
		"rescue capture did not hold a partial Cutter release"
	)


func _complete_rescue() -> bool:
	var released: Dictionary = _main._companion_rescue.update(CompanionRescueRuntime.RELEASE_SECONDS)
	_main._active_tool_runtime.release_use()
	if str(released.get("reason", "")) != "released":
		return _fail("Marl rescue did not reach pending: %s" % str(released))
	var marl = _main._companion_rescue.pending_companion()
	if marl == null:
		return _fail("pending rescue did not spawn Marl")
	_disable_companion(marl)
	var center: Vector2 = _rescue().get("center", _main._player.global_position)
	_main._player.global_position = center + Vector2(-52.0, 8.0)
	marl.global_position = center + Vector2(34.0, -8.0)
	marl.advance(0.0)
	_main._last_status_note = str(released.get("note", "Marl is free - return to the boat"))
	_main._update_status_label()
	return _expect(
		str(_main._companion_rescue.report().get("pending_rescue_id", "")) == RESCUE_ID,
		"pending return did not retain the rescue id"
	)


func _commit_and_open_habitat() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	var committed: Dictionary = _main._companion_rescue.commit_at_boat()
	if not bool(committed.get("changed", false)):
		return _fail("canonical boat did not commit Marl: %s" % str(committed))
	_main._companion_sortie._habitat.sync_presence()
	_main._last_status_note = str(committed.get("note", "Marl bonded"))
	_main._update_status_label()
	if not _main._companion_sortie.handle_input(_action(&"companion_command")):
		return _fail("BOND did not open the three-partner habitat")
	var individuals: Array = _main._anomaly_survey.profile_state().companion_report().get("individuals", [])
	for _step in range(individuals.size()):
		var habitat: Dictionary = _main._companion_sortie.report().get("habitat", {})
		var highlighted := int(habitat.get("highlighted_index", 0))
		if str((individuals[highlighted] as Dictionary).get("individual_id", "")) == MARL_ID:
			break
		_main._companion_sortie.handle_input(_action(&"active_tool_cycle_next"))
	_main._update_status_label()
	var report: Dictionary = _main._companion_sortie.report().get("habitat", {})
	return _expect(
		int(report.get("individual_count", 0)) == 3
		and bool(report.get("selection_open", false))
		and _highlighted_individual(report) == MARL_ID,
		"habitat did not expose three rows with Marl highlighted"
	)


func _confirm_marl_and_launch() -> bool:
	if not _main._companion_sortie.handle_input(_action(&"active_tool_use")):
		return _fail("USE did not confirm Marl")
	var focus := _camera_world_position(RESCUE_CAMERA_ID)
	_main._player.global_position = focus + Vector2(34.0, -8.0)
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	var launched: Dictionary = _main._companion_sortie.sync_spawn()
	var marl = _main._companion_sortie.companion()
	if str(launched.get("active_species_id", "")) != "silt_hound" or marl == null:
		return _fail("selected Marl did not launch")
	_disable_companion(marl)
	marl.global_position = focus + Vector2(-42.0, 18.0)
	marl.advance(0.0)
	_main._last_status_note = "Marl active | Six-fin excavation partner | Press B for commands"
	_main._update_status_label()
	return _expect(
		str(marl.report().get("identity", {}).get("individual_id", "")) == MARL_ID,
		"follow capture launched the wrong individual"
	)


func _prepare_excavate_command() -> bool:
	var target := _target_center()
	_positions = _action_positions(target)
	_set_action_positions()
	var control = _main._companion_sortie.control_runtime()
	var opened: Dictionary = control.begin_command_mode()
	if not bool(opened.get("command_mode", false)):
		return _fail("BOND did not open Marl's command palette")
	for _step in range(3):
		if _selected_command_id(control) == "excavate":
			break
		control.cycle_context_command()
	_main._last_status_note = "BOND | Excavate selected | USE sends Marl to the mound"
	_main._update_status_label()
	return _expect(_selected_command_id(control) == "excavate", "Excavate was not selected in the BOND palette")


func _start_excavate() -> bool:
	var result: Dictionary = _main._companion_sortie.control_runtime().confirm_context_command()
	return _expect(
		bool(result.get("changed", false)) and str(result.get("reason", "")) == "started" and not _main.get_tree().paused,
		"Excavate did not start from the selected BOND command"
	)


func _advance_excavate_to(target_state: String) -> bool:
	var marl = _main._companion_sortie.companion()
	var excavation = _main._companion_sortie.control_runtime().excavate_runtime()
	for _index in range(420):
		marl.advance(STEP_SECONDS)
		excavation.advance(STEP_SECONDS)
		if str(excavation.report().get("state", "")) == target_state:
			_main._update_status_label()
			return true
	return _fail("Excavate did not reach %s: %s" % [target_state, str(excavation.report())])


func _prepare_cargo_full() -> bool:
	var capacity: int = int(_main._held_salvage_capacity())
	while _main._sortie_state.held_salvage < capacity:
		_main._sortie_state.collect_salvage("capture_full_%d" % _main._sortie_state.held_salvage, 0)
	var result: Dictionary = _main._material_runtime.update_collection(
		_main._world,
		_target_center(),
		_main.SALVAGE_COLLECTION_RADIUS,
		_main._expedition_day_state,
		_main._sortie_state.held_salvage,
		capacity
	)
	_main._last_status_note = str(result.get("note", "Cargo full - titanium remains exposed"))
	_main._update_status_label()
	return _expect(
		bool(result.get("blocked", false))
		and bool(_main._world.get_material_candidate_state(TARGET_ID).get("available", false)),
		"cargo-full capture deleted or collected the exposed titanium"
	)


func _collect_titanium() -> bool:
	_main._sortie_state.clear_held()
	var result: Dictionary = _main._material_runtime.update_collection(
		_main._world,
		_target_center(),
		_main.SALVAGE_COLLECTION_RADIUS,
		_main._expedition_day_state,
		0,
		_main._held_salvage_capacity()
	)
	_main._last_status_note = str(result.get("note", "Titanium scrap held - return to boat"))
	_main._update_status_label()
	return _expect(
		bool(result.get("changed", false))
		and int(_main._material_runtime.held_quantities().get(MATERIAL_ID, 0)) == 1
		and bool(_main._world.get_material_candidate_state(TARGET_ID).get("depleted", false)),
		"successful pickup did not move exactly one titanium into held cargo"
	)


func _capture(capture_dir: String, state_id: String, kind: String) -> bool:
	var camera_test := _camera_test(_state_camera(state_id))
	if camera_test.is_empty():
		return _fail("missing authored camera for %s" % state_id)
	return await _renderer.capture_pair(capture_dir, state_id, camera_test, {"kind": kind})


func _set_action_positions() -> void:
	_main._player.global_position = _positions.get("player", _target_center())
	var marl = _main._companion_sortie.companion()
	marl.global_position = _positions.get("companion", _target_center())
	marl.advance(0.0)


func _action_positions(target: Vector2) -> Dictionary:
	var points: Array[Vector2] = []
	for radius in [48.0, 64.0, 80.0, 96.0]:
		for index in range(16):
			var candidate := target + Vector2.from_angle(float(index) / 16.0 * TAU) * float(radius)
			if _main._world.find_open_path(candidate, candidate).is_empty() or not _main._world.has_clear_terrain_line(candidate, target):
				continue
			points.append(candidate)
			if points.size() >= 2:
				return {"player": points[0], "companion": points[1]}
	return {"player": target, "companion": target}


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _step in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	return _fail("could not select %s" % tool_id)


func _selected_command_id(control) -> String:
	var report: Dictionary = control.report()
	var commands: Array = report.get("context_commands", [])
	var index := int(report.get("selected_command_index", 0))
	return str((commands[index] as Dictionary).get("id", "")) if index >= 0 and index < commands.size() else ""


func _highlighted_individual(habitat: Dictionary) -> String:
	var rows: Array = habitat.get("panel", {}).get("rows", [])
	var index := int(habitat.get("highlighted_index", -1))
	return str((rows[index] as Dictionary).get("individual_id", "")) if index >= 0 and index < rows.size() else ""


func _has_individual(report: Dictionary, individual_id: String) -> bool:
	return (report.get("individuals", []) as Array).any(func(value): return str((value as Dictionary).get("individual_id", "")) == individual_id)


func _rescue() -> Dictionary:
	for rescue in _main._world.get_creature_rescues():
		if str((rescue as Dictionary).get("id", "")) == RESCUE_ID:
			return (rescue as Dictionary).duplicate(true)
	return {}


func _target_center() -> Vector2:
	return _main._world.get_material_candidate_state(TARGET_ID).get("candidate", {}).get("center", Vector2.ZERO)


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


func _disable_live_processing() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _disable_companion(companion) -> void:
	companion.set_physics_process(false)
	_main._companion_sortie.set_process(false)
	var control = _main._companion_sortie.control_runtime()
	if control != null:
		control.set_process(false)
		control.set_physics_process(false)


func _action(action_name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	return event


func _write_manifest(capture_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var file := FileAccess.open("%s/capture_manifest.json" % capture_dir, FileAccess.WRITE)
	if file == null:
		return _fail("could not write capture manifest")
	file.store_string(JSON.stringify({
		"capture_runner": "res://scripts/main/captures/living_expedition_05_capture_runner.gd",
		"review_checkpoint": ReviewCheckpointFixture.LIVING_EXPEDITION_05_START,
		"baseline_accepted": false,
		"bounds_verified": true,
		"states": CAPTURE_STATES,
		"sizes": {
			"1280x720": [1280, 720],
			"mobile_844x390": [693, 390],
		},
		"subject": "Silt Hound rescue, selection, and deliberate Excavate payoff",
	}, "  ") + "\n")
	file.close()
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 05 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
