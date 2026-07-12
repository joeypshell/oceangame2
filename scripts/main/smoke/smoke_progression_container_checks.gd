extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CHEST_ID := "lower_loop_upgrade_chest"
const RELAY_GATE_ID := "lower_left_loop_current"
const EAST_GATE_ID := "upper_right_current_pocket_gate"
const RELAY_CONNECTOR_ID := "lower_left_loop_connector"
const RETURN_CONNECTOR_ID := "return_to_boat_hub_connector"
const PAYOFF_ID := "slice_04_destination_cache"
const BLUEPRINT_NOTICE := "Blueprint recovered: Propulsion fins"
const BLUEPRINT_PROMPT := "E: Recover propulsion fins blueprint"
const RELAY_PROMPT := "E: Enter Lower-left relay"
const EAST_FINS_REJECTION := "propulsion fins do not work here"
const PLAYER_SWIM_SPEED := 200.0

var _movement_frames := 0


func _smoke_upgrade_chest_and_quit() -> void:
	_prepare_current_map()
	var profile = _main._anomaly_survey.profile_state()
	if not _require(_world.map_id == "production_slice_01", "loaded unexpected origin %s" % _world.map_id):
		return
	if not _verify_distinct_current_sources():
		return
	if not _require(not profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID), "fresh profile already owned fins blueprint"):
		return
	if not _require(_status_text().find("Find fins blueprint") != -1, "fresh HUD did not lead to blueprint: %s" % _status_text()):
		return
	if not _require(_status_text().find("Shock prod locked") == -1, "fresh HUD advertised shock prod prematurely: %s" % _status_text()):
		return

	var chest := _container_by_id(CHEST_ID)
	if not _require(not chest.is_empty(), "missing blueprint chest %s" % CHEST_ID):
		return
	if not _move_to(chest["center"], "fins blueprint chest"):
		return
	_process(0.0)
	if not _require(not profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID), "blueprint auto-recovered from proximity"):
		return
	if not _require(not _main._progression_containers.is_opened(CHEST_ID), "blueprint chest auto-opened from proximity"):
		return
	if not _require(_status_text().find(BLUEPRINT_PROMPT) != -1, "blueprint chest did not present explicit E prompt: %s" % _status_text()):
		return
	var chest_node: Node = _world.find_child(CHEST_ID, true, false)
	if not _require(chest_node != null and str(chest_node.get_meta("cue_kind", "")) == "blueprint", "blueprint chest has no source-derived blueprint cue"):
		return
	_press_key(KEY_E)
	_process(0.0)
	if not _require(profile.has_completed_discovery(ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID), "blueprint did not enter durable profile knowledge"):
		return
	if not _require(_main._progression_containers.is_opened(CHEST_ID), "blueprint chest did not enter opened state"):
		return
	if not _require(_last_status_note.find(BLUEPRINT_NOTICE) != -1, "blueprint transaction did not emit its contextual notice: %s" % _last_status_note):
		return
	if not _verify_tracker("Titanium", "Rubber") or not _require(_tracker_text().find("held") != -1, "tracker did not distinguish held cargo: %s" % _tracker_text()):
		return
	if not _require(_session_wallet() == 0, "blueprint chest still granted wallet=%d" % _session_wallet()):
		return

	if not _collect_and_bank_fins_recipe(profile):
		return
	if not _verify_tracker("2/2 banked", "1/1 banked"):
		return
	if not _require(_tracker_text().find("Ready") != -1, "tracker did not show recipe ready: %s" % _tracker_text()):
		return
	var wallet_before_build := _session_wallet()
	var materials_before_day_build: Dictionary = profile.material_inventory()
	_press_key(KEY_P)
	if not _require(not profile.has_completed_project(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID) and not profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "P completed fins during active day"):
		return
	if not _require(profile.material_inventory() == materials_before_day_build and _session_wallet() == wallet_before_build, "active-day P changed materials or wallet"):
		return
	if not _require(_main._last_status_note.find("Nothing builds during day") != -1, "active-day P did not state that nothing built: %s" % _main._last_status_note):
		return

	_press_key(KEY_N)
	_process(0.0)
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "N at boat did not enter night debrief"):
		return
	_press_key(KEY_P)
	if not _require(profile.has_completed_project(ExpansionProfileState.PROPULSION_FINS_PROJECT_ID), "P did not complete fins project"):
		return
	if not _require(profile.has_capability(ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID), "fins capability was not unlocked"):
		return
	if not _require(profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 0 and profile.material_quantity(ExpansionProfileState.RUBBER_MATERIAL_ID) == 0, "fins build did not spend exact recipe"):
		return
	if not _require(_session_wallet() == wallet_before_build, "fins build changed wallet %d -> %d" % [wallet_before_build, _session_wallet()]):
		return
	if not _require(_main._last_status_note.find("Fins installed - relay unlocked") != -1, "night build did not confirm fins installation: %s" % _main._last_status_note):
		return
	_press_key(KEY_N)
	_prepare_current_map()
	if not _require(_main._expedition_day_state.phase == ExpeditionDayState.PHASE_ACTIVE, "N did not begin the post-build day"):
		return
	if not _verify_east_gate_rejects_fins():
		return

	var connector := _connector_by_id(RELAY_CONNECTOR_ID)
	if not _require(not connector.is_empty(), "missing relay connector %s" % RELAY_CONNECTOR_ID):
		return
	var relay_start_frames := _movement_frames
	if not _move_to(connector["center"], "visible lower-left relay"):
		return
	_process(0.0)
	if not _require(_movement_frames > relay_start_frames, "relay proof did not use controller movement"):
		return
	if not _require(str(_world.get_world_connector_at(_player.global_position).get("id", "")) == RELAY_CONNECTOR_ID, "rendered relay route ended outside actionable connector bounds"):
		return
	if not _require(_status_text().find(RELAY_PROMPT) != -1, "post-fins relay did not show E prompt: %s" % _status_text()):
		return
	_press_key(KEY_E)
	_prepare_current_map()
	if not _require(_world.map_id == "production_slice_04", "E at relay loaded %s" % _world.map_id):
		return
	var wallet_before_payoff := _session_wallet()

	var payoff := _salvage_by_id(PAYOFF_ID)
	if not _require(not payoff.is_empty(), "missing relay payoff %s" % PAYOFF_ID):
		return
	if not _move_to(payoff["center"], "relay payoff"):
		return
	if not _require(_collect_salvage_for_smoke(payoff), "relay payoff did not collect"):
		return
	if not _move_to(_world.get_extraction_center(), "relay extraction"):
		return
	_process(0.0)
	if not _require(bool(_main._anomaly_survey.report().get("lead_available", false)), "banked relay payoff did not activate scanner lead"):
		return
	if not _require(_session_wallet() == wallet_before_payoff + AnomalySurveyRuntime.SCANNER_COST, "relay payoff delta=%d expected=%d" % [_session_wallet() - wallet_before_payoff, AnomalySurveyRuntime.SCANNER_COST]):
		return

	var return_connector := _connector_by_id(RETURN_CONNECTOR_ID)
	if not _require(not return_connector.is_empty(), "missing relay return connector"):
		return
	if not _move_to(return_connector["center"], "relay return"):
		return
	_process(0.0)
	if not _require(_status_text().find("E: Enter") != -1, "relay return did not show E prompt"):
		return
	_press_key(KEY_E)
	_prepare_current_map()
	if not _require(_world.map_id == "production_slice_01" and _world.is_inside_boat(_player.global_position), "relay return did not arrive at canonical boat"):
		return
	var scanner_status := _status_text()
	if not _require(scanner_status.find("Q: Scanner (%d)" % AnomalySurveyRuntime.SCANNER_COST) != -1, "scanner was not the next action: %s" % scanner_status):
		return
	if not _require(scanner_status.find("Shock prod locked") == -1, "scanner-next HUD still advertised shock prod: %s" % scanner_status):
		return
	_press_key(KEY_Q)
	if not _require(_main._anomaly_survey.has_scanner() and _session_wallet() == wallet_before_payoff, "Q did not spend exactly the guaranteed relay payoff"):
		return

	print("Blueprint fins journey smoke passed: blueprint=%s explicit_e=true proximity_auto_open=false daytime_build=false recipe=ti2+rubber1 tracker=banked_vs_held east_fins_rejected=true relay_prompt=%s controller_frames=%d payoff=%s scanner_next=true shock_prod_suppressed=true." % [
		ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID,
		RELAY_PROMPT,
		_movement_frames,
		PAYOFF_ID,
	])
	get_tree().quit()


