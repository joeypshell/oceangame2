extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CUTTLE_SCENE := preload("res://scenes/companion/VeilCuttleCompanion.tscn")
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const STEP_SECONDS := 1.0 / 30.0

var _failures: Array[String] = []
var _blocked_rect := Rect2()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	player.global_position = world.spawn_position
	var cuttle := CUTTLE_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(cuttle)
	cuttle.configure(
		world,
		player,
		Callable(self, "_position_allowed"),
		{"individual_id": "veil_cuttle_juvenile_01", "species_id": "veil_cuttle", "callsign": "Mica"}
	)
	cuttle.set_physics_process(false)
	await physics_frame

	var initial: Dictionary = cuttle.report()
	_expect(str(initial.get("species_id", "")) == "veil_cuttle", "Mica did not report Veil Cuttle identity")
	_expect(str(initial.get("presentation", {}).get("callsign", "")) == "Mica", "Mica presentation lost her callsign")
	_expect(not bool(initial.get("mounted", true)), "Mica exposed mounted state")
	_test_investigations(world, player, cuttle)
	_test_separation_and_recovery(world, player, cuttle)
	_test_locked_gate(world, player, cuttle)
	_finish(world, player, cuttle)


func _test_investigations(world, player, cuttle) -> void:
	_blocked_rect = Rect2()
	player.global_position = world.spawn_position
	cuttle.recover_to_player()
	var maximum_distance := 0.0
	var stayed_open := true
	for _index in range(150):
		cuttle.advance(STEP_SECONDS)
		maximum_distance = maxf(maximum_distance, cuttle.global_position.distance_to(player.global_position))
		stayed_open = stayed_open and not world.find_open_path(cuttle.global_position, cuttle.global_position).is_empty()
	var report: Dictionary = cuttle.report()
	_expect(int(report.get("investigation_count", 0)) >= 1, "close-follow Mica never began a deterministic investigation")
	_expect(maximum_distance <= 92.0, "investigation exceeded its close envelope at %.2fpx" % maximum_distance)
	_expect(stayed_open, "investigation entered solid terrain")


func _test_separation_and_recovery(world, player, cuttle) -> void:
	var route := _find_representative_route(world, cuttle.global_position)
	_expect(not route.is_empty(), "full level had no long gate-free Mica recovery fixture")
	if route.is_empty():
		return
	cuttle.global_position = route["origin"]
	player.global_position = route["target"]
	var before: Vector2 = cuttle.global_position
	cuttle.advance(0.05)
	var worried: Dictionary = cuttle.report()
	_expect(str(worried.get("state", "")) == "separated", "long separation skipped Mica's worried state")
	_expect(before.distance_to(cuttle.global_position) <= 0.01, "Mica moved before the readable separation hold")
	cuttle.request_recall()
	var recovery_seen := false
	var stayed_open := true
	for _index in range(1000):
		cuttle.advance(STEP_SECONDS)
		var report: Dictionary = cuttle.report()
		recovery_seen = recovery_seen or str(report.get("state", "")) == "recovery"
		stayed_open = stayed_open and not world.find_open_path(cuttle.global_position, cuttle.global_position).is_empty()
		if cuttle.global_position.distance_to(player.global_position) <= 72.0 and str(report.get("state", "")) in ["hover", "investigate"]:
			break
	_expect(recovery_seen, "Recall never entered deterministic Mica recovery")
	_expect(cuttle.global_position.distance_to(player.global_position) <= 72.0, "Mica did not recover through full-level geometry")
	_expect(stayed_open, "Mica recovery entered solid terrain")
	_expect(float(cuttle.report().get("maximum_step_distance", 999.0)) <= 10.0, "Mica recovery used a teleport-sized movement step")
	_expect(int(cuttle.report().get("facing_change_count", 999)) <= 14, "Mica recovery produced unstable direction flipping")


func _test_locked_gate(world, player, cuttle) -> void:
	var fixture := _find_gate_crossing(world)
	_expect(not fixture.is_empty(), "full level had no equipment-gate crossing fixture")
	if fixture.is_empty():
		return
	_blocked_rect = fixture["gate"].get("rect", Rect2())
	cuttle.global_position = fixture["before"]
	player.global_position = fixture["after"]
	var entered_gate := false
	for _index in range(180):
		cuttle.advance(STEP_SECONDS)
		entered_gate = entered_gate or _blocked_rect.has_point(cuttle.global_position)
	var report: Dictionary = cuttle.report()
	_expect(not entered_gate, "Mica entered an equipment gate without diver access")
	_expect(bool(report.get("path_blocked_by_gate", false)), "Mica did not report the blocked access path")
	_expect(str(report.get("state", "")) == "separated", "blocked gate did not leave readable separation")


func _find_representative_route(world, start: Vector2) -> Dictionary:
	for salvage in world.get_salvage_centers():
		var path: Array = world.find_open_path(start, salvage.get("center", Vector2.ZERO))
		for index in range(path.size() - 1, -1, -1):
			var candidate := path[index] as Vector2
			if start.distance_to(candidate) < 620.0:
				continue
			var prefix := path.slice(0, index + 1)
			if prefix.all(func(point): return world.get_current_gate_at(point as Vector2).is_empty()):
				return {"origin": start, "target": candidate}
	return {}


func _find_gate_crossing(world) -> Dictionary:
	var tile := float(world.tile_size)
	for gate in world.get_current_gates():
		var rect: Rect2 = gate.get("rect", Rect2())
		var center := rect.get_center()
		for pair in [
			[Vector2(rect.position.x - tile * 0.5, center.y), Vector2(rect.end.x + tile * 0.5, center.y)],
			[Vector2(center.x, rect.position.y - tile * 0.5), Vector2(center.x, rect.end.y + tile * 0.5)],
		]:
			var before := pair[0] as Vector2
			var after := pair[1] as Vector2
			if (
				not world.find_open_path(before, before).is_empty()
				and not world.find_open_path(after, after).is_empty()
				and world.has_clear_terrain_line(before, after)
			):
				return {"gate": gate, "before": before, "after": after}
	return {}


func _position_allowed(position: Vector2) -> bool:
	return _blocked_rect.size == Vector2.ZERO or not _blocked_rect.has_point(position)


func _finish(world, player, cuttle) -> void:
	cuttle.queue_free()
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Veil Cuttle follow smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Veil Cuttle identity=Mica role=independent close_follow=true investigations=bounded separation=readable recall=recovery collision_safe=true gate_blocked=true teleport=false mounted=false.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
