extends RefCounted

const GreyboxWorldQueries := preload("res://scripts/world/greybox_world_queries.gd")
const ScannerConeTargeting := preload("res://scripts/main/scanner_cone_targeting.gd")
const SurveyInteractionController := preload("res://scripts/main/survey_interaction_controller.gd")


class FakeWorld:
	extends RefCounted
	var tile_size := 32
	var targets: Array = []
	var blocked_anchors: Array[Vector2] = []

	func get_survey_targets() -> Array:
		return targets

	func has_clear_terrain_line(_origin: Vector2, anchor: Vector2) -> bool:
		return not blocked_anchors.has(anchor)


var _failures: Array[String] = []


func run() -> Dictionary:
	_failures = []
	var targeting := ScannerConeTargeting.new()
	var world := FakeWorld.new()
	var ahead := _target("ahead", Vector2(96.0, 0.0))
	_expect(bool(targeting.evaluate_target(world, Vector2.ZERO, 1.0, ahead).get("eligible", false)), "ahead target was rejected")
	_expect(bool(targeting.evaluate_target(world, Vector2.ZERO, 1.0, _target("range_edge", Vector2(192.0, 0.0))).get("eligible", false)), "six-tile range edge was rejected")
	_expect(bool(targeting.evaluate_target(world, Vector2.ZERO, 1.0, _target("angle_edge", Vector2(96.0, tan(deg_to_rad(30.0)) * 96.0))).get("eligible", false)), "30-degree cone edge was rejected")
	_expect(targeting.evaluate_target(world, Vector2.ZERO, -1.0, ahead).get("reason") == "behind", "behind target was accepted")
	_expect(targeting.evaluate_target(world, Vector2.ZERO, 1.0, _target("off_axis", Vector2(96.0, 96.0))).get("reason") == "off_axis", "off-axis target was accepted")
	_expect(targeting.evaluate_target(world, Vector2.ZERO, 1.0, _target("out_of_range", Vector2(193.0, 0.0))).get("reason") == "out_of_range", "out-of-range target was accepted")

	world.blocked_anchors = [Vector2(96.0, 0.0)]
	_expect(targeting.evaluate_target(world, Vector2.ZERO, 1.0, ahead).get("reason") == "occluded", "occluded target was accepted")
	world.blocked_anchors.clear()

	world.targets = [_target("far_straight", Vector2(160.0, 0.0)), _target("near_off_axis", Vector2(64.0, 1.0))]
	_expect(targeting.acquire(world, Vector2.ZERO, 1.0).get("target_id") == "far_straight", "angle did not win the deterministic ranking")
	world.targets = [_target("far", Vector2(128.0, 0.0)), _target("near", Vector2(64.0, 0.0))]
	_expect(targeting.acquire(world, Vector2.ZERO, 1.0).get("target_id") == "near", "distance did not break an angle tie")
	world.targets = [_target("beta", Vector2(64.0, 0.0)), _target("alpha", Vector2(64.0, 0.0))]
	_expect(targeting.acquire(world, Vector2.ZERO, 1.0).get("target_id") == "alpha", "stable id did not break an exact tie")

	_verify_active_cancellation(targeting, world, ahead)
	_verify_grid_occlusion()
	return {
		"passed": _failures.is_empty(),
		"failures": _failures.duplicate(),
		"range_tiles": int(ScannerConeTargeting.RANGE_TILES),
		"half_angle_degrees": int(ScannerConeTargeting.HALF_ANGLE_DEGREES),
		"ranking": "angle,distance,id",
		"cancellation": "turn,move,occlusion",
	}


func _verify_active_cancellation(targeting, world, target: Dictionary) -> void:
	var interaction := SurveyInteractionController.new()
	interaction.activate(target)
	interaction.update(target, 1.0)
	_expect(float(interaction.report().get("progress", 0.0)) > 0.0, "active survey did not gain progress")
	var turned: Dictionary = targeting.evaluate_target(world, Vector2.ZERO, -1.0, target)
	_expect(interaction.update(target if bool(turned.get("eligible", false)) else {}, 0.0).get("state") == "canceled", "turning away did not cancel")
	_expect(is_zero_approx(float(interaction.report().get("progress", -1.0))), "turn cancellation retained progress")

	interaction.activate(target)
	interaction.update(target, 1.0)
	var moved: Dictionary = targeting.evaluate_target(world, Vector2(-200.0, 0.0), 1.0, target)
	_expect(interaction.update(target if bool(moved.get("eligible", false)) else {}, 0.0).get("state") == "canceled", "leaving range did not cancel")

	interaction.activate(target)
	interaction.update(target, 1.0)
	world.blocked_anchors.clear()
	world.blocked_anchors.append(target.get("scan_anchor_world", Vector2.ZERO) as Vector2)
	var occluded: Dictionary = targeting.evaluate_target(world, Vector2.ZERO, 1.0, target)
	_expect(interaction.update(target if bool(occluded.get("eligible", false)) else {}, 0.0).get("state") == "canceled", "new occlusion did not cancel")
	world.blocked_anchors.clear()


func _verify_grid_occlusion() -> void:
	var queries := GreyboxWorldQueries.new()
	var solids := {Vector2i(2, 1): true}
	_expect(not queries.has_clear_terrain_line(Vector2(48.0, 48.0), Vector2(112.0, 48.0), Vector2i(6, 6), 32, solids), "solid terrain did not block the line")
	_expect(queries.has_clear_terrain_line(Vector2(48.0, 80.0), Vector2(112.0, 80.0), Vector2i(6, 6), 32, solids), "open terrain blocked the line")


func _target(target_id: String, anchor: Vector2) -> Dictionary:
	return {
		"id": target_id,
		"scan_anchor_world": anchor,
		"interaction_seconds": 3.0,
		"interaction_label": "Survey target",
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