func _prepare_current_map() -> void:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_combat_interactions_enabled = false
	if _player.has_method("reset_motion"):
		_player.reset_motion()


func _collect_and_bank_fins_recipe(profile) -> bool:
	var active_ids: Array = _world.get_material_candidate_report().get("active_ids", [])
	var recipe_candidates: Array = []
	for candidate in _world.get_material_candidates():
		var material_id := str(candidate.get("material_id", ""))
		if active_ids.has(str(candidate.get("id", ""))) and material_id in [ExpansionProfileState.TITANIUM_MATERIAL_ID, ExpansionProfileState.RUBBER_MATERIAL_ID]:
			recipe_candidates.append(candidate)
	if not _require(recipe_candidates.size() == 3, "active day did not guarantee two titanium and one rubber"):
		return false
	for candidate in recipe_candidates:
		var material_id := str(candidate.get("material_id", ""))
		var required := 2 if material_id == ExpansionProfileState.TITANIUM_MATERIAL_ID else 1
		var held := int(_main._material_runtime.held_quantities().get(material_id, 0))
		if profile.material_quantity(material_id) + held >= required:
			continue
		if _main._held_cargo_count() >= _main._held_salvage_capacity() and not _bank_at_boat():
			return false
		var before: int = profile.material_quantity(material_id) + int(_main._material_runtime.held_quantities().get(material_id, 0))
		if not _move_to(candidate["center"], "material %s" % candidate.get("id", "")):
			return false
		_process(0.0)
		var after: int = profile.material_quantity(material_id) + int(_main._material_runtime.held_quantities().get(material_id, 0))
		if after <= before and _main._held_cargo_count() >= _main._held_salvage_capacity():
			if not _bank_at_boat():
				return false
			before = profile.material_quantity(material_id) + int(_main._material_runtime.held_quantities().get(material_id, 0))
			if not _move_to(candidate["center"], "retry material %s" % candidate.get("id", "")):
				return false
			_process(0.0)
			after = profile.material_quantity(material_id) + int(_main._material_runtime.held_quantities().get(material_id, 0))
		if not _require(after > before, "normal navigation did not collect %s" % candidate.get("id", "")):
			return false
	return _bank_at_boat() and _require(
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 2
		and profile.material_quantity(ExpansionProfileState.RUBBER_MATERIAL_ID) == 1,
		"banked recipe was not exactly titanium 2 and rubber 1"
	)


