extends RefCounted

const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const FRESH_RESCUE_ID := "living_expedition_05_start"
const EXCAVATE_READY_ID := "living_expedition_05_excavate_ready"
const MARL_ID := CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID
const MICA_ID := CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID
const SUPPORT_MATERIALS := {
	ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
	ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
}


static func is_supported(checkpoint_id: String) -> bool:
	return checkpoint_id in [FRESH_RESCUE_ID, EXCAVATE_READY_ID]


static func recipe() -> Dictionary:
	return SUPPORT_MATERIALS.duplicate(true)


static func configure(checkpoint_id: String, profile) -> Dictionary:
	if checkpoint_id == FRESH_RESCUE_ID:
		return {"ready": true, "reason": "fresh_rescue"}
	if checkpoint_id != EXCAVATE_READY_ID:
		return {"ready": false, "reason": "unsupported_checkpoint"}
	var committed: Dictionary = profile.commit_companion_rescue(
		MARL_ID,
		"silt_hound",
		"Marl",
		false
	)
	if not bool(committed.get("changed", false)):
		return {"ready": false, "reason": "marl_fixture_failed", "detail": committed}
	var selected: Dictionary = profile.select_active_companion(MARL_ID, false)
	return {
		"ready": bool(selected.get("changed", false)),
		"reason": str(selected.get("reason", "marl_selection_failed")),
		"detail": selected,
	}


static func decorate_result(checkpoint_id: String, result: Dictionary) -> Dictionary:
	var value := result.duplicate(true)
	value["day_number"] = 4
	value["review_oxygen_seconds"] = 180.0
	value["active_objective_id"] = "silt_hound_rescue" if checkpoint_id == FRESH_RESCUE_ID else "silt_hound_excavation"
	value["active_objective_label"] = "Silt Hound rescue" if checkpoint_id == FRESH_RESCUE_ID else "Marl excavation"
	if checkpoint_id == EXCAVATE_READY_ID:
		value["review_start_tile"] = {"x": 95.0, "y": 80.0}
		value["review_target_id"] = "silt_hound_buried_titanium_01"
	return value


static func boundary_is_ready(checkpoint_id: String, profile) -> bool:
	if not is_supported(checkpoint_id):
		return false
	var companion: Dictionary = profile.companion_report()
	var individuals: Array = companion.get("individuals", [])
	var marl := _individual_by_id(individuals, MARL_ID)
	var expected_count := 2 if checkpoint_id == FRESH_RESCUE_ID else 3
	var expected_active := MICA_ID if checkpoint_id == FRESH_RESCUE_ID else MARL_ID
	return (
		profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID)
		and profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		and not profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID)
		and not profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
		and profile.material_inventory() == SUPPORT_MATERIALS
		and individuals.size() == expected_count
		and str(companion.get("active_individual_id", "")) == expected_active
		and (marl.is_empty() if checkpoint_id == FRESH_RESCUE_ID else _marl_is_clean(marl))
	)


static func _marl_is_clean(marl: Dictionary) -> bool:
	return (
		str(marl.get("species_id", "")) == "silt_hound"
		and str(marl.get("callsign", "")) == "Marl"
		and bool(marl.get("rescue_committed", false))
		and (marl.get("earned_memory_ids", []) as Array).is_empty()
		and str(marl.get("selected_adaptation_id", "")).is_empty()
	)


static func _individual_by_id(individuals: Array, individual_id: String) -> Dictionary:
	for value in individuals:
		if value is Dictionary and str(value.get("individual_id", "")) == individual_id:
			return (value as Dictionary).duplicate(true)
	return {}
