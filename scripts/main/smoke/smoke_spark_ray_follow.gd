extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const SPECIES_ID := "spark_ray"
const STEP_SECONDS := 1.0 / 30.0

var _failures: Array[String] = []


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
	await physics_frame

	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var runtime := CompanionSortieRuntime.new()
	get_root().add_child(runtime)
	runtime.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"))
	_expect(runtime.companion() == null, "uncommitted profile spawned a companion")
	var committed: Dictionary = profile.commit_companion_rescue(INDIVIDUAL_ID, SPECIES_ID, "Kite", false)
	_expect(bool(committed.get("changed", false)), "fixture could not commit the Spark Ray")
	_expect(runtime.companion() == null, "boat commitment spawned the companion before the next sortie launch")
	var profile_before := profile.companion_report()
	var spawn_report: Dictionary = runtime.sync_spawn()
	var ray = runtime.companion()
	_expect(ray != null and bool(spawn_report.get("spawned", false)), "committed active Spark Ray did not spawn")
	if ray == null:
		_finish(world, player, runtime)
		return
	ray.set_physics_process(false)
	ray.advance(0.0)
	_expect(str(ray.report().get("state", "")) == "near", "spawn did not begin in the readable near state")
	_expect(ray.global_position.distance_to(player.global_position) <= 82.0, "spawn was outside the near envelope")

	var route: Dictionary = _find_representative_route(world, ray.global_position)
	_expect(not route.is_empty(), "full level had no long gate-free follow fixture")
	if not route.is_empty():
		_test_follow_envelopes(player, ray, route)
		_test_separation_and_recovery(world, player, ray, route)
	_test_context_responses(player, ray)
	_test_external_control_handoff(player, ray)
	_test_locked_gate(world, player, ray)

	player.global_position = world.spawn_position
	runtime.recover_to_player()
	_expect(ray.global_position.distance_to(player.global_position) <= 72.0, "failure-style recovery did not reunite at the player")
	_expect(str(ray.report().get("state", "")) == "near", "failure-style recovery retained stale separation state")
	_expect(profile.companion_report() == profile_before, "follow behavior mutated persistent companion state")
	_finish(world, player, runtime)


func _test_follow_envelopes(player, ray, route: Dictionary) -> void:
	var origin: Vector2 = route["origin"]
	var path: Array = route["path"]
	var follow_target := _path_point_in_distance_range(path, origin, 100.0, 180.0)
	var catch_up_target := _path_point_in_distance_range(path, origin, 260.0, 420.0)
	_expect(follow_target != Vector2.ZERO, "route fixture omitted the follow envelope")
	_expect(catch_up_target != Vector2.ZERO, "route fixture omitted the catch-up envelope")
	if follow_target != Vector2.ZERO:
		ray.set_external_control_active(true)
		ray.global_position = origin
		player.global_position = follow_target
		ray.set_external_control_active(false)
		ray.advance(0.0)
		_expect(str(ray.report().get("state", "")) == "follow", "mid-range target did not select follow state")
	if catch_up_target != Vector2.ZERO:
		ray.set_external_control_active(true)
		ray.global_position = origin
		player.global_position = catch_up_target
		ray.set_external_control_active(false)
		ray.advance(0.0)
		_expect(str(ray.report().get("state", "")) == "catch_up", "distant target did not select catch-up state")
	ray.set_external_control_active(true)
	ray.global_position = origin
	ray.set_external_control_active(false)


func _test_separation_and_recovery(world, player, ray, route: Dictionary) -> void:
	player.global_position = route["target"]
	var prior: Vector2 = ray.global_position
	ray.advance(0.05)
	var separated: Dictionary = ray.report()
	_expect(str(separated.get("state", "")) == "separated", "long separation skipped the worried state")
	_expect(bool(separated.get("presentation", {}).get("recovery_path_visible", false)), "worried state did not display its recovery path")
	var worried_step := prior.distance_to(ray.global_position)
	_expect(worried_step <= 0.01, "worried state moved %.2fpx before its bounded hold" % worried_step)

	var recovery_seen := false
	var open_cells_only := true
	var previous_distance: float = ray.global_position.distance_to(player.global_position)
	var progress_frames := 0
	for _index in range(900):
		ray.advance(STEP_SECONDS)
		var report: Dictionary = ray.report()
		if str(report.get("state", "")) == "recovery":
			recovery_seen = true
		var distance: float = ray.global_position.distance_to(player.global_position)
		if distance < previous_distance - 0.25:
			progress_frames += 1
		previous_distance = distance
		if world.find_open_path(ray.global_position, ray.global_position).is_empty():
			open_cells_only = false
		if distance <= 82.0 and str(report.get("state", "")) == "near":
			break
	_expect(recovery_seen, "separated companion never entered deterministic recovery")
	_expect(progress_frames > 12, "recovery made no sustained progress toward the player")
	_expect(ray.global_position.distance_to(player.global_position) <= 82.0, "companion did not recover through representative full-level geometry")
	_expect(open_cells_only, "companion recovery entered solid terrain")
	var final_report: Dictionary = ray.report()
	var maximum_step := float(final_report.get("maximum_step_distance", 999.0))
	_expect(maximum_step <= 10.0, "companion used a %.2fpx routine step during recovery" % maximum_step)
	_expect(int(final_report.get("facing_change_count", 999)) <= 12, "recovery produced unstable direction-flip flashing")