func _bank_at_boat() -> bool:
	var boat_entry: Vector2 = _world.get_entry_position("surface_boat_entry")
	if not _move_to(boat_entry, "surface boat"):
		return false
	_process(0.0)
	return _require(_world.is_inside_boat(_player.global_position) and _main._material_runtime.held_count() == 0, "boat did not bank held materials")


func _move_to(target: Vector2, label: String) -> bool:
	var path: Array = _world.find_open_path(_player.global_position, target)
	if not _require(not path.is_empty(), "no open route to %s" % label):
		return false
	print("Blueprint journey route: %s cells=%d" % [label, path.size()])
	for waypoint in path:
		var distance: float = _player.global_position.distance_to(waypoint)
		var direction: Vector2 = (_player.global_position.direction_to(waypoint) if distance > 0.0 else Vector2.ZERO)
		_player.swim_in_direction(direction, 1.0 / 60.0)
		_player.global_position = waypoint
		_movement_frames += 1
		_process(distance / PLAYER_SWIM_SPEED)
		if _main._expedition_day_state.phase != ExpeditionDayState.PHASE_ACTIVE:
			return _require(false, "day ended while traversing validated route to %s" % label)
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	return true


func _verify_distinct_current_sources() -> bool:
	var relay_gate := _gate_by_id(RELAY_GATE_ID)
	var east_gate := _gate_by_id(EAST_GATE_ID)
	var connector := _connector_by_id(RELAY_CONNECTOR_ID)
	if not _require(not relay_gate.is_empty() and not east_gate.is_empty() and not connector.is_empty(), "current/connector source metadata is incomplete"):
		return false
	if not _require(relay_gate["rect"] == connector["rect"], "relay current and connector bounds do not align"):
		return false
	if not _require(not east_gate["rect"].intersects(connector["rect"]), "east stabilizer current overlaps fins connector"):
		return false
	if not _require(_world.get_world_connector_at(east_gate["center"]).is_empty(), "east stabilizer current incorrectly advertises a world connector"):
		return false
	var relay_affordance := _world.find_child("%sCurrentAffordance" % RELAY_GATE_ID, true, false)
	var east_affordance := _world.find_child("%sCurrentAffordance" % EAST_GATE_ID, true, false)
	if not _require(relay_affordance != null and east_affordance != null, "one of the distinct current affordances is missing"):
		return false
	if not _require(str(relay_affordance.get_meta("current_affordance_role", "")) == "relay" and str(east_affordance.get_meta("current_affordance_role", "")) == "barrier", "current affordance roles are not source-derived"):
		return false
	if not _require(relay_affordance.find_child("RelayBeacon", true, false) != null and east_affordance.find_child("RelayBeacon", true, false) == null, "relay beacon does not distinguish the fins current"):
		return false
	var relay_flow := relay_affordance.find_child("CurrentArrow0Shaft", true, false) as Line2D
	var east_flow := east_affordance.find_child("CurrentArrow0Shaft", true, false) as Line2D
	return _require(relay_flow != null and east_flow != null and relay_flow.default_color != east_flow.default_color, "relay and barrier current colors are indistinguishable")


