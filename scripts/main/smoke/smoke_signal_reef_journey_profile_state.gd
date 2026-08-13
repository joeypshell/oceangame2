extends SceneTree

const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SignalReefJourneyProfileState := preload("res://scripts/main/signal_reef_journey_profile_state.gd")

const PROFILE_PATH := "user://oceangame2_signal_reef_journey_profile_smoke.json"
const LEGACY_PATH := "user://oceangame2_signal_reef_journey_v5_smoke.json"
const INVALID_PATH := "user://oceangame2_signal_reef_journey_invalid_smoke.json"
const BLOCKED_PATH := "user://oceangame2_signal_reef_journey_blocked"
const KITE_ID := "spark_ray_juvenile_01"
const MICA_ID := "veil_cuttle_juvenile_01"
const MARL_ID := "silt_hound_juvenile_01"
const FLOW_MEMORY_ID := "held_the_flow"
const ANCHOR_ADAPTATION_ID := "anchor_fins"
const GUARDIAN_ADAPTATION_ID := "guardian_pulse"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	_test_empty_and_schema_v5_migration()
	_test_exact_once_commit_next_day_and_reload()
	_test_malformed_payloads()
	_test_transaction_rollback()
	_cleanup()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Signal Reef journey profile smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"Signal Reef journey profile smoke passed: outer_schema=%d journey_schema=%d migration=v5_empty identity=kite adaptation=anchor_fins exact_once=true same_day=blocked next_day=restored reload=true malformed=rejected rollback=true mica_marl=unchanged field_progress=persisted_false." % [
			ExpansionProfileState.SCHEMA_VERSION,
			SignalReefJourneyProfileState.PROFILE_SCHEMA_VERSION,
		]
	)
	quit(0)


func _test_empty_and_schema_v5_migration() -> void:
	var fresh := ExpansionProfileState.new(PROFILE_PATH, true)
	var report: Dictionary = fresh.load_profile()
	_expect(report.get("status") == "missing", "fresh profile did not start missing")
	_expect(str(fresh.signal_reef_journey_report().get("state", "")) == "unresolved", "fresh profile invented journey completion")
	_expect(not fresh.report().has("field_progress"), "fresh profile persisted transient field progress")

	var legacy_profile := ExpansionProfileState.new(LEGACY_PATH, false)
	legacy_profile.load_profile()
	_commit_three_companions(legacy_profile)
	var legacy_payload: Dictionary = legacy_profile.report()
	legacy_payload.erase("status")
	legacy_payload.erase("regional_journey_profile")
	legacy_payload["schema_version"] = ExpansionProfileState.COMPANION_SCHEMA_VERSION
	_write_json(LEGACY_PATH, legacy_payload)
	var migrated := ExpansionProfileState.new(LEGACY_PATH, true)
	var migration: Dictionary = migrated.load_profile()
	_expect(migration.get("status") == "migrated_v5", "schema-v5 profile did not report migration: %s" % migration)
	_expect(str(migrated.signal_reef_journey_report().get("state", "")) == "unresolved", "schema-v5 migration invented completion")
	_expect(_identity_snapshot(migrated) == _identity_snapshot(legacy_profile), "schema-v5 migration changed Kite, Mica, or Marl")
	var written := _read_json(LEGACY_PATH)
	_expect(int(written.get("schema_version", 0)) == ExpansionProfileState.SCHEMA_VERSION, "migration did not persist outer schema 6")
	_expect(
		str((written.get("regional_journey_profile", {}) as Dictionary).get("journey_id", "")) == SignalReefJourneyProfileState.JOURNEY_ID
		and str((written.get("regional_journey_profile", {}) as Dictionary).get("adaptation_id", "")).is_empty()
		and not bool((written.get("regional_journey_profile", {}) as Dictionary).get("committed", true))
		and not bool((written.get("regional_journey_profile", {}) as Dictionary).get("restored", true)),
		"migration did not write exact empty journey state"
	)


func _test_exact_once_commit_next_day_and_reload() -> void:
	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	_commit_adapted_kite(profile)
	var before := _identity_snapshot(profile)
	var wrong_location: Dictionary = profile.commit_signal_reef_journey(
		ANCHOR_ADAPTATION_ID, "production_level_01", "wrong_entry", 4, true
	)
	_expect(wrong_location.get("reason") == "wrong_commit_location", "wrong entry committed journey")
	_expect(str(profile.signal_reef_journey_report().get("state", "")) == "unresolved", "wrong entry changed journey state")
	_expect(profile.commit_signal_reef_journey(GUARDIAN_ADAPTATION_ID, "production_level_01", "surface_boat_entry", 4, true).get("reason") == "adaptation_not_selected", "wrong adaptation committed journey")
	var committed: Dictionary = profile.commit_signal_reef_journey(
		ANCHOR_ADAPTATION_ID, "production_level_01", "surface_boat_entry", 4, true
	)
	_expect(bool(committed.get("changed", false)) and committed.get("reason") == "committed", "canonical boat did not commit exactly once")
	_expect(profile.commit_signal_reef_journey(ANCHOR_ADAPTATION_ID, "production_level_01", "surface_boat_entry", 4, true).get("reason") == "already_committed", "duplicate boat check rewrote history")
	_expect(profile.advance_signal_reef_journey_day(4, true).get("reason") == "waiting_next_day", "same day restored nursery")
	var waiting_reload := ExpansionProfileState.new(PROFILE_PATH, true)
	_expect(waiting_reload.load_profile().get("status") == "loaded", "committed journey failed to reload")
	_expect(str(waiting_reload.signal_reef_journey_report().get("state", "")) == "committed_waiting_next_day", "reload lost waiting state")
	var restored: Dictionary = waiting_reload.advance_signal_reef_journey_day(5, true)
	_expect(bool(restored.get("changed", false)) and restored.get("reason") == "restored", "later day did not restore nursery")
	_expect(waiting_reload.advance_signal_reef_journey_day(6, true).get("reason") == "already_restored", "restoration duplicated")
	var restored_reload := ExpansionProfileState.new(PROFILE_PATH, true)
	_expect(restored_reload.load_profile().get("status") == "loaded", "restored journey failed to reload")
	var final: Dictionary = restored_reload.signal_reef_journey_report()
	_expect(str(final.get("state", "")) == "restored" and int(final.get("committed_day_number", 0)) == 4 and int(final.get("restoration_day_number", 0)) == 5, "reload changed exact journey days")
	_expect(_identity_snapshot(restored_reload) == before, "journey transaction changed companion identity/history")
	_expect(not _contains_transient_state(_read_json(PROFILE_PATH)), "journey profile persisted transient field state")


