extends RefCounted

const ZONE_ID := "far_west_confined_wreck_oxygen_zone"
const WARNING_ZONE_ID := "far_west_confined_wreck_warning"
const PROTECTED_ENTRY_FEEDBACK_SECONDS := 1.5

var _zone := {}
var _zone_rect := Rect2()
var _warning_zone := {}
var _warning_rect := Rect2()
var _inside_zone := false
var _near_threshold := false
var _protected := false
var _exposure_seconds := 0.0
var _drain_multiplier := 1.0
var _note := ""
var _protected_feedback_seconds := 0.0


func on_map_loaded(world) -> void:
	_zone = {}
	_zone_rect = Rect2()
	_warning_zone = {}
	_warning_rect = Rect2()
	reset()
	if world == null or not world.has_method("get_marker_zone"):
		return
	var source: Dictionary = world.get_marker_zone(ZONE_ID)
	if source.is_empty() or not bool(source.get("oxygen_consumption_zone", false)):
		return
	_zone = source.duplicate(true)
	var tile_size := float(world.tile_size)
	_zone_rect = Rect2(
		Vector2(float(_zone.get("x", 0)), float(_zone.get("y", 0))) * tile_size,
		Vector2(float(_zone.get("w", 0)), float(_zone.get("h", 0))) * tile_size
	)
	var warning_source: Dictionary = world.get_marker_zone(WARNING_ZONE_ID)
	if (
		not warning_source.is_empty()
		and str(warning_source.get("oxygen_warning_for_zone_id", "")) == ZONE_ID
	):
		_warning_zone = warning_source.duplicate(true)
		_warning_rect = Rect2(
			Vector2(float(_warning_zone.get("x", 0)), float(_warning_zone.get("y", 0))) * tile_size,
			Vector2(float(_warning_zone.get("w", 0)), float(_warning_zone.get("h", 0))) * tile_size
		)


func update(position: Vector2, has_capability: Callable, delta: float) -> Dictionary:
	if _zone.is_empty():
		_clear_exposure()
		return report()

	var capability_id := str(_zone.get("required_capability_id", "")).strip_edges()
	var has_protection := (
		capability_id.is_empty()
		or (has_capability.is_valid() and bool(has_capability.call(capability_id)))
	)
	if not _zone_rect.has_point(position):
		_clear_exposure()
		if not _warning_zone.is_empty() and _warning_rect.has_point(position):
			_near_threshold = true
			_protected = has_protection
			_note = str(_warning_zone.get(
				"protected_warning_label" if has_protection else "oxygen_warning_label",
				"Rebreather ready" if has_protection else "Confined wreck ahead"
			))
		return report()

	var entered := not _inside_zone or _protected != has_protection
	_inside_zone = true
	_near_threshold = false
	_protected = has_protection

	if has_protection:
		_exposure_seconds = 0.0
		_drain_multiplier = 1.0
		if entered:
			_protected_feedback_seconds = PROTECTED_ENTRY_FEEDBACK_SECONDS
		else:
			_protected_feedback_seconds = maxf(
				0.0,
				_protected_feedback_seconds - maxf(0.0, delta)
			)
		_note = "Rebreather active" if _protected_feedback_seconds > 0.0 else ""
		return report()

	_protected_feedback_seconds = 0.0
	var frame_seconds := maxf(0.0, delta)
	var previous_exposure := _exposure_seconds
	_exposure_seconds += frame_seconds
	var grace_seconds := maxf(0.0, float(_zone.get("warning_grace_seconds", 0.0)))
	var label := str(_zone.get("oxygen_consumption_label", "Confined wreck air"))
	if _exposure_seconds <= grace_seconds:
		_drain_multiplier = 1.0
		_note = "%s | Retreat" % label
	else:
		var source_multiplier := maxf(
			1.0,
			float(_zone.get("unprotected_oxygen_drain_multiplier", 1.0))
		)
		var critical_seconds := minf(
			frame_seconds,
			maxf(0.0, _exposure_seconds - maxf(previous_exposure, grace_seconds))
		)
		_drain_multiplier = (
			((frame_seconds - critical_seconds) + critical_seconds * source_multiplier)
			/ frame_seconds
			if frame_seconds > 0.0
			else source_multiplier
		)
		_note = "%s | Oxygen x%d" % [label, int(source_multiplier)]
	return report()


func reset() -> void:
	_clear_exposure()


func overlay_text() -> String:
	return _note


func drain_multiplier() -> float:
	return _drain_multiplier


func report() -> Dictionary:
	return {
		"zone_id": str(_zone.get("id", "")),
		"inside": _inside_zone,
		"near_threshold": _near_threshold,
		"protected": _protected,
		"exposure_seconds": _exposure_seconds,
		"drain_multiplier": _drain_multiplier,
		"note": _note,
	}


func _clear_exposure() -> void:
	_inside_zone = false
	_near_threshold = false
	_protected = false
	_exposure_seconds = 0.0
	_drain_multiplier = 1.0
	_note = ""
	_protected_feedback_seconds = 0.0
