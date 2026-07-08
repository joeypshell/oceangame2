extends RefCounted

const PASS_11_CUE_MARKER_ID := "southwest_pocket_pre_pickup_cue"
const TARGET_UNCOLLECTED_CONDITION := "target_uncollected"


func current_prompt(world, player_position: Vector2) -> String:
	if world == null or not world.has_method("get_marker_zone"):
		return ""

	var marker: Dictionary = world.get_marker_zone(PASS_11_CUE_MARKER_ID)
	if marker.is_empty():
		return ""
	if not _marker_contains_position(marker, player_position, float(world.tile_size)):
		return ""
	if not _condition_is_met(world, marker):
		return ""

	return str(marker.get("cue_text", "")).strip_edges()


func _marker_contains_position(marker: Dictionary, position: Vector2, tile_size: float) -> bool:
	if tile_size <= 0.0:
		return false
	var marker_rect := Rect2(
		Vector2(float(marker.get("x", 0)), float(marker.get("y", 0))) * tile_size,
		Vector2(float(marker.get("w", 0)), float(marker.get("h", 0))) * tile_size
	)
	return marker_rect.has_point(position)


func _condition_is_met(world, marker: Dictionary) -> bool:
	var condition := str(marker.get("cue_condition", TARGET_UNCOLLECTED_CONDITION))
	if condition != TARGET_UNCOLLECTED_CONDITION:
		return false

	var target_id := str(marker.get("cue_target_id", ""))
	if target_id.is_empty() or not _target_exists(world, target_id):
		return false
	if not world.has_method("is_salvage_collected"):
		return false
	return not world.is_salvage_collected(target_id)


func _target_exists(world, target_id: String) -> bool:
	if not world.has_method("get_salvage_centers"):
		return true
	for salvage in world.get_salvage_centers():
		if str(salvage.get("id", "")) == target_id:
			return true
	return false
