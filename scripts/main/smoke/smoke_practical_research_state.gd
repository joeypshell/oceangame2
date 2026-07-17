extends SceneTree

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ProgressionRuntimeController := preload("res://scripts/main/progression_runtime_controller.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")
const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")

const MAP_PATH := "res://maps/production_slice_01.greybox.json"
const TARGET_ID := "upper_right_mineral_trace_survey"
const TEST_PROFILE_PATH := "user://oceangame2_practical_research_state.json"

var _failures: Array[String] = []


class StorageFailingProfile:
	extends RefCounted

	func complete_discovery(discovery_id: String, _persist := true) -> Dictionary:
		return {"changed": false, "reason": "storage_error", "discovery_id": discovery_id}


class ScannerPlayer:
	extends Node2D
	var scanner_facing_sign := 1.0

	func get_facing_sign() -> float:
		return scanner_facing_sign

	func face_scanner_direction(sign: float) -> void:
		scanner_facing_sign = 1.0 if sign >= 0.0 else -1.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	var world: Node = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	profile.complete_material_project(_project_by_id(world, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), true)
	var runtime := AnomalySurveyRuntime.new(ProgressionRuntimeController.new(SessionProgression.new()), true, profile)
	var player := ScannerPlayer.new()
	get_root().add_child(player)
	runtime.on_map_loaded(world)

	var target := _target_by_id(world, TARGET_ID)
	_expect(not target.is_empty(), "resource survey target missing")
	_expect(str(target.get("target_type", "")) == "resource", "resource target type mismatch")
	_expect(runtime.has_scanner(), "resource setup did not own project-built scanner")
	_place_for_scan(world, player, target)
	var ready_overlay := runtime.overlay_text(world, player)
	_expect(ready_overlay.find(str(target.get("clue_label", ""))) != -1 and ready_overlay.find("Q/SCAN: Survey mineral trace") != -1, "resource clue or scan action was not source-derived")
	_expect(runtime.scanner_action(world, player).get("reason") == "activated", "Q/SCAN did not activate resource research")
	var partial: Dictionary = runtime.update(world, player, 1.0)
	_expect(str(partial.get("state", "")) == "progress", "resource survey did not progress without anomaly lead")
	_expect(float(partial.get("survey", {}).get("progress", 0.0)) > 0.0, "resource survey progress missing")
	player.global_position = Vector2.ZERO
	_expect(str(runtime.update(world, player, 0.0).get("state", "")) == "canceled", "resource leave-range did not cancel")

	_place_for_scan(world, player, target)
	runtime.scanner_action(world, player)
	var completed: Dictionary = runtime.update(world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(completed.get("pending", false)), "resource survey did not create pending finding")
	var pending: Dictionary = runtime.report().get("expedition", {}).get("pending", {})
	_expect(str(pending.get("discovery_id", "")) == ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID, "pending research id mismatch")
	_expect(str(pending.get("metadata", {}).get("finding_label", "")) == str(target.get("finding_label", "")), "pending finding label was not preserved")
	runtime.on_map_transition("production_slice_04")
	_expect(runtime.has_pending_discovery(), "connector transition cleared pending research")
	runtime.on_map_loaded(world)
	runtime.clear_unbanked("hazard", world)
	_expect(not runtime.has_pending_discovery(), "hazard cleanup retained pending research")
	_complete_pending(runtime, world, player, target)
	runtime.clear_unbanked("reset", world)
	_expect(not runtime.has_pending_discovery(), "reset cleanup retained pending research")
	_complete_pending(runtime, world, player, target)
	runtime.clear_unbanked("oxygen_failure", world)
	_expect(not runtime.has_pending_discovery(), "oxygen cleanup retained pending research")
	_verify_pending_owner(target)

	_complete_pending(runtime, world, player, target)
	runtime.on_map_loaded(world)
	player.global_position = world.get_extraction_center()
	var committed: Dictionary = runtime.update(world, player, 0.0)
	_expect(bool(committed.get("committed", false)), "canonical boat did not commit resource research")
	_expect(str(committed.get("result_text", "")) == str(target.get("finding_label", "")), "commit result was not source-derived")
	_expect(runtime.has_completed_research(), "committed research missing from profile")
	_expect(not runtime.has_completed_discovery(), "resource research completed legacy anomaly")
	_expect(not runtime.has_pending_discovery(), "commit retained pending research")

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") == "loaded", "research profile did not reload")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID), "reload lost research")
	_expect(not reloaded.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "reload invented anomaly discovery")
	_expect(int(reload_report.get("schema_version", 0)) == ExpansionProfileState.SCHEMA_VERSION, "research changed profile schema")
	reloaded.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, true)
	var both_discoveries := ExpansionProfileState.new(TEST_PROFILE_PATH)
	both_discoveries.load_profile()
	_expect(both_discoveries.has_completed_discovery(ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID), "combined profile lost research")
	_expect(both_discoveries.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "combined profile lost anomaly")

	var final_report := runtime.report()
	world.queue_free()
	player.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Practical research state smoke failed: %s" % failure)
		quit(1)
		return
	print("Practical research state smoke passed: target=%s discovery=%s lead_required=false cancel=true pending_across_connectors=true clears=hazard,reset,oxygen save_failure_retains=true one_pending=true canonical_commit=true schema=%d both_discoveries_valid=true result=\"%s\" report=%s." % [
		TARGET_ID,
		ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID,
		ExpansionProfileState.SCHEMA_VERSION,
		runtime.result_text(),
		str(final_report),
	])
	quit(0)


func _target_by_id(world, target_id: String) -> Dictionary:
	for target in world.get_survey_targets():
		if str(target.get("id", "")) == target_id:
			return target
	return {}


func _project_by_id(world, project_id: String) -> Dictionary:
	for project in world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _complete_pending(runtime, world, player, target: Dictionary) -> void:
	_place_for_scan(world, player, target)
	runtime.scanner_action(world, player)
	var completed: Dictionary = runtime.update(world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(completed.get("pending", false)) and runtime.has_pending_discovery(), "resource survey did not recreate pending finding")


func _place_for_scan(world, player, target: Dictionary) -> void:
	var pose: Dictionary = ScannerSmokePose.new().place(world, player, target)
	_expect(bool(pose.get("found", false)), "no clear scan pose for %s" % target.get("id", "target"))


func _verify_pending_owner(target: Dictionary) -> void:
	var owner := ExpeditionDiscoveryState.new()
	var created: Dictionary = owner.create_pending(
		ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID,
		"production_slice_01",
		TARGET_ID,
		"production_slice_01",
		"surface_boat_entry",
		{"target_type": "resource", "finding_label": target.get("finding_label", "")}
	)
	_expect(created.get("status") == "pending_created", "pending owner rejected resource research")
	var competing: Dictionary = owner.create_pending(
		ExpansionProfileState.ANOMALY_DISCOVERY_ID,
		"production_slice_02",
		"lower_right_anomaly_survey",
		"production_slice_01",
		"surface_boat_entry"
	)
	_expect(competing.get("status") == "pending_exists", "second discovery replaced pending research")
	var failed: Dictionary = owner.commit_at("production_slice_01", "surface_boat_entry", StorageFailingProfile.new())
	_expect(failed.get("status") == "storage_error" and owner.has_pending(), "save failure discarded pending research")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
