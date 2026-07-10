extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const TEST_PROFILE_PATH := "user://oceangame2_night_debrief_smoke.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	var profile := ExpansionProfileState.new(TEST_PROFILE_PATH)
	profile.load_profile()
	profile.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, true)
	profile.complete_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID, true)
	main._anomaly_survey = AnomalySurveyRuntime.new(main._progression_runtime, true, profile)
	main._anomaly_survey.on_map_loaded(main._world)

	main._expedition_day_state.record_sortie_started()
	main._expedition_day_state.record_sortie_started()
	main._expedition_day_state.record_bank(2, 450)
	main._expedition_day_state.record_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID)
	main._player.global_position = main._world.get_extraction_center()
	main._expedition_day_state.request_end_day("voluntary")
	main._process(0.0)
	var voluntary_text := ExpeditionDayDebrief.build_text(main._expedition_day_state)
	_expect(main._expedition_day_state.phase == main._expedition_day_state.PHASE_DEBRIEF, "voluntary end did not enter debrief")
	_expect(voluntary_text.find("Dives 2") != -1 and voluntary_text.find("Banked cargo 2") != -1, "voluntary debrief omitted day totals")
	_expect(voluntary_text.find("Banked value 450") != -1 and voluntary_text.find("Discoveries 1") != -1, "voluntary debrief omitted value or discovery")
	_expect(not _contains_future_tax(voluntary_text), "debrief exposed unimplemented survival or planning controls")

	ExpeditionDayDebrief.handle_day_key(main)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false
	_expect(main._expedition_day_state.day_number == 2 and main._expedition_day_state.phase == main._expedition_day_state.PHASE_ACTIVE, "next day did not start active")
	_expect(main._expedition_day_state.sortie_count == 0 and main._expedition_day_state.banked_score == 0, "next day retained day-scoped totals")
	_expect(main._world.map_id == "production_slice_01" and main._world.is_inside_boat(main._player.global_position), "next day did not start at canonical boat")
	_expect(main._anomaly_survey.has_scanner() and main._anomaly_survey.has_completed_discovery(), "next day lost profile progression")

	var targets := _instant_salvage(main._world)
	_expect(targets.size() >= 2, "forced recovery smoke needs two instant targets")
	if targets.size() >= 2:
		main._player.global_position = targets[0]["center"]
		main._process(0.0)
		main._player.global_position = main._world.get_extraction_center()
		main._process(0.0)
		var committed_score: int = main._expedition_day_state.banked_score
		main._player.global_position = targets[1]["center"]
		main._process(0.0)
		main._expedition_day_state.daylight_remaining_seconds = 0.1
		main._process(0.2)
		var forced_text := ExpeditionDayDebrief.build_text(main._expedition_day_state)
		_expect(main._expedition_day_state.phase == main._expedition_day_state.PHASE_DEBRIEF, "nightfall did not enter debrief")
		_expect(main._expedition_day_state.banked_score == committed_score and committed_score > 0, "forced recovery changed committed day value")
		_expect(main._sortie_state.held_salvage == 0, "forced recovery retained unbanked cargo")
		_expect(forced_text.find("Forced recovery at nightfall") != -1 and forced_text.find("unbanked progress lost") != -1, "forced debrief omitted recovery consequence")
		_expect(main._anomaly_survey.has_completed_discovery(), "forced recovery lost profile discovery")

	var reloaded := ExpansionProfileState.new(TEST_PROFILE_PATH)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(reload_report.get("status") == "loaded", "profile did not reload")
	_expect(reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "profile reload lost scanner")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "profile reload lost discovery")
	_cleanup_profile()

	if not _failures.is_empty():
		for failure in _failures:
			push_error("Night debrief smoke failed: %s" % failure)
		quit(1)
		return
	print("Night debrief smoke passed: voluntary_day=1 dives=2 banked=2 value=450 discovery=1 next_day=2 forced_recovery=true unbanked_cleared=true profile_reloaded=true survival_tax=false.")
	quit(0)


func _instant_salvage(world) -> Array:
	var targets := []
	for salvage in world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			targets.append(salvage)
	return targets


func _contains_future_tax(text: String) -> bool:
	var lowered := text.to_lower()
	for word in ["food", "water", "power", "forecast"]:
		if lowered.find(word) != -1:
			return true
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
