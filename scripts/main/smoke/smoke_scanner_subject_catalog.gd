extends SceneTree

const ScannerConeTargeting := preload("res://scripts/main/scanner_cone_targeting.gd")
const ScannerSubjectCatalog := preload("res://scripts/main/scanner_subject_catalog.gd")

const EXPECTED_IDENTIFY_IDS := [
	"identify_biological_gel_source",
	"identify_boat_surface_boat",
	"identify_container_equipment_cache",
	"identify_current_archive_current",
	"identify_hazard_vent_hazard",
	"identify_hostile_territorial_eel",
	"identify_landmark_signal_reef_landmark",
	"identify_material_active_titanium",
	"identify_salvage_visible_salvage",
	"identify_tool_target_sealed_wreck",
	"identify_wildlife_patrol_fish",
]

var _failures: Array[String] = []


class FakeWorld:
	extends RefCounted

	var tile_size := 32

	func get_survey_targets() -> Array:
		return [{
			"id": "progression_relay",
			"scan_anchor_world": Vector2(160, 0),
			"interaction_label": "Survey wreck relay",
			"interaction_seconds": 3.0,
			"discovery_id": "relay_discovery",
		}]

	func get_salvage_centers() -> Array:
		return [
			{"id": "visible_salvage", "center": Vector2(64, 0), "tier": "valuable"},
			{"id": "collected_salvage", "center": Vector2(72, 0), "tier": "common"},
		]

	func is_salvage_collected(salvage_id: String) -> bool:
		return salvage_id == "collected_salvage"

	func get_material_candidates() -> Array:
		return [
			{"id": "active_titanium", "center": Vector2(80, 0), "material_id": "titanium_scrap"},
			{"id": "inactive_rubber", "center": Vector2(88, 0), "material_id": "rubber_sheet"},
			{"id": "depleted_coil", "center": Vector2(96, 0), "material_id": "conductive_coil"},
		]

	func get_material_candidate_report() -> Dictionary:
		return {
			"active_ids": ["active_titanium", "depleted_coil"],
			"depleted_ids": ["depleted_coil"],
		}

	func get_tool_targets() -> Array:
		return [
			{"id": "sealed_wreck", "center": Vector2(104, 0), "interaction_label": "Sealed wreck"},
			{"id": "opened_wreck", "center": Vector2(112, 0), "interaction_label": "Opened wreck"},
		]

	func get_tool_target_report() -> Dictionary:
		return {"collected_ids": ["opened_wreck"]}

	func get_hostile_encounters() -> Array:
		return [{"id": "territorial_eel", "home_center": Vector2(120, 0), "display_label": "Territorial eel"}]

	func get_biological_resource_sources() -> Array:
		return [
			{"id": "gel_source", "center": Vector2(128, 0), "display_label": "Insulating gel"},
			{"id": "hidden_source", "center": Vector2(136, 0), "display_label": "Hidden source"},
		]

	func get_biological_resource_visual_report() -> Dictionary:
		return {"states": {"gel_source": "available", "hidden_source": "hidden"}}

	func get_hazard_centers() -> Array:
		return [{"id": "vent_hazard", "center": Vector2(140, 0)}]

	func get_moving_hazards() -> Array:
		return [{"id": "patrol_fish", "center": Vector2(144, 0), "display_label": "Reef patrol"}]

	func get_current_gates() -> Array:
		return [{
			"id": "archive_current",
			"center": Vector2(152, 0),
			"current_gate_label": "Northwest archive current",
			"required_capability_id": "current_stabilizer",
		}]

	func get_regional_journeys() -> Array:
		return [{"landmark_zone_id": "signal_reef_landmark"}]

	func get_marker_zone(marker_id: String) -> Dictionary:
		return {"id": marker_id, "x": 5, "y": 0, "w": 1, "h": 1, "landmark_label": "Signal Reef"}

	func get_progression_containers() -> Array:
		return [{"id": "equipment_cache", "center": Vector2(176, 0), "display_label": "Equipment cache"}]

	func get_extraction_center() -> Vector2:
		return Vector2(184, 0)

	func has_clear_terrain_line(_origin: Vector2, _anchor: Vector2) -> bool:
		return true


func _init() -> void:
	var world := FakeWorld.new()
	var subjects: Array[Dictionary] = ScannerSubjectCatalog.new().subjects(world)
	var progression := _subject_by_id(subjects, "progression_relay")
	_expect(progression.get("scanner_subject_mode") == "progression", "authored survey did not remain a progression subject")
	_expect(int(progression.get("scan_priority", -1)) == 0, "progression subject lost deterministic priority")

	var identify_ids: Array[String] = []
	for subject in subjects:
		if str(subject.get("scanner_subject_mode", "")) != "identify":
			continue
		identify_ids.append(str(subject.get("id", "")))
		_expect(int(subject.get("scan_priority", -1)) == 1, "%s used the wrong identification priority" % subject.get("id"))
		_expect(not str(subject.get("scan_subject_label", "")).is_empty(), "%s omitted a display label" % subject.get("id"))
		_expect(not str(subject.get("scan_subject_kind", "")).is_empty(), "%s omitted a subject type" % subject.get("id"))
		for forbidden_field in ["discovery_id", "scan_reward_id", "score", "reward_id"]:
			_expect(not subject.has(forbidden_field), "%s ordinary identification exposed reward field %s" % [subject.get("id"), forbidden_field])
	identify_ids.sort()
	_expect(identify_ids == EXPECTED_IDENTIFY_IDS, "scanner identification catalog drifted: %s" % [identify_ids])
	var sealed_wreck := _subject_by_id(subjects, "identify_tool_target_sealed_wreck")
	_expect(
		str(sealed_wreck.get("scan_subject_description", "")).find("Cutter required") != -1,
		"sealed tool target identification omitted cutter guidance"
	)

	var targeting := ScannerConeTargeting.new()
	var acquired: Dictionary = targeting.acquire(world, Vector2.ZERO, 1.0)
	_expect(acquired.get("target_id") == "progression_relay", "nearer ordinary subject displaced the progression target")
	var public_report: Dictionary = targeting.public_report(acquired)
	_expect(public_report.get("requires_hold") == true, "progression target did not require held scanning")
	_expect(public_report.get("scan_subject_label") == "Survey wreck relay", "public targeting report omitted the source label")

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: scanner subject catalog progression=priority0 identify=11 reward_free=true filtered=collected+inactive+depleted+hidden categories=salvage,material,tool,hostile,biological,hazard,wildlife,current,landmark,container,boat.")
	quit(0)


func _subject_by_id(subjects: Array[Dictionary], subject_id: String) -> Dictionary:
	for subject in subjects:
		if str(subject.get("id", "")) == subject_id:
			return subject
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
