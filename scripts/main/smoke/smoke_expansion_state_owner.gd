extends SceneTree

const ExpeditionDiscoveryState := preload("res://scripts/main/expedition_discovery_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
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

	_cleanup_files()
	profile = ExpansionProfileState.new(TEST_PATH)
	profile.load_profile()
	var unlock: Dictionary = profile.unlock_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID, true)
	_expect(bool(unlock.get("changed", false)), "scanner capability did not persist")
	_expect(FileAccess.file_exists(TEST_PATH), "profile save file was not created")
	_expect(not FileAccess.file_exists("%s.tmp" % TEST_PATH), "atomic temp file leaked")
	_expect(not FileAccess.file_exists("%s.bak" % TEST_PATH), "atomic backup file leaked")

	var reloaded := ExpansionProfileState.new(TEST_PATH)
	report = reloaded.load_profile()
	_expect(report.get("status") == "loaded", "saved profile did not reload")
	_expect(reloaded.has_capability(ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID), "reloaded scanner capability missing")
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
	final_reload.load_profile()
	_expect(final_reload.has_completed_discovery(ExpansionProfileState.ANOMALY_DISCOVERY_ID), "discovery did not survive reload")
	_create_pending(expedition)
	var repeated_commit: Dictionary = expedition.commit_at("production_slice_01", "surface_boat_entry", final_reload)
	_expect(repeated_commit.get("status") == "already_committed", "repeat commit was not idempotent")
	_expect(not expedition.has_pending(), "repeat commit retained stale pending discovery")

	_create_pending(expedition)
	expedition.clear_pending("oxygen_failure")
	_expect(not expedition.has_pending(), "oxygen failure retained pending discovery")
	_create_pending(expedition)
	expedition.clear_pending("reset")
	_expect(not expedition.has_pending(), "reset retained pending discovery")

	var final_report := final_reload.report()
	_cleanup_files()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Expansion state owner smoke failed: %s" % failure)
		quit(1)
		return
	print("Expansion state owner smoke passed: schema=%d capability=%s discovery=%s pending_cleanup=hazard,oxygen_failure,reset cross_map=true exact_once=true report=%s." % [
		ExpansionProfileState.SCHEMA_VERSION,
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		ExpansionProfileState.ANOMALY_DISCOVERY_ID,
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
