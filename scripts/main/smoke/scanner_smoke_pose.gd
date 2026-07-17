extends RefCounted

const ScannerConeTargeting := preload("res://scripts/main/scanner_cone_targeting.gd")


func find_pose(world, target: Dictionary) -> Dictionary:
	if world == null or target.is_empty():
		return {"found": false}
	var anchor: Vector2 = target.get("scan_anchor_world", target.get("center", Vector2.ZERO))
	var tile_size := float(world.get("tile_size"))
	var targeting := ScannerConeTargeting.new()
	var attempts: Array = []
	for distance_tiles in [2.0, 1.0, 3.0, 4.0, 5.0]:
		for facing_sign in [1.0, -1.0]:
			var origin := anchor - Vector2(facing_sign * distance_tiles * tile_size, 0.0)
			var report: Dictionary = targeting.evaluate_target(world, origin, facing_sign, target)
			var attempt := targeting.public_report(report)
			attempt["origin"] = origin
			attempt["facing_sign"] = facing_sign
			attempts.append(attempt)
			if bool(report.get("eligible", false)):
				return {
					"found": true,
					"origin": origin,
					"facing_sign": facing_sign,
					"target_id": str(target.get("id", "")),
				}
	return {"found": false, "target_id": str(target.get("id", "")), "attempts": attempts}


func place(world, player, target: Dictionary) -> Dictionary:
	var pose := find_pose(world, target)
	if not bool(pose.get("found", false)) or player == null:
		return pose
	var origin: Vector2 = pose.get("origin", Vector2.ZERO)
	var facing_sign := float(pose.get("facing_sign", 1.0))
	player.global_position = origin
	if player.has_method("face_scanner_direction"):
		player.face_scanner_direction(facing_sign)
	elif player.has_method("swim_in_direction"):
		player.swim_in_direction(Vector2(facing_sign, 0.0), 0.0)
		player.global_position = origin
		if player.has_method("reset_motion"):
			player.reset_motion()
	return pose
