extends RefCounted

const MaterialCargoState := preload("res://scripts/main/material_cargo_state.gd")
const PracticalResearchPresentation := preload("res://scripts/main/practical_research_presentation.gd")
const TITANIUM_ID := "titanium_scrap"
const RUBBER_ID := "rubber_sheet"
const COIL_ID := "conductive_coil"
const INSULATING_GEL_ID := "insulating_gel"
const EEL_ELECTROCYTE_ID := "eel_electrocyte"

var _profile
var _cargo := MaterialCargoState.new()
var _current_map_has_materials := false
var _current_map_has_biological_resources := false
var _research_lead_text := ""
var _researched_pool_ids: Array[String] = []


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world, day_state, active_condition_ids := []) -> Dictionary:
	_current_map_has_materials = false
	_current_map_has_biological_resources = false
	_research_lead_text = ""
	_researched_pool_ids = []
	if world == null or day_state == null or not world.has_method("get_material_candidate_pools"):
		return report()
	var pools: Array = world.get_material_candidate_pools()
	_current_map_has_materials = not pools.is_empty()
	if world.has_method("get_biological_resource_sources"):
		_current_map_has_biological_resources = not world.get_biological_resource_sources().is_empty()
	var profile_report: Dictionary = _profile.report() if _profile != null else {}
	var completed_discoveries: Array = profile_report.get("completed_discoveries", [])
	var selected: Array[String] = day_state.material_selection_for(str(world.map_id), pools, completed_discoveries, active_condition_ids)
	_researched_pool_ids = day_state.material_researched_pool_ids(str(world.map_id))
	_research_lead_text = PracticalResearchPresentation.lead_text(pools, _researched_pool_ids)
	var depleted: Array[String] = day_state.material_depleted_ids(str(world.map_id))
	world.configure_material_candidates(selected, depleted)
	return report()


func update_collection(world, position: Vector2, radius_px: float, day_state, occupied_salvage: int, capacity: int) -> Dictionary:
	if world == null or day_state == null or not world.has_method("get_material_candidate_near"):
		return {}
	var candidate: Dictionary = world.get_material_candidate_near(position, radius_px)
	if candidate.is_empty():
		return {}
	if occupied_salvage + held_count() >= capacity:
		return {"blocked": true, "note": "Cargo full - bank materials at boat", "candidate": candidate}
	var candidate_id := str(candidate.get("id", ""))
	if candidate_id.is_empty() or not world.collect_material_candidate(candidate_id):
		return {}
	if not _cargo.collect(candidate, str(world.map_id)):
		world.restore_material_candidate(candidate_id)
		return {}
	day_state.mark_material_depleted(str(world.map_id), candidate_id)
	return {
		"changed": true,
		"candidate": candidate,
		"note": "%s held - return to boat" % _display_material(str(candidate.get("material_id", "material"))),
	}


func collect_biological_source(source: Dictionary, map_id: String, occupied_salvage: int, capacity: int) -> Dictionary:
	if occupied_salvage + held_count() >= capacity:
		return {"blocked": true, "reason": "cargo_full", "note": "Cargo full - bank materials at boat"}
	var cargo_source := source.duplicate(true)
	cargo_source["cargo_source_type"] = "biological_resource"
	if not _cargo.collect(cargo_source, map_id):
		return {"changed": false, "reason": "cargo_rejected"}
	return {
		"changed": true,
		"reason": "collected",
		"source": cargo_source,
		"note": "%s held - return to boat" % _display_material(str(source.get("material_id", "material"))),
	}


func try_commit_at_boat(world, position: Vector2) -> Dictionary:
	if world == null or _profile == null or not world.has_method("is_inside_boat"):
		return {}
	if not world.is_inside_boat(position) or held_count() <= 0:
		return {}
	var quantities := _cargo.quantities()
	var deposit: Dictionary = _profile.deposit_materials(quantities, true)
	if not bool(deposit.get("changed", false)):
		return {
			"changed": false,
			"reason": deposit.get("reason", "storage_error"),
			"note": "Material bank failed - cargo retained",
		}
	_cargo.clear()
	return {
		"changed": true,
		"reason": "banked",
		"banked": quantities,
		"note": "Materials banked at boat",
	}


func restore_unbanked(world, day_state, reason := "failure") -> Dictionary:
	var entries := _cargo.clear()
	for entry in entries:
		if str(entry.get("cargo_source_type", "material_candidate")) == "biological_resource":
			continue
		var map_id := str(entry.get("map_id", ""))
		var candidate_id := str(entry.get("candidate_id", ""))
		day_state.restore_material_candidate(map_id, candidate_id)
		if world != null and str(world.map_id) == map_id and world.has_method("restore_material_candidate"):
			world.restore_material_candidate(candidate_id)
	return {"reason": reason, "restored_count": entries.size(), "entries": entries}


func discard_unbanked(reason := "discarded") -> Dictionary:
	var entries := _cargo.clear()
	return {"reason": reason, "discarded_count": entries.size(), "entries": entries}


func held_count() -> int:
	return _cargo.held_count()


func has_held() -> bool:
	return held_count() > 0


func held_quantities() -> Dictionary:
	return _cargo.quantities()


func banked_quantity(material_id: String) -> int:
	return _profile.material_quantity(material_id) if _profile != null else 0


func overlay_text(include_research_lead := true) -> String:
	var held := held_quantities()
	var titanium_banked := banked_quantity(TITANIUM_ID)
	var rubber_banked := banked_quantity(RUBBER_ID)
	var coil_banked := banked_quantity(COIL_ID)
	var gel_banked := banked_quantity(INSULATING_GEL_ID)
	var electrocyte_banked := banked_quantity(EEL_ELECTROCYTE_ID)
	var held_standard := int(held.get(TITANIUM_ID, 0)) + int(held.get(RUBBER_ID, 0)) + int(held.get(COIL_ID, 0))
	var lines: Array[String] = []
	if _current_map_has_materials or held_standard > 0 or titanium_banked > 0 or rubber_banked > 0 or coil_banked > 0:
		lines.append("Materials Ti %d (+%d) | Rubber %d (+%d) | Coil %d (+%d)" % [
			titanium_banked,
			int(held.get(TITANIUM_ID, 0)),
			rubber_banked,
			int(held.get(RUBBER_ID, 0)),
			coil_banked,
			int(held.get(COIL_ID, 0)),
		])
	if _current_map_has_biological_resources or gel_banked > 0 or electrocyte_banked > 0:
		lines.append("Bio Gel %d (+%d) | Electro %d (+%d)" % [
			gel_banked,
			int(held.get(INSULATING_GEL_ID, 0)),
			electrocyte_banked,
			int(held.get(EEL_ELECTROCYTE_ID, 0)),
		])
	if include_research_lead and not _research_lead_text.is_empty():
		lines.append(_research_lead_text)
	return "\n".join(lines)


func report() -> Dictionary:
	var value := _cargo.report()
	value["banked_materials"] = _profile.material_inventory() if _profile != null else {}
	value["current_map_has_materials"] = _current_map_has_materials
	value["current_map_has_biological_resources"] = _current_map_has_biological_resources
	value["researched_pool_ids"] = _researched_pool_ids.duplicate()
	value["research_lead_text"] = _research_lead_text
	return value


func _display_material(material_id: String) -> String:
	return material_id.replace("_", " ").capitalize()
