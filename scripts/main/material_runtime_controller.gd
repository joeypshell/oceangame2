extends RefCounted

const MaterialCargoState := preload("res://scripts/main/material_cargo_state.gd")
const CANONICAL_MAP_ID := "production_slice_01"
const TITANIUM_ID := "titanium_scrap"
const COIL_ID := "conductive_coil"

var _profile
var _cargo := MaterialCargoState.new()
var _current_map_has_materials := false


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world, day_state) -> Dictionary:
	_current_map_has_materials = false
	if world == null or day_state == null or not world.has_method("get_material_candidate_pools"):
		return report()
	var pools: Array = world.get_material_candidate_pools()
	_current_map_has_materials = not pools.is_empty()
	var selected: Array[String] = day_state.material_selection_for(str(world.map_id), pools)
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


func try_commit_at_boat(world, position: Vector2) -> Dictionary:
	if world == null or _profile == null or str(world.map_id) != CANONICAL_MAP_ID:
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


func overlay_text() -> String:
	var held := held_quantities()
	var titanium_banked := banked_quantity(TITANIUM_ID)
	var coil_banked := banked_quantity(COIL_ID)
	if not _current_map_has_materials and held_count() <= 0 and titanium_banked <= 0 and coil_banked <= 0:
		return ""
	return "Materials Ti %d (+%d) | Coil %d (+%d)" % [
		titanium_banked,
		int(held.get(TITANIUM_ID, 0)),
		coil_banked,
		int(held.get(COIL_ID, 0)),
	]


func report() -> Dictionary:
	var value := _cargo.report()
	value["banked_materials"] = _profile.material_inventory() if _profile != null else {}
	value["current_map_has_materials"] = _current_map_has_materials
	return value


func _display_material(material_id: String) -> String:
	return material_id.replace("_", " ").capitalize()
