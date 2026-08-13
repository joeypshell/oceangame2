extends SceneTree

const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SignalReefJourneyProfileState := preload("res://scripts/main/signal_reef_journey_profile_state.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")
const TEST_PATH := "user://oceangame2_expansion_state_test.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_files()
	var profile := ExpansionProfileState.new(TEST_PATH)
	var report: Dictionary = profile.load_profile()
	_expect(report.get("status") == "missing", "missing profile did not recover as fresh")
	_expect(report.get("completed_discoveries", []).is_empty(), "fresh profile had discoveries")
	_expect(report.get("unlocked_capabilities", []).is_empty(), "fresh profile had capabilities")
	_expect(report.get("banked_tool_target_ids", []).is_empty(), "fresh profile had banked tool targets")

	_write_text(TEST_PATH, "{not valid json")
	profile = ExpansionProfileState.new(TEST_PATH)
	report = profile.load_profile()
	_expect(report.get("status") == "invalid_json", "corrupt profile did not recover")
	_expect(not profile.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "corrupt profile leaked capability")

	_write_text(TEST_PATH, JSON.stringify({
		"schema_version": 99,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
		"wallet": 500,
	}))
	profile = ExpansionProfileState.new(TEST_PATH)
	report = profile.load_profile()
	_expect(report.get("status") == "invalid_schema", "unsupported/extra profile fields were accepted")
	_expect(not report.get("failures", []).is_empty(), "invalid profile had no diagnostic")

	_write_text(TEST_PATH, JSON.stringify({
		"schema_version": 3,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
		"material_inventory": {},
		"completed_projects": [],
	}))
	profile = ExpansionProfileState.new(TEST_PATH)
	report = profile.load_profile()
	_expect(report.get("status") == "migrated_v3", "schema-v3 profile did not migrate")
	_expect(report.get("banked_tool_target_ids", []).is_empty(), "schema-v3 migration invented a banked tool target")

	for invalid_ids in [["unsupported_target"], [ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID, ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID]]:
		_write_text(TEST_PATH, JSON.stringify({
			"schema_version": ExpansionProfileState.SCHEMA_VERSION,
			"completed_discoveries": [],
			"unlocked_capabilities": [],
			"material_inventory": {},
			"completed_projects": [],
			"banked_tool_target_ids": invalid_ids,
			"companion_profile": CompanionProfileState.new().payload(),
			"regional_journey_profile": SignalReefJourneyProfileState.new().payload(),
		}))
		profile = ExpansionProfileState.new(TEST_PATH)
		_expect(profile.load_profile().get("status") == "invalid_schema", "invalid banked tool target ids were accepted")

	_write_text(TEST_PATH, JSON.stringify({
		"schema_version": ExpansionProfileState.SCHEMA_VERSION,
		"completed_discoveries": [],
		"unlocked_capabilities": [ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID],
		"material_inventory": {},
		"completed_projects": [],
		"banked_tool_target_ids": [],
		"companion_profile": CompanionProfileState.new().payload(),
		"regional_journey_profile": SignalReefJourneyProfileState.new().payload(),
	}))
	profile = ExpansionProfileState.new(TEST_PATH)
	report = profile.load_profile()
	_expect(report.get("status") == "migrated_scanner_purchase", "legacy scanner purchase did not migrate: %s" % report)
	_expect(profile.has_completed_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID), "scanner migration omitted blueprint: %s" % report)
	_expect(profile.has_completed_project(ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID), "scanner migration omitted project: %s" % report)

	_cleanup_files()
	profile = ExpansionProfileState.new(TEST_PATH)
	profile.load_profile()
	var unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, true)
	_expect(unlock.get("reason") == "project_transaction_required", "scanner bypassed its project transaction")
	profile.complete_discovery(ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID, false)
	profile.deposit_materials({ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1}, false)
	var scanner_build: Dictionary = profile.complete_material_project(_scanner_project_definition(), true)
	_expect(bool(scanner_build.get("changed", false)), "scanner project did not persist")
	var banked_recorder: Dictionary = profile.bank_tool_target(ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID, true)
	_expect(bool(banked_recorder.get("changed", false)), "recorder clearance did not persist")
	var repeat_bank: Dictionary = profile.bank_tool_target(ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID, true)
	_expect(repeat_bank.get("reason") == "already_banked", "recorder clearance banking was not exact-once")
	_expect(FileAccess.file_exists(TEST_PATH), "profile save file was not created")
	_expect(not FileAccess.file_exists("%s.tmp" % TEST_PATH), "atomic temp file leaked")
	_expect(not FileAccess.file_exists("%s.bak" % TEST_PATH), "atomic backup file leaked")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	report = reloaded.load_profile()
	_expect(report.get("status") == "loaded", "saved profile did not reload")
	_expect(reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "reloaded scanner capability missing")
	_expect(reloaded.has_banked_tool_target(ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID), "reloaded recorder clearance missing")
	var repeat_unlock: Dictionary = reloaded.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, true)
	_expect(repeat_unlock.get("reason") == "already_unlocked", "scanner unlock was not idempotent")

	var expedition := ExpeditionDiscoveryState.new()
	var pending: Dictionary = _create_pending(expedition)
	_expect(pending.get("status") == "pending_created", "pending discovery was not created")
	expedition.on_map_transition("production_slice_04")
	_expect(expedition.has_pending(), "connector transition cleared pending discovery")
	var cleared: Dictionary = expedition.clear_pending("hazard")
	_expect(cleared.get("status") == "cleared_hazard", "hazard cleanup report mismatch")
	_expect(not expedition.has_pending(), "hazard cleanup retained pending discovery")

	_create_pending(expedition)
	var wrong_commit: Dictionary = expedition.commit_at("production_slice_04", "relay_sub_entry", reloaded)
	_expect(wrong_commit.get("status") == "wrong_commit_location", "wrong return committed discovery")
	_expect(expedition.has_pending(), "wrong return discarded pending discovery")
	var committed: Dictionary = expedition.commit_at("production_slice_01", "surface_boat_entry", reloaded)
	_expect(committed.get("status") == "committed", "canonical boat return did not commit")
	_expect(not expedition.has_pending(), "commit retained pending discovery")
	_expect(reloaded.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "profile did not record discovery")

	var final_reload := ExpansionProfileState.new(TEST_PATH)
	var cutter_migration: Dictionary = final_reload.load_profile()
	_expect(cutter_migration.get("status") == "loaded", "old committed anomaly profile did not remain load-compatible")
	_expect(final_reload.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "discovery did not survive reload")
	_expect(final_reload.has_completed_discovery(ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID), "old committed anomaly did not imply cutter blueprint")
	var migrated_reload := ExpansionProfileState.new(TEST_PATH)
	_expect(migrated_reload.load_profile().get("status") == "loaded", "cutter-blueprint migration was not persisted exactly once")
	_expect(migrated_reload.has_completed_discovery(ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID), "persisted cutter blueprint was lost on reload")
	final_reload = migrated_reload
	_create_pending(expedition)
	var repeated_commit: Dictionary = expedition.commit_at("production_slice_01", "surface_boat_entry", final_reload)
	_expect(repeated_commit.get("status") == "already_committed", "repeat commit was not idempotent")
	_expect(not expedition.has_pending(), "repeat commit retained stale pending discovery")

	var regional_pending: Dictionary = expedition.create_pending(
		ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID,
		"production_level_01",
		"lower_right_signal_reef_survey",
		"production_level_01",
		"surface_boat_entry",
		{
			"target_type": "regional",
			"finding_label": "Discovery logged: Signal Reef chart",
			"next_lead_label": "Next lead: deeper harmonic below reef",
		}
	)
	_expect(regional_pending.get("status") == "pending_created", "regional pending discovery was not created")
	_expect(
		str(expedition.pending_metadata().get("next_lead_label", "")) == "Next lead: deeper harmonic below reef",
		"regional pending metadata lost the next lead"
	)
	var wrong_regional_commit: Dictionary = expedition.commit_at("production_slice_01", "surface_boat_entry", final_reload)
	_expect(wrong_regional_commit.get("status") == "wrong_commit_location", "regional discovery committed at wrong map")
	var regional_commit: Dictionary = expedition.commit_at("production_level_01", "surface_boat_entry", final_reload)
	_expect(regional_commit.get("status") == "committed", "regional discovery did not commit at full-level boat")
	_expect(
		final_reload.has_completed_discovery(ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID),
		"profile did not record regional discovery"
	)
	var regional_reload := ExpansionProfileState.new(TEST_PATH)
	regional_reload.load_profile()
	_expect(
		regional_reload.has_completed_discovery(ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID),
		"regional discovery did not survive reload"
	)
	final_reload = regional_reload

	_create_pending(expedition)
	expedition.clear_pending("oxygen_failure")
	_expect(not expedition.has_pending(), "oxygen failure retained pending discovery")
	_create_pending(expedition)
	expedition.clear_pending("reset")
	_expect(not expedition.has_pending(), "reset retained pending discovery")

	var sortie := SortieState.new(90.0)
	sortie.begin_map_leg("production_slice_01", "surface_boat_entry", 90.0)
	sortie.collect_salvage("salvage_safe_route", 100)
	_expect(sortie.held_salvage == 1 and sortie.held_salvage_score == 100, "sortie did not own held cargo")
	_expect(not sortie.apply_oxygen_penalty(12.0), "nonlethal oxygen penalty failed the sortie")
	_expect(is_equal_approx(sortie.oxygen_seconds, 78.0), "sortie did not own current oxygen")
	var dropped_ids := sortie.clear_held()
	_expect(dropped_ids == ["salvage_safe_route"] and sortie.held_salvage == 0, "sortie cargo cleanup mismatch")
	sortie.mark_failed("oxygen_failure")
	_expect(sortie.failed and sortie.failure_reason == "oxygen_failure", "sortie did not own local failure")

	var day := ExpeditionDayState.new(300.0)
	day.on_map_loaded("production_slice_01")
	day.record_sortie_started()
	day.record_bank(2, 250)
	day.record_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID)
	day.daylight_remaining_seconds = 225.0
	day.on_map_transition("production_slice_04")
	var transition_report := day.report()
	_expect(transition_report.get("daylight_remaining_seconds") == 225.0, "connector transition reset daylight")
	_expect(transition_report.get("banked_score") == 250, "connector transition reset day bank totals")
	_expect(transition_report.get("sortie_count") == 1, "connector transition reset sortie count")
	day.end_day("voluntary")
	_expect(day.phase == ExpeditionDayState.PHASE_DEBRIEF, "day owner did not retain end-day state")
	day.begin_next_day()
	_expect(day.day_number == 2 and day.banked_score == 0, "next-day reset retained day-local totals")

	var final_report := final_reload.report()
	_cleanup_files()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Expansion state owner smoke failed: %s" % failure)
		quit(1)
		return
	print("Expansion state owner smoke passed: schema=%d capability=%s discovery=%s regional_discovery=%s pending_cleanup=hazard,oxygen_failure,reset cross_map=true sortie_owner=true day_owner=true exact_once=true report=%s." % [
		ExpansionProfileState.SCHEMA_VERSION,
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		ExpansionProfileState.ANOMALY_DISCOVERY_ID,
		ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID,
		str(final_report),
	])
	quit(0)


func _create_pending(expedition) -> Dictionary:
	return expedition.create_pending(
		ExpansionProfileState.ANOMALY_DISCOVERY_ID,
		"production_slice_02",
		"lower_right_anomaly_survey",
		"production_slice_01",
		"surface_boat_entry"
	)


func _scanner_project_definition() -> Dictionary:
	return {
		"id": ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID,
		"required_discovery_id": ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID,
		"required_materials": {ExpansionProfileState.TITANIUM_MATERIAL_ID: 1, ExpansionProfileState.COIL_MATERIAL_ID: 1},
		"unlocks_capability_id": ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		"target_id": ExpansionProfileState.SURVEY_SCANNER_TARGET_ID,
		"build_phase": "night_debrief",
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write test profile")
		return
	file.store_string(text)
	file.close()


func _cleanup_files() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [TEST_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
