extends SceneTree

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ProgressionRuntimeController := preload("res://scripts/main/progression_runtime_controller.gd")
const SessionProgression := preload("res://scripts/main/session_progression.gd")
const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")

const ORIGIN_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const TARGET_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const REGIONAL_MAP_PATH := "res://maps/production_level_01.greybox.json"
const TARGET_ID := "lower_right_anomaly_survey"
const REGIONAL_TARGET_ID := "lower_right_signal_reef_survey"
const HARMONIC_TARGET_ID := "signal_reef_deep_harmonic_survey"
const HARMONIC_ZONE_ID := "signal_reef_deep_harmonic_dark_zone"
const ABYSSAL_TARGET_ID := "abyssal_basin_harmonic_source_survey"
const TEST_PATH := "user://oceangame2_harmonic_survey_test.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_file(TEST_PATH)
	var session := SessionProgression.new()
	var progression := ProgressionRuntimeController.new(session)
	var profile := ExpansionProfileState.new(TEST_PATH, true)
	var runtime := AnomalySurveyRuntime.new(progression, true, profile)
	progression.set_profile_state(profile)
	var player := Node2D.new()
	get_root().add_child(player)

	var origin: Node = _load_world(ORIGIN_MAP_PATH)
	player.global_position = origin.get_extraction_center()
	var blocked: Dictionary = runtime.scanner_action(origin, player)
	_expect(blocked.get("reason") == "blueprint_required", "scanner bypassed its blueprint")
	_expect(progression.wallet() == 0, "scanner guidance changed wallet")
	profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	var unlocked: Dictionary = profile.complete_material_project(_project_by_id(origin, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), true)
	_expect(bool(unlocked.get("changed", false)), "scanner project transaction failed")
	_expect(runtime.has_scanner(), "profile did not own scanner after unlock")
	var repeated: Dictionary = runtime.scanner_action(origin, player)
	_expect(repeated.get("reason") == "ready", "scanner action did not become contextual after build")
	_expect(progression.wallet() == 0, "scanner project changed wallet")

	var target_world: Node = _load_world(TARGET_MAP_PATH)
	runtime.on_map_transition(target_world.map_id)
	runtime.on_map_loaded(target_world)
	var target := _target_by_id(target_world, TARGET_ID)
	_expect(not target.is_empty(), "source-authored survey target missing at runtime")
	player.global_position = target.get("center", Vector2.ZERO)
	var initial: Dictionary = runtime.update(target_world, player, 1.0)
	_expect(str(initial.get("state", "")) == "awaiting_activation", "survey advanced before Q/SCAN activation")
	_expect(is_zero_approx(float(initial.get("survey", {}).get("progress", -1.0))), "proximity-only survey retained progress")
	var activated: Dictionary = runtime.scanner_action(target_world, player)
	_expect(activated.get("reason") == "activated", "Q/SCAN did not activate the nearby survey")
	var partial: Dictionary = runtime.update(target_world, player, 1.0)
	var progress := float(partial.get("survey", {}).get("progress", 0.0))
	_expect(progress > 0.0 and progress < 1.0, "survey did not report partial progress")
	player.global_position = Vector2.ZERO
	var canceled: Dictionary = runtime.update(target_world, player, 0.0)
	_expect(str(canceled.get("state", "")) == "canceled", "leaving target did not cancel survey")
	_expect(not runtime.has_pending_discovery(), "canceled survey created pending discovery")

	player.global_position = target.get("center", Vector2.ZERO)
	var retry_wait: Dictionary = runtime.update(target_world, player, 1.0)
	_expect(str(retry_wait.get("state", "")) == "awaiting_activation", "returning to a canceled survey did not require a new Q/SCAN press")
	_expect(is_zero_approx(float(retry_wait.get("survey", {}).get("progress", -1.0))), "canceled survey resumed from proximity")
	runtime.scanner_action(target_world, player)
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
	_expect(runtime.result_text().find("Cutter plan recovered:") != -1, "commit result omitted cutter-plan feedback")

	var regional_world: Node = _load_world(REGIONAL_MAP_PATH)
	runtime.clear_unbanked("regional_setup", regional_world)
	runtime.on_map_loaded(regional_world)
	var regional_target := _target_by_id(regional_world, REGIONAL_TARGET_ID)
	_expect(not regional_target.is_empty(), "source-authored regional survey target missing at runtime")
	_expect(str(regional_target.get("target_type", "")) == "regional", "regional survey target type drifted")
	var full_level_session := SessionProgression.new()
	var full_level_progression := ProgressionRuntimeController.new(full_level_session)
	var full_level_profile := ExpansionProfileState.new(ExpansionProfileState.DEFAULT_STORAGE_PATH, false)
	var full_level_runtime := AnomalySurveyRuntime.new(full_level_progression, false, full_level_profile)
	full_level_profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	full_level_profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	var full_level_unlock: Dictionary = full_level_profile.complete_material_project(_project_by_id(regional_world, ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), false)
	_expect(bool(full_level_unlock.get("changed", false)), "scanner project did not unlock on promoted full level")
	player.global_position = regional_target.get("center", Vector2.ZERO)
	var regional_clue := runtime.overlay_text(regional_world, player)
	_expect(regional_clue.find(str(regional_target.get("clue_label", ""))) != -1 and regional_clue.find("Q/SCAN: Survey Signal Reef") != -1, "regional clue or scan action did not use source text")
	runtime.scanner_action(regional_world, player)
	var regional_complete: Dictionary = runtime.update(
		regional_world,
		player,
		float(regional_target.get("interaction_seconds", 0.0))
	)
	_expect(bool(regional_complete.get("pending", false)), "regional survey did not create pending discovery")
	_expect(runtime.has_pending_discovery(), "regional pending discovery owner remained empty")
	var pending_metadata: Dictionary = runtime.report().get("expedition", {}).get("pending", {}).get("metadata", {})
	_expect(
		str(pending_metadata.get("next_lead_label", "")) == str(regional_target.get("next_lead_label", "")),
		"regional pending state lost the source next lead"
	)
	runtime.clear_unbanked("hazard", regional_world)
	_expect(not runtime.has_pending_discovery(), "regional hazard cleanup retained pending discovery")
	_expect(
		not profile.has_completed_discovery(ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID),
		"regional hazard cleanup committed discovery"
	)
	player.global_position = regional_target.get("center", Vector2.ZERO)
	runtime.scanner_action(regional_world, player)
	regional_complete = runtime.update(
		regional_world,
		player,
		float(regional_target.get("interaction_seconds", 0.0))
	)
	_expect(bool(regional_complete.get("pending", false)), "regional survey did not restart after cleanup")
	player.global_position = regional_world.get_extraction_center()
	var regional_commit: Dictionary = runtime.update(regional_world, player, 0.0)
	_expect(bool(regional_commit.get("committed", false)), "full-level boat did not commit regional discovery")
	_expect(
		profile.has_completed_discovery(ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID),
		"regional discovery did not reach profile"
	)
	var expected_regional_result := "%s\n%s" % [
		regional_target.get("finding_label", ""),
		regional_target.get("next_lead_label", ""),
	]
	_expect(runtime.result_text() == expected_regional_result, "regional result did not use authored finding and next lead")
	var harmonic_report := _exercise_harmonic_return(runtime, progression, profile, regional_world, player)
	var abyssal_report := _exercise_abyssal_return(runtime, progression, profile, regional_world, player)

	var report := runtime.report()
	origin.queue_free()
	target_world.queue_free()
	regional_world.queue_free()
	player.queue_free()
	_cleanup_file(TEST_PATH)
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Anomaly survey runtime smoke failed: %s" % failure)
		quit(1)
		return
	print("Anomaly survey runtime smoke passed: target=%s seconds=%.1f partial=%.2f cancel=true pending_across_connectors=true regional_target=%s full_level_commit=true harmonic=%s abyssal=%s pre_light_blocked=true light_readability=true failure_cleanup=true reload=true wallet=%d exact_once=true result=\"%s\" report=%s." % [
		TARGET_ID,
		float(target.get("interaction_seconds", 0.0)),
		progress,
		REGIONAL_TARGET_ID,
		str(harmonic_report),
		str(abyssal_report),
		progression.wallet(),
		runtime.result_text().replace("\n", " | "),
		str(report),
	])
	quit(0)


