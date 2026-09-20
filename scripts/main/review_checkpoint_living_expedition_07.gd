extends RefCounted

const Capabilities := preload("res://scripts/main/review_checkpoint_living_expedition_06.gd")
const ReviewCamera := preload("res://scripts/main/review_checkpoint_camera.gd")
const REFUGE_ID := "living_expedition_07_refuge"
const NIGHT_ID := "living_expedition_07_night"
const PIN_ID := "living_expedition_07_pin"
const MARL_ID := "silt_hound_juvenile_01"
const REFUGE := "deep_cache_burrow_refuge_01"
const REQUIRED := ["propulsion_fins", "dive_light_1", "shock_prod", "salvage_cutter"]


static func is_supported(id: String) -> bool:
	return id in [REFUGE_ID, NIGHT_ID, PIN_ID]


static func frame_player(player, id: String) -> void:
	if id in [REFUGE_ID, PIN_ID]:
		player.add_child(ReviewCamera.new())


static func apply(id: String, profile, map_path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(map_path))
	if not is_supported(id) or not data is Dictionary:
		return {"ready": false, "reason": "invalid_checkpoint_source"}
	var refuge := {}
	for record in data.get("burrow_refuges", []):
		if record.get("id") == REFUGE:
			refuge = record
	if refuge.is_empty():
		return {"ready": false, "reason": "missing_refuge"}
	for capability in REQUIRED:
		var result := Capabilities._complete_capability(profile, data.get("material_projects", []), capability)
		if not result.get("ready", false):
			return result
	profile.commit_companion_rescue(MARL_ID, "silt_hound", "Marl", false)
	profile.select_active_companion(MARL_ID, false)
	if id != REFUGE_ID:
		profile.earn_companion_memory_for(MARL_ID, "guarded_the_nest", false)
	if id == PIN_ID:
		profile.select_companion_adaptation("root_claws", false)
	var individual: Dictionary = profile.companion_report().get("individual", {})
	var adapted := str(individual.get("selected_adaptation_id", "")) == "root_claws"
	var remembered := (individual.get("earned_memory_ids", []) as Array).has("guarded_the_nest")
	if individual.get("individual_id") != MARL_ID or adapted != (id == PIN_ID) or remembered != (id != REFUGE_ID):
		return {"ready": false, "reason": "identity_boundary_failed"}
	var result := {"ready": true, "reason": "ready", "checkpoint_id": id,
		"map_path": map_path, "day_number": 5 if id == PIN_ID else 4,
		"review_target_id": REFUGE,
		"active_objective_id": "marl_guarded_nest_opportunity_01",
		"active_objective_label": "Marl's Root Claws"}
	if id != NIGHT_ID:
		# The authored approach lets the player read before deliberately drawing the eel.
		result["review_start_tile"] = refuge["approach_point"].duplicate()
	return result
