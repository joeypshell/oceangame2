extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const LivingExpedition04CaptureRenderer := preload("res://scripts/main/captures/living_expedition_04_capture_renderer.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")

const HOSTILE_ID := "deep_cache_territorial_eel"
const HARVEST_ID := "deep_cache_eel_electrocyte_harvest"
const CACHE_ID := "salvage_deep_right_cache"
const MICA_ID := "veil_cuttle_juvenile_01"
const KITE_ID := "spark_ray_juvenile_01"
const CAMERA_ID := "living_expedition_04_eel_review_camera_01"
const CAPTURE_STATES := [
	{"id": "mica_intent_read", "camera": CAMERA_ID},
	{"id": "guardian_opening", "camera": CAMERA_ID},
	{"id": "shock_prod_damage", "camera": CAMERA_ID},
	{"id": "defeat_harvest_available", "camera": CAMERA_ID},
]

var _main
var _renderer


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if not _prepare_main():
		return
	_renderer = LivingExpedition04CaptureRenderer.new(_main)
	if not _prepare_mica_intent() or not await _capture(capture_dir, "mica_intent_read", {"kind": "mica_intent"}):
		return
	if not _prepare_guardian_opening() or not await _capture(capture_dir, "guardian_opening", {"kind": "guardian_opening"}):
		return
	if not _prepare_shock_damage() or not await _capture(capture_dir, "shock_prod_damage", {"kind": "shock_damage", "replay_shock": true}):
		return
	if not _prepare_defeat_harvest() or not await _capture(capture_dir, "defeat_harvest_available", {"kind": "defeat_harvest"}):
		return
	if not _write_manifest(capture_dir):
		return
	print("Saved Living Expedition 04 captures under: %s" % ProjectSettings.globalize_path(capture_dir))
	await _renderer.prepare_to_quit()
	_main.get_tree().quit(0)


func _prepare_main() -> bool:
	if _main._world == null or _main._player == null or _main._world.map_id != "production_level_01":
		return _fail("requires production_level_01")
	if (
		_main._review_checkpoint_id != ReviewCheckpointFixture.LIVING_EXPEDITION_04_START
		or not bool(_main._review_checkpoint_report.get("ready", false))
	):
		return _fail("requires the isolated living_expedition_04_start checkpoint")
	_disable_live_processing()
	_main._sortie_state.update_offload_presence(false, _main._oxygen_capacity_seconds())
	_main._expedition_day_state.record_sortie_started()
	var profile = _main._anomaly_survey.profile_state()
	var companion: Dictionary = profile.companion_report()
	return _expect(
		int(_main._expedition_day_state.day_number) == 3
		and str(companion.get("active_individual_id", "")) == MICA_ID
		and _adaptation_for(companion, MICA_ID) == "drift_lens"
		and _adaptation_for(companion, KITE_ID) == "guardian_pulse"
		and profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID),
		"checkpoint did not begin on Day 3 with both adapted companions and Shock Prod"
	)


func _prepare_mica_intent() -> bool:
	if not _bind_active_companion(MICA_ID, "veil_cuttle"):
		return false
	_reset_encounter()
	var home := _hostile_home()
	_main._player.global_position = home + Vector2(-64.0, 0.0)
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_place_companion(home + Vector2(-44.0, 0.0))
	_main._hostiles.update(_main._world, _main._player.global_position, 0.0)
	var result := _dispatch_command("read_drift")
	_main._update_status_label()
	var projection: Dictionary = _main._companion_sortie.companion().report().get("drift_projection", {})
	return _expect(
		bool(result.get("changed", false))
		and str(result.get("target_id", "")) == HOSTILE_ID
		and str(result.get("command_label", "")) == "Predict Lunge"
		and str(result.get("phase", "")) == "warning"
		and bool(projection.get("visible", false))
		and str(projection.get("subject_kind", "")) == "territorial_hostile",
		"Mica intent capture did not explain Predict Lunge against the warned eel"
	)