func _exercise_harmonic_return(runtime, progression, profile, world, player) -> Dictionary:
	runtime.clear_unbanked("harmonic_setup", world)
	var target := _target_by_id(world, HARMONIC_TARGET_ID)
	var zone := _visibility_zone_by_id(world, HARMONIC_ZONE_ID)
	_expect(not target.is_empty(), "source-authored harmonic survey target missing at runtime")
	_expect(not zone.is_empty(), "source-authored harmonic dark zone missing at runtime")
	if target.is_empty() or zone.is_empty():
		return {}

	player.global_position = target.get("center", Vector2.ZERO)
	progression.apply_light_profile(world, player)
	var pre_light_alpha := float(_visibility_zone_by_id(world, HARMONIC_ZONE_ID).get("overlay_alpha", 0.0))
	var clue := str(target.get("clue_label", ""))
	_expect(runtime.overlay_text(world, player) == clue, "pre-light harmonic clue was not source-derived")
	var blocked: Dictionary = runtime.update(world, player, 1.0)
	_expect(blocked.get("reason") == "light_required", "harmonic survey advanced without durable light")
	_expect(str(blocked.get("note", "")) == clue, "pre-light denial did not use the source clue")
	_expect(
		is_zero_approx(float(runtime.report().get("interaction", {}).get("progress", -1.0))),
		"pre-light denial retained survey progress"
	)
	_expect(not runtime.has_pending_discovery(), "pre-light denial created pending discovery")
	_expect(str(_target_by_id(world, HARMONIC_TARGET_ID).get("state", "")) == "locked", "pre-light target was not visibly locked")

	var project := _project_by_id(world, ExpansionProfileState.DIVE_LIGHT_PROJECT_ID)
	_expect(not project.is_empty(), "source-authored dive-light project missing at runtime")
	if project.is_empty():
		return {}
	var deposited: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
		ExpansionProfileState.COIL_MATERIAL_ID: 1,
		ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
	}, true)
	_expect(bool(deposited.get("changed", false)), "harmonic fixture could not bank the exact light recipe")
	var built: Dictionary = profile.complete_material_project(project, true)
	_expect(bool(built.get("changed", false)), "real light project transaction did not unlock the survey requirement")
	progression.apply_light_profile(world, player)
	runtime.on_map_loaded(world)
	var upgraded_alpha := float(_visibility_zone_by_id(world, HARMONIC_ZONE_ID).get("overlay_alpha", 0.0))
	_expect(upgraded_alpha > 0.0 and upgraded_alpha < pre_light_alpha, "durable light did not improve harmonic-zone readability")
	_expect(str(_target_by_id(world, HARMONIC_TARGET_ID).get("state", "")) == "available", "light-owned harmonic target did not become available")

	player.global_position = target.get("center", Vector2.ZERO)
	_expect(runtime.scanner_action(world, player).get("reason") == "activated", "Q/SCAN did not activate the harmonic survey")
	var partial: Dictionary = runtime.update(world, player, 1.0)
	var partial_progress := float(partial.get("survey", {}).get("progress", 0.0))
	_expect(partial_progress > 0.0 and partial_progress < 1.0, "light-owned harmonic survey did not report partial progress")
	_expect(runtime.overlay_text(world, player).begins_with("Survey deep harmonic "), "light-owned harmonic survey omitted active progress")
	player.global_position = Vector2.ZERO
	var canceled: Dictionary = runtime.update(world, player, 0.0)
	_expect(canceled.get("state") == "canceled", "leaving harmonic range did not cancel partial progress")

	for reason in ["hazard", "oxygen_failure", "combat_defeat", "reset"]:
		player.global_position = target.get("center", Vector2.ZERO)
		runtime.scanner_action(world, player)
		runtime.update(world, player, 1.0)
		runtime.clear_unbanked(reason, world)
		_expect(
			is_zero_approx(float(runtime.report().get("interaction", {}).get("progress", -1.0)))
			and not runtime.has_pending_discovery(),
			"%s cleanup retained harmonic progress or pending state" % reason
		)

	player.global_position = target.get("center", Vector2.ZERO)
	runtime.scanner_action(world, player)
	var pending: Dictionary = runtime.update(world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(pending.get("pending", false)), "completed harmonic survey did not become pending")
	runtime.clear_unbanked("hazard", world)
	_expect(
		not runtime.has_pending_discovery()
		and not profile.has_completed_discovery(ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID),
		"failure cleanup committed or retained the pending harmonic discovery"
	)

	player.global_position = target.get("center", Vector2.ZERO)
	runtime.scanner_action(world, player)
	pending = runtime.update(world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(pending.get("pending", false)), "harmonic survey did not restart after cleanup")
	player.global_position = world.get_extraction_center()
	var committed: Dictionary = runtime.update(world, player, 0.0)
	var expected_result := "%s\n%s" % [target.get("finding_label", ""), target.get("next_lead_label", "")]
	_expect(bool(committed.get("committed", false)), "canonical full-level boat did not commit harmonic discovery")
	_expect(profile.has_completed_discovery(ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID), "harmonic discovery did not reach the profile")
	_expect(runtime.result_text() == expected_result, "harmonic boat payoff did not use source finding and next lead")

	runtime.on_map_loaded(world)
	player.global_position = target.get("center", Vector2.ZERO)
	var next_day: Dictionary = runtime.update(world, player, 0.0)
	_expect(next_day.get("reason") == "completed" and not runtime.has_pending_discovery(), "next day recreated harmonic pending state")

	var reloaded_profile := ExpansionProfileState.new(TEST_PATH, true)
	var reload_progression := ProgressionRuntimeController.new(SessionProgression.new())
	var reload_runtime := AnomalySurveyRuntime.new(reload_progression, true, reloaded_profile)
	reload_progression.set_profile_state(reloaded_profile)
	reload_runtime.on_map_loaded(world)
	var reload_repeat: Dictionary = reload_runtime.update(world, player, 0.0)
	_expect(
		reloaded_profile.has_capability(ExpansionProfileState.DIVE_LIGHT_CAPABILITY_ID)
		and reloaded_profile.has_completed_discovery(ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID),
		"profile reload lost durable light or harmonic discovery"
	)
	_expect(reload_repeat.get("reason") == "completed" and not reload_runtime.has_pending_discovery(), "profile reload duplicated harmonic survey or commit")
	return {
		"target": HARMONIC_TARGET_ID,
		"seconds": target.get("interaction_seconds", 0.0),
		"partial": partial_progress,
		"pre_alpha": pre_light_alpha,
		"upgraded_alpha": upgraded_alpha,
		"committed": profile.has_completed_discovery(ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID),
	}