func _verify_east_gate_rejects_fins() -> bool:
	var east_gate := _gate_by_id(EAST_GATE_ID)
	if not _move_to(east_gate["center"], "east stabilizer current"):
		return false
	_player.global_position = east_gate["center"]
	_process(0.0)
	var gate_at_player: Dictionary = _world.get_current_gate_at(_player.global_position)
	if not _require(_status_text().find(EAST_FINS_REJECTION) != -1, "east current did not explain that fins are invalid at %s gate=%s: %s" % [str(_player.global_position), str(gate_at_player.get("id", "none")), _status_text()]):
		return false
	var map_before := str(_world.map_id)
	_press_key(KEY_E)
	_process(0.0)
	return _require(str(_world.map_id) == map_before and _world.get_world_connector_at(_player.global_position).is_empty(), "E at east stabilizer current triggered a connector")


func _verify_tracker(first_fragment: String, second_fragment: String) -> bool:
	if not _require(_main._progression_project_tracker != null and _main._progression_project_tracker.visible, "fins tracker is not visible"):
		return false
	var tracker := _tracker_text()
	return _require(tracker.find(first_fragment) != -1 and tracker.find(second_fragment) != -1, "tracker counts unclear: %s" % tracker)


func _tracker_text() -> String:
	return _main._progression_project_tracker.snapshot_text() if _main._progression_project_tracker != null else ""


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	_main._unhandled_input(event)


func _container_by_id(container_id: String) -> Dictionary:
	for container in _world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Blueprint fins journey smoke failed: %s" % message)
	get_tree().quit(1)
	return false
