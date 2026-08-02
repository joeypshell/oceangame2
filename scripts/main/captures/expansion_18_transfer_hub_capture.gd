extends RefCounted

const Expansion16CaptureRenderer := preload("res://scripts/main/captures/expansion_16_capture_renderer.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const EXTERIOR_MAP_ID := "production_level_01"
const INTERIOR_MAP_ID := "transfer_hub_interior_01"
const ENTRANCE_ID := "transfer_hub_exterior_entrance"
const RETURN_ID := "transfer_hub_interior_return"
const BOAT_ENTRY_ID := "surface_boat_entry"
const CORE_TARGET_ID := "transfer_hub_navigation_core_cradle"
const CORE_DISCOVERY_ID := "transfer_hub_navigation_core_discovery"
const CAMERA_ENTRANCE := "expansion_18_transfer_hub_approach"
const CAMERA_BOAT := "production_level_boat_entry"
const CAMERA_INTERIOR_ARRIVAL := "transfer_hub_interior_arrival"
const CAMERA_INTERIOR_CORE := "transfer_hub_navigation_core"
const MOBILE_INTERIOR_FOCUS_SHIFT_PX := 310.0
const CAPTURE_FLAG := "--capture-expansion-18-transfer-hub"
const CAPTURE_STATES := [
	{"map": EXTERIOR_MAP_ID, "id": "entrance_locked"},
	{"map": EXTERIOR_MAP_ID, "id": "entrance_ready"},
	{"map": INTERIOR_MAP_ID, "id": "interior_arrival"},
	{"map": INTERIOR_MAP_ID, "id": "core_cargo_full"},
	{"map": INTERIOR_MAP_ID, "id": "core_recovered"},
	{"map": EXTERIOR_MAP_ID, "id": "exterior_return"},
	{"map": EXTERIOR_MAP_ID, "id": "boat_result"},
]

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_isolated_capture():
		return
	_renderer = Expansion16CaptureRenderer.new(_main, "Expansion 18 Transfer Hub")
	if not _prepare_entrance(false):
		return
	if not await _capture(capture_dir, "entrance_locked", CAMERA_ENTRANCE):
		return
	if not _apply_expansion_18_checkpoint() or not _prepare_entrance(true):
		return
	if not await _capture(capture_dir, "entrance_ready", CAMERA_ENTRANCE, true):
		return
	if not _enter_hub():
		return
	if not await _capture(capture_dir, "interior_arrival", CAMERA_INTERIOR_ARRIVAL, true):
		return
	if not _prepare_full_cargo_core_block():
		return
	if not await _capture(
		capture_dir,
		"core_cargo_full",
		CAMERA_INTERIOR_CORE,
		true,
		MOBILE_INTERIOR_FOCUS_SHIFT_PX
	):
		return
	if not _recover_navigation_core():
		return
	if not await _capture(
		capture_dir,
		"core_recovered",
		CAMERA_INTERIOR_CORE,
		true,
		MOBILE_INTERIOR_FOCUS_SHIFT_PX
	):
		return
	if not _return_to_exterior():
		return
	if not await _capture(capture_dir, "exterior_return", CAMERA_ENTRANCE, true):
		return
	if not _commit_at_boat():
		return
	if not await _capture(capture_dir, "boat_result", CAMERA_BOAT, true):
		return
	if not _write_manifest(capture_dir):
		return
	print("Saved Expansion 18 Transfer Hub captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_isolated_capture() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != EXTERIOR_MAP_ID:
		return _fail("requires the contiguous production level")
	var profile = _main._anomaly_survey.profile_state()
	var report: Dictionary = profile.report()
	if (
		str(profile.last_storage_report().get("status", "")) != "memory"
		or not report.get("completed_discoveries", []).is_empty()
		or not report.get("unlocked_capabilities", []).is_empty()
		or not report.get("material_inventory", {}).is_empty()
		or not report.get("completed_projects", []).is_empty()
	):
		return _fail("did not start from isolated fresh profile state")
	_prepare_runtime_nodes()
	return true


func _apply_expansion_18_checkpoint() -> bool:
	var profile = _main._anomaly_survey.profile_state()
	var applied: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.EXPANSION_18_START, profile)
	if not bool(applied.get("ready", false)):
		return _fail("could not establish the Expansion 18 boundary: %s" % str(applied))
	_main._anomaly_survey.on_map_loaded(_main._world)
	_main._wreck_network_investigation.on_map_loaded(_main._world)
	_main._material_runtime.on_map_loaded(_main._world, _main._expedition_day_state, _main._daily_conditions.current_ids())
	_main._material_project.on_map_loaded(_main._world)
	_main._cutter_salvage.on_map_loaded(_main._world)
	_main._navigation_core.on_map_loaded(_main._world)
	_main._refresh_active_tools()
	return true


func _prepare_runtime_nodes() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._player.reset_motion()
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = false


func _prepare_entrance(ready: bool) -> bool:
	var entrance := _connector_by_id(ENTRANCE_ID)
	if entrance.is_empty():
		return _fail("source-authored exterior entrance is unavailable")
	_main._player.global_position = entrance.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	_main._last_status_note = ""
	_main._update_status_label()
	var expected := "E: Enter Transfer Hub" if ready else "Coordinates not triangulated"
	return _expect(_status_text().find(expected) != -1, "entrance omitted %s" % expected)


func _enter_hub() -> bool:
	if not _main._try_world_connector_transition() or _main._world.map_id != INTERIOR_MAP_ID:
		return _fail("ready entrance did not load the Transfer Hub")
	_prepare_runtime_nodes()
	_main._last_status_note = "Transfer Hub interior"
	_main._update_status_label()
	return _expect(
		_main._player.global_position == _main._world.get_entry_position("transfer_hub_interior_entry"),
		"interior arrival ignored its source entry"
	)


func _prepare_full_cargo_core_block() -> bool:
	var target := _core_target()
	if target.is_empty():
		return _fail("navigation core target is unavailable")
	var probe_index := 0
	while _main._held_cargo_count() < _main._held_salvage_capacity():
		_main._sortie_state.collect_salvage("capture_capacity_probe_%d" % probe_index, 0)
		probe_index += 1
	_main._player.global_position = target.get("center", Vector2.ZERO)
	_main._player.reset_motion()
	if not _select_cutter():
		return false
	var blocked: Dictionary = _main._active_tool_runtime.use()
	_main._update_status_label()
	return _expect(
		str(blocked.get("status", "")) == "wrong_context"
		and str(blocked.get("note", "")).find("Cargo full") != -1
		and not _main._world.is_salvage_collected(CORE_TARGET_ID),
		"full cargo did not leave the core visibly retryable"
	)


func _recover_navigation_core() -> bool:
	_main._sortie_state.clear_held()
	_main._cutter_salvage.reset()
	var target := _core_target()
	_main._player.global_position = target.get("center", Vector2.ZERO)
	if not _select_cutter():
		return false
	var activated: Dictionary = _main._active_tool_runtime.use()
	if str(activated.get("status", "")) != "used":
		return _fail("Space/USE did not activate the Cutter: %s" % str(activated))
	_main._cargo_collection.update(float(target.get("interaction_seconds", 0.0)) + 0.1)
	_main._update_status_label()
	return _expect(
		_main._world.is_salvage_collected(CORE_TARGET_ID)
		and _main._navigation_core.held_count() == 1
		and _status_text().find("Navigation core secured") != -1,
		"Cutter completion did not present recovered core cargo"
	)


func _return_to_exterior() -> bool:
	var paired_return := _connector_by_id(RETURN_ID)
	if paired_return.is_empty():
		return _fail("paired interior return is unavailable")
	_main._player.global_position = paired_return.get("center", Vector2.ZERO)
	if not _main._try_world_connector_transition() or _main._world.map_id != EXTERIOR_MAP_ID:
		return _fail("paired return did not restore the exterior")
	_prepare_runtime_nodes()
	_main._update_status_label()
	return _expect(
		_main._navigation_core.held_count() == 1
		and _main._anomaly_survey.has_pending_discovery(),
		"paired return lost held navigation-core state"
	)


func _commit_at_boat() -> bool:
	_main._player.global_position = _main._world.get_entry_position(BOAT_ENTRY_ID)
	_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	return _expect(
		_main._anomaly_survey.profile_state().has_completed_discovery(CORE_DISCOVERY_ID)
		and _main._navigation_core.held_count() == 0
		and _status_text().find("Navigation core delivered") != -1,
		"canonical boat omitted the delivered-core result"
	)


func _capture(
	capture_dir: String,
	state_id: String,
	camera_id: String,
	allow_status_overlap := false,
	mobile_focus_shift_px := 0.0
) -> bool:
	var camera_test := _camera_test_by_id(camera_id)
	if camera_test.is_empty():
		return _fail("missing authored camera test %s on %s" % [camera_id, _main._world.map_id])
	return await _renderer.capture_pair(
		capture_dir,
		state_id,
		camera_test,
		allow_status_overlap,
		mobile_focus_shift_px
	)


func _write_manifest(capture_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var path := "%s/capture_manifest.json" % capture_dir
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("could not write capture manifest")
	file.store_string(JSON.stringify({
		"capture_flag": CAPTURE_FLAG,
		"review_checkpoint": ReviewCheckpointFixture.EXPANSION_18_START,
		"baseline_accepted": false,
		"states": CAPTURE_STATES,
		"sizes": ["1280x720", "mobile_844x390"],
		"desktop_controls": "E/ACT + Tab + Space/USE",
		"mobile_controls": "ACT + TOOL + USE",
	}, "  ") + "\n")
	file.close()
	return true


func _select_cutter() -> bool:
	_main._refresh_active_tools()
	for _index in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID:
			return true
		_main._active_tool_runtime.cycle()
	return _fail("could not select the existing Salvage Cutter")


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _main._world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _core_target() -> Dictionary:
	for target in _main._world.get_tool_targets():
		if str(target.get("id", "")) == CORE_TARGET_ID:
			return target
	return {}


func _camera_test_by_id(camera_id: String) -> Dictionary:
	for camera_test in _main._world.camera_tests:
		if str(camera_test.get("id", "")) == camera_id:
			return camera_test
	return {}


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Expansion 18 Transfer Hub capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
