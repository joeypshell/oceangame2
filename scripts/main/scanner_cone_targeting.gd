extends RefCounted

const RANGE_TILES := 6.0
const HALF_ANGLE_DEGREES := 30.0
const COMPARISON_EPSILON := 0.0001


func acquire(world, origin: Vector2, facing_sign: float) -> Dictionary:
	if world == null or not world.has_method("get_survey_targets"):
		return _empty_report("world_unavailable")
	var best := {}
	for target in world.get_survey_targets():
		var report := evaluate_target(world, origin, facing_sign, target)
		if bool(report.get("eligible", false)) and (best.is_empty() or _precedes(report, best)):
			best = report
	return best if not best.is_empty() else _empty_report("no_target")


func evaluate_target(world, origin: Vector2, facing_sign: float, target: Dictionary) -> Dictionary:
	var target_id := str(target.get("id", "")).strip_edges()
	if target_id.is_empty():
		return _empty_report("invalid_target")
	var anchor := _target_anchor(target)
	var tile_size := float(world.get("tile_size")) if world != null else 0.0
	if tile_size <= 0.0:
		return _target_report(target, anchor, 0.0, 0.0, 0.0, false, "invalid_tile_size")

	var offset := anchor - origin
	var distance := offset.length()
	var range_pixels := RANGE_TILES * tile_size
	var normalized_facing := 1.0 if facing_sign >= 0.0 else -1.0
	var forward_distance := offset.x * normalized_facing
	var angle_degrees := rad_to_deg(atan2(absf(offset.y), forward_distance)) if forward_distance > 0.0 else 180.0
	if forward_distance <= 0.0:
		return _target_report(target, anchor, angle_degrees, distance, range_pixels, false, "behind")
	if distance > range_pixels + COMPARISON_EPSILON:
		return _target_report(target, anchor, angle_degrees, distance, range_pixels, false, "out_of_range")
	if angle_degrees > HALF_ANGLE_DEGREES + COMPARISON_EPSILON:
		return _target_report(target, anchor, angle_degrees, distance, range_pixels, false, "off_axis")
	if world == null or not world.has_method("has_clear_terrain_line") or not world.has_clear_terrain_line(origin, anchor):
		return _target_report(target, anchor, angle_degrees, distance, range_pixels, false, "occluded")
	return _target_report(target, anchor, angle_degrees, distance, range_pixels, true, "eligible")


func target_by_id(world, target_id: String) -> Dictionary:
	if world == null or not world.has_method("get_survey_targets"):
		return {}
	for target in world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func public_report(report: Dictionary) -> Dictionary:
	var result := report.duplicate(true)
	result.erase("target")
	return result


func _precedes(candidate: Dictionary, incumbent: Dictionary) -> bool:
	var candidate_angle := float(candidate.get("angle_degrees", 180.0))
	var incumbent_angle := float(incumbent.get("angle_degrees", 180.0))
	if absf(candidate_angle - incumbent_angle) > COMPARISON_EPSILON:
		return candidate_angle < incumbent_angle
	var candidate_distance := float(candidate.get("distance_pixels", INF))
	var incumbent_distance := float(incumbent.get("distance_pixels", INF))
	if absf(candidate_distance - incumbent_distance) > COMPARISON_EPSILON:
		return candidate_distance < incumbent_distance
	return str(candidate.get("target_id", "")) < str(incumbent.get("target_id", ""))


func _target_anchor(target: Dictionary) -> Vector2:
	var anchor = target.get("scan_anchor_world", target.get("center", Vector2.ZERO))
	return anchor if anchor is Vector2 else Vector2.ZERO


func _target_report(
	target: Dictionary,
	anchor: Vector2,
	angle_degrees: float,
	distance_pixels: float,
	range_pixels: float,
	eligible: bool,
	reason: String
) -> Dictionary:
	return {
		"eligible": eligible,
		"reason": reason,
		"target_id": str(target.get("id", "")),
		"anchor": anchor,
		"angle_degrees": angle_degrees,
		"distance_pixels": distance_pixels,
		"range_pixels": range_pixels,
		"target": target,
	}


func _empty_report(reason: String) -> Dictionary:
	return {
		"eligible": false,
		"reason": reason,
		"target_id": "",
		"anchor": Vector2.ZERO,
		"angle_degrees": 0.0,
		"distance_pixels": 0.0,
		"range_pixels": 0.0,
	}