func _test_context_responses(player, ray) -> void:
	var profile_free_report: Dictionary = ray.report()
	_expect(ray.show_context_response("rescue_memory", player.global_position + Vector2.UP * 40.0), "rescue-memory response was rejected")
	_expect(str(ray.report().get("presentation", {}).get("context_kind", "")) == "rescue_memory", "rescue-memory cue was not visible")
	_expect(ray.show_context_response("danger", player.global_position + Vector2.RIGHT * 40.0), "danger response was rejected")
	_expect(str(ray.report().get("presentation", {}).get("context_kind", "")) == "danger", "danger cue was not visible")
	ray.advance(1.0)
	_expect(str(ray.report().get("presentation", {}).get("context_kind", "")) == "", "context response did not expire")
	_expect(not profile_free_report.has("memory_award") and not ray.has_method("attack"), "follow presentation exposed memory or attack behavior")


func _test_external_control_handoff(player, ray) -> void:
	player.global_position = ray.global_position + Vector2(48.0, 0.0)
	ray.set_external_control_active(true)
	var before: Vector2 = ray.global_position
	ray.velocity = Vector2(60.0, 0.0)
	ray.advance(0.5)
	var held: Dictionary = ray.report()
	_expect(str(held.get("state", "")) == "external_control", "external-control handoff did not suspend follow")
	_expect(before.distance_to(ray.global_position) <= 0.01, "follow movement fought the external-control fixture")
	_expect(ray.velocity == Vector2(60.0, 0.0), "follow owner changed externally controlled velocity")
	_expect(bool(held.get("can_handoff_control", false)), "near companion did not expose a valid control handoff")
	ray.set_external_control_active(false)
	ray.advance(0.0)
	_expect(str(ray.report().get("state", "")) == "near", "leaving external control did not restore follow state")


func _test_locked_gate(world, player, ray) -> void:
	var fixture := _find_gate_crossing(world)
	_expect(not fixture.is_empty(), "full level had no clear equipment-gate crossing fixture")
	if fixture.is_empty():
		return
	var gate: Dictionary = fixture["gate"]
	var rect: Rect2 = gate["rect"]
	ray.set_external_control_active(true)
	ray.global_position = fixture["before"]
	player.global_position = fixture["after"]
	ray.set_external_control_active(false)
	var entered_gate := false
	for _index in range(180):
		ray.advance(STEP_SECONDS)
		entered_gate = entered_gate or rect.has_point(ray.global_position)
	var report: Dictionary = ray.report()
	_expect(not entered_gate, "companion entered an equipment gate without its requirement")
	_expect(bool(report.get("path_blocked_by_gate", false)), "locked gate did not become explicit path state")
	_expect(str(report.get("state", "")) == "separated", "locked gate did not leave a readable separated state")


func _find_representative_route(world, start: Vector2) -> Dictionary:
	for salvage in world.get_salvage_centers():
		var path: Array = world.find_open_path(start, salvage.get("center", Vector2.ZERO))
		for index in range(path.size() - 1, -1, -1):
			var candidate := path[index] as Vector2
			if start.distance_to(candidate) < 620.0:
				continue
			var prefix := path.slice(0, index + 1)
			if prefix.all(func(point): return world.get_current_gate_at(point as Vector2).is_empty()):
				return {"origin": start, "target": candidate, "path": prefix, "path_points": prefix.size()}
	return {}


func _path_point_in_distance_range(path: Array, origin: Vector2, minimum: float, maximum: float) -> Vector2:
	for point in path:
		var candidate := point as Vector2
		var distance := origin.distance_to(candidate)
		if distance >= minimum and distance <= maximum:
			return candidate
	return Vector2.ZERO


func _find_gate_crossing(world) -> Dictionary:
	var tile := float(world.tile_size)
	for gate in world.get_current_gates():
		var rect: Rect2 = gate.get("rect", Rect2())
		var center := rect.get_center()
		var pairs := [
			[Vector2(rect.position.x - tile * 0.5, center.y), Vector2(rect.end.x + tile * 0.5, center.y)],
			[Vector2(center.x, rect.position.y - tile * 0.5), Vector2(center.x, rect.end.y + tile * 0.5)],
		]
		for pair in pairs:
			var before := pair[0] as Vector2
			var after := pair[1] as Vector2
			if (
				not world.find_open_path(before, before).is_empty()
				and not world.find_open_path(after, after).is_empty()
				and world.has_clear_terrain_line(before, after)
			):
				return {"gate": gate, "before": before, "after": after}
	return {}


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _finish(world, player, runtime) -> void:
	runtime.clear_map()
	runtime.queue_free()
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Spark Ray follow smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Spark Ray follow active_spawn=true near=true follow=true catch_up=true worried=true recovery=true collision_safe=true gate_blocked=true teleport=false external_handoff=true context_cues=2 profile_unchanged=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
