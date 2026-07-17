extends SceneTree

const PlayerScene := preload("res://scenes/player/Player.tscn")
const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
const GreyboxSurveyTargets := preload("res://scripts/world/greybox_survey_targets.gd")

var _failures: Array[String] = []
var _mobile_scanner_event: InputEvent


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := PlayerScene.instantiate()
	get_root().add_child(player)
	await process_frame
	player.set_physics_process(false)
	player.global_position = Vector2(400.0, 300.0)

	var original_facing: Dictionary = player.get_facing_report()
	var miss_report := _runtime_report(false, 0.0, "", Vector2.ZERO)
	player.show_scanner_action({"reason": "ready"}, miss_report)
	var presentation: Dictionary = player.get_scanner_presentation_report()
	_expect(bool(presentation.get("visible", false)), "missed pulse did not show the scanner field")
	_expect(not bool(presentation.get("active", true)), "missed pulse incorrectly reported an active scan")
	_expect(not bool(presentation.get("target_visible", true)), "missed pulse highlighted a nonexistent target")
	_expect(is_equal_approx(float(presentation.get("range_pixels", 0.0)), 192.0), "scanner field was not six 32px tiles long")
	_expect(is_equal_approx(float(presentation.get("half_angle_degrees", 0.0)), 30.0), "scanner field was not 30 degrees wide per side")

	var scanner_field := player.get_node("ScannerField")
	scanner_field._process(1.0)
	presentation = player.get_scanner_presentation_report()
	_expect(not bool(presentation.get("visible", true)), "missed pulse did not clear after its brief display")

	var right_anchor: Vector2 = player.global_position + Vector2(120.0, 18.0)
	var active_report := _runtime_report(true, 0.42, "artifact_subject", right_anchor)
	player.show_scanner_action({"reason": "activated", "target_id": "artifact_subject"}, active_report)
	scanner_field._process(1.0)
	presentation = player.get_scanner_presentation_report()
	_expect(bool(presentation.get("visible", false)), "active scan did not keep the scanner field visible")
	_expect(bool(presentation.get("active", false)), "active scan was not reported as active")
	_expect(bool(presentation.get("target_visible", false)), "acquired physical subject was not bracketed")
	_expect(str(presentation.get("target_id", "")) == "artifact_subject", "scanner bracket selected the wrong subject")
	_expect((presentation.get("target_local_position", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(120.0, 18.0)), "scanner bracket did not use the authored scan anchor")
	_expect(is_equal_approx(float(presentation.get("progress", 0.0)), 0.42), "scanner progress did not match runtime progress")
	_expect((presentation.get("progress_size", Vector2.ZERO) as Vector2) == Vector2(40.0, 4.0), "scanner progress dimensions drifted")
	_expect(_facing_unchanged(original_facing, player.get_facing_report()), "scanner presentation changed player sprite or light facing")

	player.swim_in_direction(Vector2.LEFT, 0.0)
	var left_anchor: Vector2 = player.global_position + Vector2(-120.0, 18.0)
	player.sync_scanner_presentation(_runtime_report(true, 0.65, "artifact_subject", left_anchor))
	presentation = player.get_scanner_presentation_report()
	_expect(is_equal_approx(float(presentation.get("facing_sign", 0.0)), -1.0), "scanner field did not follow left-facing state")
	_expect((presentation.get("target_local_position", Vector2.ZERO) as Vector2).x < 0.0, "left-facing target bracket remained on the right")

	player.sync_scanner_presentation(_runtime_report(false, 0.0, "", Vector2.ZERO))
	presentation = player.get_scanner_presentation_report()
	_expect(not bool(presentation.get("visible", true)), "cancellation left the scanner cone visible")
	_expect(str(presentation.get("target_id", "")) == "", "cancellation left the target bracket visible")
	_expect(is_zero_approx(float(presentation.get("progress", 1.0))), "cancellation left stale scanner progress")

	await _verify_mobile_scan_command()
	_verify_world_subject_presentation()
	player.queue_free()
	await process_frame

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: scanner field range_tiles=6 half_angle=30 miss=pulse active=continuous subject=bracketed progress=compact cancel=clear mobile_scan=Q generic_rings=removed debug_outline=available.")
	quit(0)


func _runtime_report(active: bool, progress: float, target_id: String, anchor: Vector2) -> Dictionary:
	return {
		"scanner_unlocked": true,
		"interaction": {
			"activated": active,
			"active_target_id": target_id if active else "",
			"progress": progress,
		},
		"targeting": {
			"eligible": not target_id.is_empty(),
			"reason": "eligible" if not target_id.is_empty() else "no_target",
			"target_id": target_id,
			"scan_subject_id": "maintenance_case" if not target_id.is_empty() else "",
			"scan_presentation_id": "salvage_cutter_blueprint_case" if not target_id.is_empty() else "",
			"anchor": anchor,
			"range_pixels": 192.0,
		},
	}


func _verify_mobile_scan_command() -> void:
	var controls := MobileTestControls.new()
	controls.force_visible = true
	controls.command_dispatched.connect(_on_mobile_command)
	get_root().add_child(controls)
	await process_frame
	var report: Dictionary = controls.get_test_report()
	var scanner_rect: Rect2 = report.get("command_rects", {}).get(&"scanner", Rect2())
	_expect(scanner_rect.size != Vector2.ZERO, "mobile scanner control was not laid out")
	var press := InputEventScreenTouch.new()
	press.index = 17
	press.position = scanner_rect.get_center()
	press.pressed = true
	controls._input(press)
	var release := press.duplicate() as InputEventScreenTouch
	release.pressed = false
	controls._input(release)
	_expect(_mobile_scanner_event is InputEventKey, "mobile SCAN did not dispatch a keyboard event")
	if _mobile_scanner_event is InputEventKey:
		_expect((_mobile_scanner_event as InputEventKey).keycode == KEY_Q, "mobile SCAN did not use desktop Q semantics")
	var reachable_bottom := (report.get("viewport_size", Vector2.ZERO) as Vector2).y - float(report.get("bottom_inset", 0.0))
	_expect(scanner_rect.end.y <= reachable_bottom, "mobile SCAN extended below the reachable landscape inset")
	controls.queue_free()
	await process_frame


func _verify_world_subject_presentation() -> void:
	var targets := [
		{"id": "generic_signal", "x": 2, "y": 2, "w": 2, "h": 2},
		{
			"id": "artifact_subject",
			"x": 6,
			"y": 2,
			"w": 2,
			"h": 2,
			"scan_presentation_id": "salvage_cutter_blueprint_case",
		},
	]
	var normal_parent := Node2D.new()
	get_root().add_child(normal_parent)
	var normal_renderer := GreyboxSurveyTargets.new()
	normal_renderer.build(normal_parent, targets, 32, false)
	_expect(normal_parent.get_node_or_null("generic_signal/SurveyHaze") == null, "normal play still rendered survey haze")
	_expect(normal_parent.get_node_or_null("generic_signal/SurveyRing") == null, "normal play still rendered a generic survey ring")
	_expect(normal_parent.get_node_or_null("generic_signal/SurveyCore") == null, "normal play still rendered a generic survey core")
	_expect(normal_parent.get_node_or_null("generic_signal/SurveyAxis") == null, "normal play still rendered a generic survey axis")
	_expect(normal_parent.get_node_or_null("artifact_subject/MaintenanceCase") != null, "authored physical scan subject was removed")
	_expect(normal_parent.get_node_or_null("generic_signalDebugOutline") == null, "debug outline leaked into normal play")

	var debug_parent := Node2D.new()
	get_root().add_child(debug_parent)
	var debug_renderer := GreyboxSurveyTargets.new()
	debug_renderer.build(debug_parent, [targets[0]], 32, true)
	_expect(debug_parent.get_node_or_null("generic_signalDebugOutline") != null, "source debug outline was not available under the debug flag")
	normal_parent.queue_free()
	debug_parent.queue_free()


func _facing_unchanged(before: Dictionary, after: Dictionary) -> bool:
	return (
		is_equal_approx(float(before.get("root_scale_x", 0.0)), float(after.get("root_scale_x", 1.0)))
		and bool(before.get("body_flip_h", false)) == bool(after.get("body_flip_h", true))
		and is_equal_approx(float(before.get("light_cone_position_x", 0.0)), float(after.get("light_cone_position_x", 1.0)))
		and is_equal_approx(float(before.get("light_cone_scale_x", 0.0)), float(after.get("light_cone_scale_x", 1.0)))
	)


func _on_mobile_command(command_id: StringName, event: InputEvent) -> void:
	if command_id == &"scanner":
		_mobile_scanner_event = event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