func _test_malformed_payloads() -> void:
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	_commit_adapted_kite(profile)
	var base: Dictionary = profile.report()
	base.erase("status")
	var malformed := []
	var wrong_journey := base.duplicate(true)
	wrong_journey["regional_journey_profile"]["journey_id"] = "wrong_journey"
	malformed.append(wrong_journey)
	var bad_day := base.duplicate(true)
	bad_day["regional_journey_profile"]["committed"] = true
	bad_day["regional_journey_profile"]["adaptation_id"] = ANCHOR_ADAPTATION_ID
	bad_day["regional_journey_profile"]["committed_day_number"] = 0
	malformed.append(bad_day)
	var wrong_day_type := base.duplicate(true)
	wrong_day_type["regional_journey_profile"]["committed_day_number"] = {"not": "a day"}
	malformed.append(wrong_day_type)
	var transient := base.duplicate(true)
	transient["regional_journey_profile"]["field_progress"] = 0.5
	malformed.append(transient)
	var mismatched := base.duplicate(true)
	mismatched["regional_journey_profile"]["committed"] = true
	mismatched["regional_journey_profile"]["adaptation_id"] = GUARDIAN_ADAPTATION_ID
	mismatched["regional_journey_profile"]["committed_day_number"] = 4
	malformed.append(mismatched)
	for payload in malformed:
		_write_json(INVALID_PATH, payload)
		var invalid := ExpansionProfileState.new(INVALID_PATH, true)
		_expect(invalid.load_profile().get("status") == "invalid_schema", "malformed journey payload was accepted")
		_expect(str(invalid.signal_reef_journey_report().get("state", "")) == "unresolved", "malformed payload leaked completion")


func _test_transaction_rollback() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BLOCKED_PATH))
	var profile := ExpansionProfileState.new(BLOCKED_PATH, true)
	profile.load_profile()
	_commit_adapted_kite(profile)
	var result: Dictionary = profile.commit_signal_reef_journey(
		ANCHOR_ADAPTATION_ID, "production_level_01", "surface_boat_entry", 4, true
	)
	_expect(result.get("reason") == "storage_error", "forced write failure did not report storage_error")
	_expect(str(profile.signal_reef_journey_report().get("state", "")) == "unresolved", "failed save retained in-memory journey commitment")


func _commit_adapted_kite(profile) -> void:
	profile.commit_companion_rescue(KITE_ID, "spark_ray", "Kite", false)
	profile.earn_companion_memory(FLOW_MEMORY_ID, false)
	profile.select_companion_adaptation(ANCHOR_ADAPTATION_ID, false)


func _commit_three_companions(profile) -> void:
	_commit_adapted_kite(profile)
	profile.commit_companion_rescue(MICA_ID, "veil_cuttle", "Mica", false)
	profile.commit_companion_rescue(MARL_ID, "silt_hound", "Marl", false)
	profile.select_active_companion(MICA_ID, false)


func _identity_snapshot(profile) -> Dictionary:
	return profile.companion_report().duplicate(true)


func _contains_transient_state(value) -> bool:
	var forbidden := ["field_progress", "pending", "action_progress", "pressure_phase", "cooldown", "movement_target"]
	if typeof(value) == TYPE_DICTIONARY:
		for key in value:
			if forbidden.has(str(key)) or _contains_transient_state(value[key]):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item in value:
			if _contains_transient_state(item):
				return true
	return false


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	return json.data as Dictionary if error == OK and typeof(json.data) == TYPE_DICTIONARY else {}


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write fixture %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _cleanup() -> void:
	for base_path in [PROFILE_PATH, LEGACY_PATH, INVALID_PATH, BLOCKED_PATH]:
		for suffix in ["", ".tmp", ".bak"]:
			var path := "%s%s" % [base_path, suffix]
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var absolute := ProjectSettings.globalize_path(BLOCKED_PATH)
	if DirAccess.dir_exists_absolute(absolute):
		DirAccess.remove_absolute(absolute)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