func _prepare_guardian_opening() -> bool:
	if not _bind_active_companion(KITE_ID, "spark_ray"):
		return false
	_reset_encounter()
	var home := _hostile_home()
	_main._player.global_position = home + Vector2(-100.0, 0.0)
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_place_companion(home + Vector2(-84.0, 0.0))
	_main._hostiles.update(_main._world, _main._player.global_position, 0.0)
	var before: Dictionary = _hostile_state()
	var started := _dispatch_command("guardian_pulse_action")
	if not bool(started.get("changed", false)):
		return _fail("Guardian Pulse did not begin: %s" % str(started))
	var guardian = _main._companion_sortie.guardian_pulse_runtime()
	guardian.advance(0.5, false)
	_main._update_status_label()
	var after: Dictionary = _hostile_state()
	var presentation: Dictionary = _main._companion_sortie.companion().report().get("presentation", {})
	return _expect(
		str(guardian.report().get("last_result", "")) == "hit"
		and str(after.get("phase", "")) == "recovery"
		and int(after.get("health", -1)) == int(before.get("health", -2))
		and bool(presentation.get("guardian_opening", false)),
		"Guardian opening capture changed health or omitted the opening cue"
	)


func _prepare_shock_damage() -> bool:
	_main._companion_sortie.guardian_pulse_runtime().reset("capture_transition")
	_reset_encounter()
	if not _select_tool(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID):
		return false
	var first := _shock_hit()
	if not bool(first.get("connected", false)) or int(first.get("health", -1)) != 2:
		return _fail("first Shock Prod setup hit failed: %s" % str(first))
	_main._shock_prod.update(ShockProdController.ATTACK_COOLDOWN_SECONDS)
	var second := _shock_hit()
	_main._update_status_label()
	return _expect(
		bool(second.get("connected", false))
		and int(second.get("health", -1)) == 1
		and str(_hostile_state().get("phase", "")) == "recovery"
		and bool(_main._player.get_shock_prod_presentation_report().get("visible", false)),
		"Shock Prod damage capture did not reach the readable 1/3 state"
	)


func _prepare_defeat_harvest() -> bool:
	_main._shock_prod.update(ShockProdController.ATTACK_COOLDOWN_SECONDS)
	var defeated := _shock_hit()
	if not bool(defeated.get("defeated", false)) or int(_hostile_state().get("health", -1)) != 0:
		return _fail("third Shock Prod hit did not defeat the eel: %s" % str(defeated))
	var position: Vector2 = _hostile_state().get("position", Vector2.ZERO)
	_main._player.global_position = position + Vector2(-24.0, 0.0)
	_place_companion(position + Vector2(-84.0, 0.0))
	_main._cargo_collection.update(0.0)
	_main._update_status_label()
	var resource_states: Dictionary = _main._world.get_biological_resource_visual_report().get("states", {})
	return _expect(
		str(_hostile_state().get("phase", "")) == "defeated"
		and str(resource_states.get(HARVEST_ID, "")) == "available"
		and str(_main._biological_resources.report().get("active_source_id", "")) == HARVEST_ID
		and not _main._world.is_salvage_collected(CACHE_ID),
		"defeat capture did not expose only the explicit harvest"
	)


func _bind_active_companion(individual_id: String, species_id: String) -> bool:
	var profile = _main._anomaly_survey.profile_state()
	if str(profile.companion_report().get("active_individual_id", "")) != individual_id:
		var selected: Dictionary = profile.select_active_companion(individual_id, false)
		if not bool(selected.get("changed", false)):
			return _fail("could not select %s: %s" % [individual_id, str(selected)])
	var launched: Dictionary = _main._companion_sortie.bind_map(
		_main._world,
		_main._player,
		profile,
		Callable(_main, "_has_upgrade_id"),
		true,
		false,
		_main._hostiles,
		_main._moving_hazards,
		_main._daily_conditions.current_ids()
	)
	var companion = _main._companion_sortie.companion()
	if str(launched.get("active_species_id", "")) != species_id or companion == null:
		return _fail("%s did not launch from the checkpoint" % individual_id)
	_disable_companion(companion)
	return true