func _exercise_abyssal_return(runtime, _progression, profile, world, player) -> Dictionary:
	runtime.clear_unbanked("abyssal_setup", world)
	var target := _target_by_id(world, ABYSSAL_TARGET_ID)
	_expect(not target.is_empty(), "source-authored abyssal survey target missing at runtime")
	if target.is_empty():
		return {}

	player.global_position = target.get("center", Vector2.ZERO)
	var clue := str(target.get("clue_label", ""))
	_expect(runtime.overlay_text(world, player) == clue, "pre-suit abyssal clue was not source-derived")
	var blocked: Dictionary = runtime.update(world, player, 1.0)
	_expect(blocked.get("reason") == "pressure_required", "abyssal survey advanced without pressure suit")
	_expect(str(blocked.get("note", "")) == clue, "pre-suit abyssal denial did not use source clue")
	_expect(
		is_zero_approx(float(runtime.report().get("interaction", {}).get("progress", -1.0)))
		and not runtime.has_pending_discovery(),
		"pre-suit abyssal denial retained progress or pending state"
	)
	_expect(str(_target_by_id(world, ABYSSAL_TARGET_ID).get("state", "")) == "locked", "pre-suit abyssal target was not visibly locked")

	var project := _project_by_id(world, ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID)
	_expect(not project.is_empty(), "source-authored pressure-suit project missing at runtime")
	if project.is_empty():
		return {}
	var deposited: Dictionary = profile.deposit_materials({
		ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
		ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
		ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
	}, true)
	_expect(bool(deposited.get("changed", false)), "abyssal fixture could not bank the exact pressure recipe")
	var built: Dictionary = profile.complete_material_project(project, true)
	_expect(bool(built.get("changed", false)), "real pressure project did not unlock survey protection")
	runtime.on_map_loaded(world)
	_expect(str(_target_by_id(world, ABYSSAL_TARGET_ID).get("state", "")) == "available", "pressure-owned abyssal target did not become available")

	player.global_position = target.get("center", Vector2.ZERO)
	_expect(runtime.scanner_action(world, player).get("reason") == "activated", "Q/SCAN did not activate the abyssal survey")
	var partial: Dictionary = runtime.update(world, player, 1.0)
	var partial_progress := float(partial.get("survey", {}).get("progress", 0.0))
	_expect(partial_progress > 0.0 and partial_progress < 1.0, "protected abyssal survey did not report partial progress")
	_expect(runtime.overlay_text(world, player).begins_with("Survey abyssal source "), "protected abyssal survey omitted active progress")
	player.global_position = Vector2.ZERO
	_expect(runtime.update(world, player, 0.0).get("state") == "canceled", "leaving abyssal range did not cancel progress")

	for reason in ["hazard", "oxygen_failure", "combat_defeat", "reset", "nightfall"]:
		player.global_position = target.get("center", Vector2.ZERO)
		runtime.scanner_action(world, player)
		runtime.update(world, player, 1.0)
		runtime.clear_unbanked(reason, world)
		_expect(
			is_zero_approx(float(runtime.report().get("interaction", {}).get("progress", -1.0)))
			and not runtime.has_pending_discovery(),
			"%s cleanup retained abyssal progress or pending state" % reason
		)

	player.global_position = target.get("center", Vector2.ZERO)
	runtime.scanner_action(world, player)
	var pending: Dictionary = runtime.update(world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(pending.get("pending", false)), "completed abyssal survey did not become pending")
	_expect(pending.get("note") == "Abyssal source charted | Return to boat", "abyssal pending feedback drifted")
	_expect(runtime.overlay_text(world, player) == "Abyssal chart pending | Return to surface boat before another scan", "abyssal pending overlay drifted")
	runtime.clear_unbanked("hazard", world)
	_expect(
		not runtime.has_pending_discovery()
		and not profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID),
		"failure cleanup committed or retained the pending abyssal discovery"
	)

	player.global_position = target.get("center", Vector2.ZERO)
	runtime.scanner_action(world, player)
	pending = runtime.update(world, player, float(target.get("interaction_seconds", 0.0)))
	_expect(bool(pending.get("pending", false)), "abyssal survey did not restart after cleanup")
	player.global_position = world.get_extraction_center()
	var committed: Dictionary = runtime.update(world, player, 0.0)
	var expected_result := "%s\n%s" % [target.get("finding_label", ""), target.get("next_lead_label", "")]
	_expect(bool(committed.get("committed", false)), "canonical boat did not commit abyssal discovery")
	_expect(profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID), "abyssal discovery did not reach profile")
	_expect(runtime.result_text() == expected_result, "abyssal boat payoff did not use source finding and next lead")

	runtime.on_map_loaded(world)
	player.global_position = target.get("center", Vector2.ZERO)
	var next_day: Dictionary = runtime.update(world, player, 0.0)
	_expect(next_day.get("reason") == "completed" and not runtime.has_pending_discovery(), "next day recreated abyssal pending state")
	var reloaded_profile := ExpansionProfileState.new(TEST_PATH, true)
	var reload_runtime := AnomalySurveyRuntime.new(_progression, true, reloaded_profile)
	reload_runtime.on_map_loaded(world)
	var reload_repeat: Dictionary = reload_runtime.update(world, player, 0.0)
	_expect(
		reloaded_profile.has_capability(ExpansionProfileState.PRESSURE_SUIT_CAPABILITY_ID)
		and reloaded_profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID),
		"profile reload lost durable pressure suit or abyssal discovery"
	)
	_expect(reload_repeat.get("reason") == "completed" and not reload_runtime.has_pending_discovery(), "profile reload duplicated abyssal survey or commit")
	return {
		"target": ABYSSAL_TARGET_ID,
		"seconds": target.get("interaction_seconds", 0.0),
		"partial": partial_progress,
		"committed": profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID),
	}


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


func _visibility_zone_by_id(world, zone_id: String) -> Dictionary:
	for zone in world.get_visibility_zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _project_by_id(world, project_id: String) -> Dictionary:
	for project in world.get_material_projects():
		if str(project.get("id", "")) == project_id:
			return project
	return {}


func _cleanup_file(path: String) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var candidate := "%s%s" % [path, suffix]
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
