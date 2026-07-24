extends SceneTree

const PlayerScene := preload("res://scenes/player/Player.tscn")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := PlayerScene.instantiate()
	get_root().add_child(player)
	await process_frame
	player.set_physics_process(false)
	player.global_position = Vector2(400.0, 300.0)

	var cooldown_result := {
		"discharged": false,
		"reason": "cooldown",
		"attack_range_px": ShockProdController.ATTACK_RANGE_PX,
	}
	_expect(not player.show_shock_prod_action(cooldown_result, 1.0), "cooldown attempt faked a discharge")
	var report: Dictionary = player.get_shock_prod_presentation_report()
	_expect(not bool(report.get("visible", true)), "cooldown attempt made the field visible")
	_expect(int(report.get("discharge_count", -1)) == 0, "cooldown attempt incremented discharge count")

	var miss_endpoint: Vector2 = player.global_position + Vector2(ShockProdController.ATTACK_RANGE_PX, 0.0)
	var miss_result := {
		"discharged": true,
		"connected": false,
		"reason": "miss",
		"target_position": miss_endpoint,
		"attack_range_px": ShockProdController.ATTACK_RANGE_PX,
		"attack_half_angle_degrees": ShockProdController.ATTACK_HALF_ANGLE_DEGREES,
	}
	_expect(player.show_shock_prod_action(miss_result, 1.0), "ready miss did not show a discharge")
	report = player.get_shock_prod_presentation_report()
	_expect(bool(report.get("visible", false)), "miss discharge was not visible")
	_expect(not bool(report.get("connected", true)), "miss discharge reported a connection")
	_expect(is_equal_approx(float(report.get("range_pixels", 0.0)), ShockProdController.ATTACK_RANGE_PX), "presentation range drifted from controller")
	_expect(is_equal_approx(float(report.get("arc_half_angle_degrees", 0.0)), ShockProdController.ATTACK_HALF_ANGLE_DEGREES), "presentation cone drifted from controller targeting")
	_expect(str(report.get("range_shape", "")) == "forward_cone", "presentation did not report a forward cone")
	_expect(str(report.get("miss_feedback", "")) == "directional_fizzle", "miss did not report directional fizzle feedback")
	_expect((report.get("endpoint_local", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(ShockProdController.ATTACK_RANGE_PX, 0.0)), "miss did not reach the range edge")
	_expect(int(report.get("bolt_count", 0)) >= 2 and int(report.get("bolt_segments", 0)) >= 5, "electrical bolt was not meaningfully segmented")

	var field := player.get_node("ShockProdField")
	field._process(1.0)
	_expect(not bool(player.get_shock_prod_presentation_report().get("visible", true)), "brief discharge did not clear")

	var target_position: Vector2 = player.global_position + Vector2(54.0, 12.0)
	var hit_result := {
		"discharged": true,
		"connected": true,
		"reason": "interrupted",
		"id": "deep_cache_territorial_eel",
		"target_position": target_position,
		"attack_range_px": ShockProdController.ATTACK_RANGE_PX,
		"attack_half_angle_degrees": ShockProdController.ATTACK_HALF_ANGLE_DEGREES,
	}
	_expect(player.show_shock_prod_action(hit_result, 1.0), "hit did not show a discharge")
	report = player.get_shock_prod_presentation_report()
	_expect(bool(report.get("connected", false)), "hit did not report a connected arc")
	_expect(str(report.get("target_id", "")) == "deep_cache_territorial_eel", "hit arc omitted the eel id")
	_expect((report.get("endpoint_local", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(54.0, 12.0)), "hit arc did not terminate at the target")

	field._process(1.0)
	var left_miss := miss_result.duplicate(true)
	left_miss["target_position"] = player.global_position + Vector2(-ShockProdController.ATTACK_RANGE_PX, 0.0)
	_expect(player.show_shock_prod_action(left_miss, -1.0), "left-facing miss did not show a discharge")
	report = player.get_shock_prod_presentation_report()
	_expect(float(report.get("facing_sign", 0.0)) < 0.0, "left-facing discharge retained right-facing state")
	_expect((report.get("endpoint_local", Vector2.ZERO) as Vector2).x < 0.0, "left-facing discharge remained on the right")
	_expect(int(report.get("discharge_count", 0)) == 3, "discharge count did not distinguish cooldown from three real attempts")

	player.queue_free()
	await process_frame
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: Shock Prod presentation range=72 forward_cone=35deg miss=edge_fizzle hit=target electrical_bolts=3 cooldown=no_fake_discharge facing=both.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
