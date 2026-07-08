extends RefCounted

const REST_MARKER_ID := "lower_loop_oxygen_rest_pocket"
const DEFAULT_LABEL := "Rest pocket"

var _current_prompt := ""
var _inside_rest_pocket := false


func reset() -> void:
	_current_prompt = ""
	_inside_rest_pocket = false


func current_prompt() -> String:
	return _current_prompt


func is_inside_rest_pocket() -> bool:
	return _inside_rest_pocket


func update(world, player_position: Vector2, oxygen_seconds: float, delta: float) -> Dictionary:
	reset()
	if world == null or not world.has_method("get_marker_zone"):
		return {"inside": false, "oxygen_seconds": oxygen_seconds}

	var marker: Dictionary = world.get_marker_zone(REST_MARKER_ID)
	if marker.is_empty() or not bool(marker.get("oxygen_rest", false)):
		return {"inside": false, "oxygen_seconds": oxygen_seconds}
	if not _marker_contains_position(marker, player_position, float(world.tile_size)):
		return {"inside": false, "oxygen_seconds": oxygen_seconds}

	_inside_rest_pocket = true
	var cap_seconds := maxf(0.0, float(marker.get("oxygen_rest_cap_seconds", oxygen_seconds)))
	var refill_per_second := maxf(0.0, float(marker.get("oxygen_rest_refill_per_second", 0.0)))
	var elapsed := maxf(0.0, delta)
	var after_normal_drain := maxf(0.0, oxygen_seconds - elapsed)
	var recovered_oxygen := after_normal_drain
	if after_normal_drain < cap_seconds and refill_per_second > 0.0:
		recovered_oxygen = minf(cap_seconds, after_normal_drain + refill_per_second * elapsed)

	var label := _display_label(marker)
	_current_prompt = "%s +oxygen" % label if recovered_oxygen > after_normal_drain else "%s cap %ds" % [label, int(ceil(cap_seconds))]
	return {
		"inside": true,
		"oxygen_seconds": recovered_oxygen,
		"recovering": recovered_oxygen > after_normal_drain,
		"cap_seconds": cap_seconds,
	}


func _marker_contains_position(marker: Dictionary, position: Vector2, tile_size: float) -> bool:
	if tile_size <= 0.0:
		return false
	var marker_rect := Rect2(
		Vector2(float(marker.get("x", 0)), float(marker.get("y", 0))) * tile_size,
		Vector2(float(marker.get("w", 0)), float(marker.get("h", 0))) * tile_size
	)
	return marker_rect.has_point(position)


func _display_label(marker: Dictionary) -> String:
	var label := str(marker.get("oxygen_rest_label", DEFAULT_LABEL)).strip_edges()
	if label.is_empty():
		label = DEFAULT_LABEL
	return label.replace("_", " ")
