extends RefCounted

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const CONTAINER_ID := "east_current_scanner_blueprint_chest"
const OPTIONAL_CACHE_ID := "salvage_current_pocket_cache"
const BOAT_ENTRY_ID := "surface_boat_entry"
const PASSABLE_CAPABILITIES := [ExpansionProfileState.PROPULSION_FINS_CAPABILITY_ID]


func run(owner) -> bool:
	var profile = owner._main._anomaly_survey.profile_state()
	var container := _container_by_id(owner._world, CONTAINER_ID)
	if not owner._require(not container.is_empty(), "missing scanner blueprint container %s" % CONTAINER_ID):
		return false
	var navigation = owner._navigation_for("", PASSABLE_CAPABILITIES)
	if not await owner._drive_to("scanner_blueprint_outbound", container["center"], navigation):
		return false
	owner._advance(0.0)
	if not owner._require(not profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID), "scanner blueprint auto-recovered"):
		return false
	owner._press_key(KEY_E)
	if not owner._require(profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID), "E did not recover scanner blueprint"):
		return false
	var tracker_text: String = owner._main._progression_project_tracker.snapshot_text()
	if not owner._require(
		owner._main._progression_project_tracker.visible
		and tracker_text.find("Titanium  0/1 banked") != -1
		and tracker_text.find("Coil  0/1 banked") != -1,
		"scanner recipe tracker was not immediate and exact: %s" % tracker_text
	):
		return false
	owner._press_key(KEY_SPACE)
	if not owner._require(not owner._main._anomaly_survey.has_scanner() and owner._main._last_status_note.find("Ti 1 + Coil 1") != -1, "Space bypassed or obscured scanner project"):
		return false
	if not await owner._return_to_boat("scanner_blueprint_return", navigation):
		return false

	var wallet_before: int = owner._session_wallet()
	for material_id in [ExpansionProfileState.TITANIUM_MATERIAL_ID, ExpansionProfileState.COIL_MATERIAL_ID]:
		if profile.material_quantity(material_id) >= 1:
			continue
		var candidate := _reachable_recipe_candidate(owner, material_id)
		if not owner._require(not candidate.is_empty(), "no collision-clear active %s source for scanner recipe" % material_id):
			return false
		var candidate_material_id := str(candidate.get("material_id", ""))
		var candidate_navigation = owner._navigation_for(str(candidate.get("id", "")), PASSABLE_CAPABILITIES)
		if not await owner._drive_to("scanner_recipe_%s" % candidate_material_id, candidate["center"], candidate_navigation):
			return false
		owner._advance(0.0)
		if not await owner._return_to_boat("scanner_recipe_return_%s" % candidate_material_id, candidate_navigation):
			return false
	if not owner._require(
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 1
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 1,
		"scanner recipe was not exactly titanium 1 and coil 1"
	):
		return false
	owner._press_key(KEY_P)
	if not owner._require(not profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "scanner built during active day"):
		return false
	owner._press_key(KEY_N)
	owner._advance(0.0)
	if not owner._require(owner._main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF, "scanner recipe did not reach night debrief"):
		return false
	owner._press_key(KEY_P)
	if not owner._require(
		profile.has_completed_project(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID)
		and profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID),
		"night transaction did not build scanner"
	):
		return false
	if not owner._require(
		profile.material_quantity(ExpansionProfileState.TITANIUM_MATERIAL_ID) == 0
		and profile.material_quantity(ExpansionProfileState.COIL_MATERIAL_ID) == 0
		and owner._session_wallet() == wallet_before
		and not owner._world.is_salvage_collected(OPTIONAL_CACHE_ID),
		"scanner project spent the wrong owner or required optional cache"
	):
		return false
	owner._press_key(KEY_N)
	owner._advance(0.0)
	owner._prepare_controlled_movement()
	owner._body_size = ((owner._player.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size
	owner._starting_health = int(owner._main._player_health.current_health)
	owner._minimum_oxygen = owner._oxygen_seconds
	owner._press_key(KEY_SPACE)
	return owner._require(
		owner._main._expedition_day_state.day_number == 3
		and owner._main._last_status_note.begins_with("Scanner ready"),
		"built scanner did not enter contextual SCAN state on day three"
	)


func _container_by_id(world, container_id: String) -> Dictionary:
	for container in world.get_progression_containers():
		if str(container.get("id", "")) == container_id:
			return container
	return {}


func _reachable_recipe_candidate(owner, material_id: String) -> Dictionary:
	var active_ids: Array = owner._world.get_material_candidate_report().get("active_ids", [])
	for candidate in owner._world.get_material_candidates():
		var candidate_id := str(candidate.get("id", ""))
		if not active_ids.has(candidate_id) or str(candidate.get("material_id", "")) != material_id:
			continue
		var navigation = owner._navigation_for(candidate_id, PASSABLE_CAPABILITIES)
		var outbound: PackedVector2Array = navigation.path_between(owner._player.global_position, candidate["center"])
		var returning: PackedVector2Array = navigation.path_between(candidate["center"], owner._world.get_entry_position(BOAT_ENTRY_ID))
		if outbound.size() > 1 and returning.size() > 1:
			return candidate
	return {}