func _reset_encounter() -> void:
	_main._hostiles.reset_for_failure(_main._world)
	_main._biological_resources.on_map_loaded(_main._world, false)
	_main._shock_prod.reset()
	_main._last_status_note = ""


func _shock_hit() -> Dictionary:
	var position: Vector2 = _hostile_state().get("position", _hostile_home())
	_main._player.global_position = position + Vector2(-60.0, 0.0)
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_place_companion(position + Vector2(-100.0, 0.0))
	_main._hostiles.update(_main._world, _main._player.global_position, 0.0)
	var result: Dictionary = _main._active_tool_runtime.use_shock_prod()
	_main._update_status_label()
	return result


func _dispatch_command(action_id: String) -> Dictionary:
	var control = _main._companion_sortie.control_runtime()
	var commands: Array = control.begin_command_mode().get("context_commands", [])
	for index in range(commands.size()):
		if str((commands[index] as Dictionary).get("id", "")) == action_id:
			return control.activate_context_command(index)
	control.end_command_mode()
	return {"changed": false, "reason": "command_missing", "action_id": action_id}


func _select_tool(tool_id: String) -> bool:
	_main._refresh_active_tools()
	for _step in range(_main.ActiveToolController.ordered_tool_ids().size()):
		if _main._active_tools.selected_tool_id() == tool_id:
			return true
		_main._active_tool_runtime.cycle()
	return _fail("could not select %s" % tool_id)


func _place_companion(position: Vector2) -> void:
	var companion = _main._companion_sortie.companion()
	if companion == null:
		return
	companion.global_position = position
	if companion.has_method("advance"):
		companion.advance(0.0)


func _capture(capture_dir: String, state_id: String, expectation: Dictionary) -> bool:
	var camera_test := _camera_test(_state_camera(state_id))
	if camera_test.is_empty():
		return _fail("missing authored camera for %s" % state_id)
	var defeat_timer: Timer = null
	if str(expectation.get("kind", "")) == "defeat_harvest":
		var hostile_root: Node = _main._world.find_child(HOSTILE_ID, true, false)
		if hostile_root != null:
			defeat_timer = hostile_root.get_node_or_null("DefeatTimer") as Timer
			if defeat_timer != null:
				defeat_timer.paused = true
	var captured: bool = await _renderer.capture_pair(capture_dir, state_id, camera_test, expectation)
	if defeat_timer != null and is_instance_valid(defeat_timer):
		defeat_timer.paused = false
	return captured


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


func _hostile_state() -> Dictionary:
	return _main._hostiles.state_for(HOSTILE_ID)


func _hostile_home() -> Vector2:
	return _hostile_state().get("home_center", Vector2.ZERO)


func _adaptation_for(report: Dictionary, individual_id: String) -> String:
	for individual in report.get("individuals", []):
		if str((individual as Dictionary).get("individual_id", "")) == individual_id:
			return str((individual as Dictionary).get("selected_adaptation_id", ""))
	return ""


func _disable_live_processing() -> void:
	_main.set_process(false)
	_main._player.set_physics_process(false)
	_main._hazard_interactions_enabled = false
	_main._combat_interactions_enabled = true


func _disable_companion(companion) -> void:
	companion.set_physics_process(false)
	_main._companion_sortie.set_process(false)
	var control = _main._companion_sortie.control_runtime()
	control.set_process(false)
	control.set_physics_process(false)


func _write_manifest(capture_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var file := FileAccess.open("%s/capture_manifest.json" % capture_dir, FileAccess.WRITE)
	if file == null:
		return _fail("could not write capture manifest")
	file.store_string(JSON.stringify({
		"capture_runner": "res://scripts/main/captures/living_expedition_04_capture_runner.gd",
		"review_checkpoint": ReviewCheckpointFixture.LIVING_EXPEDITION_04_START,
		"baseline_accepted": false,
		"bounds_verified": true,
		"states": CAPTURE_STATES,
		"sizes": {
			"1280x720": [1280, 720],
			"mobile_844x390": [693, 390],
		},
		"subject": "companion-shaped territorial eel encounter",
	}, "  ") + "\n")
	file.close()
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 04 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
