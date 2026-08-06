extends RefCounted

const MATERIAL_LABELS := {
	"titanium_scrap": "Titanium scrap",
	"rubber_sheet": "Rubber sheet",
	"conductive_coil": "Conductive coil",
	"insulating_gel": "Insulating gel",
	"eel_electrocyte": "Eel electrocyte",
}


func subjects(world, required_mode := "") -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	var seen := {}
	if str(required_mode) != "identify":
		_append_progression_subjects(values, seen, world)
	if str(required_mode) == "progression":
		return values
	_append_ecological_traces(values, seen, world)
	_append_tool_targets(values, seen, world)
	_append_salvage(values, seen, world)
	_append_materials(values, seen, world)
	_append_hostiles(values, seen, world)
	_append_biological_sources(values, seen, world)
	_append_static_hazards(values, seen, world)
	_append_moving_hazards(values, seen, world)
	_append_current_gates(values, seen, world)
	_append_landmarks(values, seen, world)
	_append_progression_containers(values, seen, world)
	_append_boat(values, seen, world)
	return values


func _append_progression_subjects(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_survey_targets"):
		var target: Dictionary = source.duplicate(true)
		var target_id := str(target.get("id", "")).strip_edges()
		if target_id.is_empty():
			continue
		target["scanner_subject_mode"] = "progression"
		target["scan_priority"] = 0
		target["scan_subject_id"] = str(target.get("scan_subject_id", target_id))
		target["scan_subject_kind"] = str(target.get("scan_subject_kind", "environment"))
		target["scan_subject_label"] = _first_label(
			target,
			["scan_subject_label", "interaction_label", "clue_label"],
			target_id
		)
		target["scan_subject_description"] = _first_label(
			target,
			["scan_subject_description", "clue_label"],
			"Progression survey target"
		)
		target["scan_presentation_id"] = str(target.get("scan_presentation_id", "survey_signal"))
		_append_unique(values, seen, target)


func _append_ecological_traces(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_ecological_traces"):
		if str(source.get("state", "hidden")) not in ["revealed", "identified"]:
			continue
		_append_identification(
			values,
			seen,
			"ecological_trace",
			source,
			_first_label(source, ["display_label", "trace_label"], "Veil Cuttle trace"),
			"Revealed environmental evidence",
			"environment"
		)


func _append_salvage(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_salvage_centers"):
		var source_id := str(source.get("id", ""))
		if world.has_method("is_salvage_collected") and world.is_salvage_collected(source_id):
			continue
		var tier := str(source.get("tier", "common")).capitalize()
		_append_identification(
			values,
			seen,
			"salvage",
			source,
			_first_label(source, ["destination_payoff_label", "interaction_label"], source_id),
			"%s salvage" % tier,
			"artifact"
		)


func _append_materials(values: Array[Dictionary], seen: Dictionary, world) -> void:
	var report := _world_report(world, &"get_material_candidate_report")
	var active_ids: Array = report.get("active_ids", [])
	var depleted_ids: Array = report.get("depleted_ids", [])
	for source in _world_array(world, &"get_material_candidates"):
		var source_id := str(source.get("id", ""))
		if not active_ids.has(source_id) or depleted_ids.has(source_id):
			continue
		var material_id := str(source.get("material_id", ""))
		_append_identification(
			values,
			seen,
			"material",
			source,
			str(MATERIAL_LABELS.get(material_id, _humanize(material_id))),
			"Crafting material",
			"resource"
		)


func _append_tool_targets(values: Array[Dictionary], seen: Dictionary, world) -> void:
	var collected_ids: Array = _world_report(world, &"get_tool_target_report").get("collected_ids", [])
	for source in _world_array(world, &"get_tool_targets"):
		if collected_ids.has(str(source.get("id", ""))):
			continue
		_append_identification(
			values,
			seen,
			"tool_target",
			source,
			_first_label(source, ["interaction_label"], str(source.get("kind", ""))),
			"Sealed salvage target | Cutter required",
			"artifact"
		)


func _append_hostiles(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_hostile_encounters"):
		_append_identification(
			values,
			seen,
			"hostile",
			source,
			_first_label(source, ["display_label", "species_label"], "Territorial eel"),
			"Territorial wildlife",
			"creature",
			"home_center"
		)


func _append_biological_sources(values: Array[Dictionary], seen: Dictionary, world) -> void:
	var states: Dictionary = _world_report(world, &"get_biological_resource_visual_report").get("states", {})
	for source in _world_array(world, &"get_biological_resource_sources"):
		var source_id := str(source.get("id", ""))
		if str(states.get(source_id, "")) in ["hidden", "depleted"]:
			continue
		_append_identification(
			values,
			seen,
			"biological",
			source,
			_first_label(source, ["display_label"], str(source.get("material_id", ""))),
			"Biological material source",
			"resource"
		)


func _append_static_hazards(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_hazard_centers"):
		_append_identification(
			values,
			seen,
			"hazard",
			source,
			_first_label(source, ["display_label"], str(source.get("id", "Hazard"))),
			"Environmental hazard",
			"hazard"
		)


func _append_moving_hazards(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_moving_hazards"):
		_append_identification(
			values,
			seen,
			"wildlife",
			source,
			_first_label(source, ["display_label"], str(source.get("kind", "Wildlife"))),
			"Moving wildlife hazard",
			"creature"
		)


func _append_current_gates(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_current_gates"):
		var requirement := str(source.get("required_capability_id", source.get("required_upgrade_id", "")))
		var description := "Strong current"
		if not requirement.is_empty():
			description += " | %s required" % _humanize(requirement)
		_append_identification(
			values,
			seen,
			"current",
			source,
			_first_label(source, ["current_gate_label"], "Current barrier"),
			description,
			"environment"
		)


func _append_landmarks(values: Array[Dictionary], seen: Dictionary, world) -> void:
	if world == null or not world.has_method("get_marker_zone"):
		return
	for journey in _world_array(world, &"get_regional_journeys"):
		var zone_id := str(journey.get("landmark_zone_id", ""))
		var source: Dictionary = world.get_marker_zone(zone_id)
		if source.is_empty():
			continue
		source["id"] = zone_id
		source["center"] = _rect_center(source, float(world.get("tile_size")))
		_append_identification(
			values,
			seen,
			"landmark",
			source,
			_first_label(source, ["landmark_label"], zone_id),
			"Regional landmark",
			"environment"
		)


func _append_progression_containers(values: Array[Dictionary], seen: Dictionary, world) -> void:
	for source in _world_array(world, &"get_progression_containers"):
		_append_identification(
			values,
			seen,
			"container",
			source,
			_first_label(source, ["display_label", "reward_label"], "Equipment cache"),
			"Progression cache",
			"artifact"
		)


func _append_boat(values: Array[Dictionary], seen: Dictionary, world) -> void:
	if world == null or not world.has_method("get_extraction_center"):
		return
	_append_identification(
		values,
		seen,
		"boat",
		{"id": "surface_boat", "center": world.get_extraction_center()},
		"Surface boat",
		"Cargo offload and oxygen refill",
		"environment"
	)


func _append_identification(
	values: Array[Dictionary],
	seen: Dictionary,
	source_type: String,
	source: Dictionary,
	label: String,
	description: String,
	subject_kind: String,
	center_field := "center"
) -> void:
	var source_id := str(source.get("id", "")).strip_edges()
	var center = source.get(center_field, Vector2.ZERO)
	if source_id.is_empty() or not center is Vector2:
		return
	var target := {
		"id": "identify_%s_%s" % [source_type, source_id],
		"source_id": source_id,
		"source_type": source_type,
		"scanner_subject_mode": "identify",
		"scan_priority": 1,
		"scan_subject_id": source_id,
		"scan_subject_kind": subject_kind,
		"scan_subject_label": label,
		"scan_subject_description": description,
		"scan_presentation_id": "identify_%s" % source_type,
		"scan_anchor_world": center,
	}
	_append_unique(values, seen, target)


func _append_unique(values: Array[Dictionary], seen: Dictionary, target: Dictionary) -> void:
	var subject_id := str(target.get("scan_subject_id", ""))
	if subject_id.is_empty() or seen.has(subject_id):
		return
	seen[subject_id] = true
	values.append(target)


func _first_label(source: Dictionary, fields: Array, fallback: String) -> String:
	for field in fields:
		var value := str(source.get(field, "")).strip_edges()
		if not value.is_empty():
			return value
	return _humanize(fallback)


func _humanize(value: String) -> String:
	var text := value.replace("_", " ").strip_edges()
	return text.substr(0, 1).to_upper() + text.substr(1) if not text.is_empty() else "Unknown subject"


func _rect_center(source: Dictionary, tile_size: float) -> Vector2:
	return Vector2(
		float(source.get("x", 0)) + float(source.get("w", 1)) * 0.5,
		float(source.get("y", 0)) + float(source.get("h", 1)) * 0.5
	) * tile_size


func _world_array(world, method_name: StringName) -> Array:
	if world == null or not world.has_method(method_name):
		return []
	var value = world.call(method_name)
	return value if value is Array else []


func _world_report(world, method_name: StringName) -> Dictionary:
	if world == null or not world.has_method(method_name):
		return {}
	var value = world.call(method_name)
	return value if value is Dictionary else {}
