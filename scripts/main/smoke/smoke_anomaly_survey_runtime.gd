extends SceneTree

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ProgressionRuntimeController := preload("res://scripts/main/progression_runtime_controller.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")

const ORIGIN_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const TARGET_MAP_PATH := "res://maps/production_slice_02.greybox.json"
const TARGET_ID := "lower_right_anomaly_survey"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := SessionProgression.new()
	var progression := ProgressionRuntimeController.new(session)
	progression.grant_wallet_reward(AnomalySurveyRuntime.SCANNER_COST)
	var profile := ExpansionProfileState.new(ExpansionProfileState.DEFAULT_STORAGE_PATH, false)
	var runtime := AnomalySurveyRuntime.new(progression, false, profile)
	var player := Node2D.new()
	get_root().add_child(player)

	var origin: Node = _load_world(ORIGIN_MAP_PATH)
	player.global_position = origin.get_extraction_center()
	var blocked: Dictionary = runtime.try_unlock_scanner(origin, player)
	_expect(blocked.get("reason") == "lead_unavailable", "scanner unlocked before final-dive lead")
	_expect(progression.wallet() == AnomalySurveyRuntime.SCANNER_COST, "blocked unlock changed wallet")
	runtime.activate_lead()
	var unlocked: Dictionary = runtime.try_unlock_scanner(origin, player)
	_expect(bool(unlocked.get("changed", false)), "affordable scanner unlock failed")
	_expect(runtime.has_scanner(), "profile did not own scanner after unlock")
	_expect(progression.wallet() == 0, "scanner did not deduct exact cost")
	var repeated: Dictionary = runtime.try_unlock_scanner(origin, player)
	_expect(repeated.get("reason") == "already_unlocked", "repeat scanner unlock was not idempotent")
	_expect(progression.wallet() == 0, "repeat scanner unlock charged wallet")

	var target_world: Node = _load_world(TARGET_MAP_PATH)
	runtime.on_map_transition(target_world.map_id)
	runtime.on_map_loaded(target_world)
	var target := _target_by_id(target_world, TARGET_ID)
	_expect(not target.is_empty(), "source-authored survey target missing at runtime")
	player.global_position = target.get("center", Vector2.ZERO)
	var initial: Dictionary = runtime.update(target_world, player, 0.0)
	_expect(str(initial.get("state", "")) == "progress", "survey completed instantly")
	var partial: Dictionary = runtime.update(target_world, player, 1.0)
	var progress := float(partial.get("survey", {}).get("progress", 0.0))
	_expect(progress > 0.0 and progress < 1.0, "survey did not report partial progress")
	player.global_position = Vector2.ZERO
	var canceled: Dictionary = runtime.update(target_world, player, 0.0)
	_expect(str(canceled.get("state", "")) == "canceled", "leaving target did not cancel survey")
	_expect(not runtime.has_pending_discovery(), "canceled survey created pending discovery")

	player.global_position = target.get("center", Vector2.ZERO)
	var completed: Dictionary = runtime.update(target_world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(completed.get("pending", false)), "completed survey did not create pending discovery")
	_expect(runtime.has_pending_discovery(), "pending discovery owner remained empty")
	runtime.on_map_transition("production_slice_04")
	_expect(runtime.has_pending_discovery(), "connector transition cleared pending discovery")

	runtime.on_map_transition(origin.map_id)
	runtime.on_map_loaded(origin)
	player.global_position = origin.get_extraction_center()
	var committed: Dictionary = runtime.update(origin, player, 0.0)
	_expect(bool(committed.get("committed", false)), "canonical boat return did not commit discovery")
	_expect(runtime.has_completed_discovery(), "committed discovery did not reach profile")
	_expect(not runtime.has_pending_discovery(), "commit retained pending discovery")
	var repeat_commit: Dictionary = runtime.update(origin, player, 0.0)
	_expect(not bool(repeat_commit.get("committed", false)), "discovery committed more than once")
	_expect(runtime.result_text().find("Next lead:") != -1, "commit result omitted next-lead feedback")

	var report := runtime.report()
	origin.queue_free()
	target_world.queue_free()
	player.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Anomaly survey runtime smoke failed: %s" % failure)
		quit(1)
		return
	print("Anomaly survey runtime smoke passed: target=%s seconds=%.1f partial=%.2f cancel=true pending_across_connectors=true wallet=%d exact_once=true result=\"%s\" report=%s." % [
		TARGET_ID,
		float(target.get("interaction_seconds", 0.0)),
		progress,
		progression.wallet(),
		runtime.result_text().replace("\n", " | "),
		str(report),
	])
	quit(0)


func _load_world(path: String):
	var world := WORLD_SCENE.instantiate()
	world.map_path = path
	get_root().add_child(world)
	return world


func _target_by_id(world, target_id: String) -> Dictionary:
	for target in world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
