extends "res://scripts/main/smoke/smoke_check_base.gd"

const LIGHT_X := 88.0
const REVERSAL_SEQUENCE := [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.RIGHT,
]


func _smoke_pass_27_facing_transitions_and_quit() -> void:
	if not _player.has_method("swim_in_direction") or not _player.has_method("get_facing_report"):
		_fail("Pass 27 facing transition smoke requires swim_in_direction() and get_facing_report().")
		return

	_player.set_physics_process(false)
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var reports: Array[Dictionary] = []
	for direction in REVERSAL_SEQUENCE:
		_player.swim_in_direction(direction, 1.0 / 60.0)
		var report: Dictionary = _player.get_facing_report()
		reports.append(report)
		if not _report_matches_direction(report, direction):
			_fail("Pass 27 facing transition mismatch after %s: %s" % [_direction_label(direction), report])
			return

	if _player.has_method("reset_motion"):
		_player.reset_motion()
	var reset_report: Dictionary = _player.get_facing_report()
	if not _report_matches_direction(reset_report, REVERSAL_SEQUENCE.back()):
		_fail("Pass 27 facing transition reset mismatch: %s" % reset_report)
		return

	var final_report: Dictionary = reports.back()
	print("Pass 27 facing transition smoke passed: reversals=%d final_flip=%s final_light_x=%.1f final_light_scale_x=%.1f final_frame=%d clip=%s reset_frame=%d." % [
		REVERSAL_SEQUENCE.size() - 1,
		str(final_report.get("body_flip_h", null)),
		float(final_report.get("light_cone_position_x", 0.0)),
		float(final_report.get("light_cone_scale_x", 0.0)),
		int(final_report.get("body_frame", -1)),
		str(final_report.get("body_region_filter_clip_enabled", false)),
		int(reset_report.get("body_frame", -1)),
	])
	get_tree().quit()


func _report_matches_direction(report: Dictionary, direction: Vector2) -> bool:
	var expected_flip := direction.x < 0.0
	var expected_light_x := LIGHT_X if direction.x > 0.0 else -LIGHT_X
	var expected_light_scale_sign := 1.0 if direction.x > 0.0 else -1.0
	var frame := int(report.get("body_frame", -1))
	var hframes := int(report.get("body_hframes", 0))
	return (
		is_equal_approx(float(report.get("root_scale_x", 0.0)), 1.0)
		and bool(report.get("body_flip_h", not expected_flip)) == expected_flip
		and bool(report.get("body_region_filter_clip_enabled", false))
		and hframes == 4
		and frame >= 0
		and frame < hframes
		and is_equal_approx(float(report.get("light_cone_position_x", 0.0)), expected_light_x)
		and signf(float(report.get("light_cone_scale_x", 0.0))) == expected_light_scale_sign
		and float(report.get("light_cone_range_scale", 0.0)) > 0.0
		and float(report.get("light_cone_alpha", 0.0)) > 0.0
	)


func _direction_label(direction: Vector2) -> String:
	return "right" if direction.x > 0.0 else "left"


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
