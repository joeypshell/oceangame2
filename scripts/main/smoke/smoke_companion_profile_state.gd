extends SceneTree

const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const PROFILE_PATH := "user://oceangame2_companion_profile_smoke.json"
const LEGACY_PATH := "user://oceangame2_companion_profile_v4_smoke.json"
const ISOLATED_PATH := "user://oceangame2_companion_profile_isolated_smoke.json"
const BLOCKED_PATH := "user://oceangame2_companion_profile_blocked"
const SPECIES_ID := "spark_ray"
const CALLSIGN := "Test Ray"
const FLOW_MEMORY_ID := "held_the_flow"
const GROUND_MEMORY_ID := "stood_ground"
const ANCHOR_ADAPTATION_ID := "anchor_fins"
const GUARDIAN_ADAPTATION_ID := "guardian_pulse"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	_test_fresh_and_v4_migration()
	_test_exact_once_round_trip()
	_test_storage_rollback()
	_test_transient_state_rejection()
	_test_review_profile_isolation()
	_cleanup()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Companion profile smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"Companion profile smoke passed: schema=%d individual=%s rescue_exact_once=true memories_exact_once=true adaptation=%s reload_unmounted=true v4_migration=true review_isolated=true riding_derived=true." % [
			ExpansionProfileState.SCHEMA_VERSION,
			CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
			ANCHOR_ADAPTATION_ID,
		]
	)
	quit(0)


func _test_fresh_and_v4_migration() -> void:
	var fresh := ExpansionProfileState.new(PROFILE_PATH, true)
	var fresh_report: Dictionary = fresh.load_profile()
	_expect(fresh_report.get("status") == "missing", "fresh profile did not start missing")
	_expect(not fresh.has_committed_companion(), "fresh profile received a companion")
	_expect(not fresh.active_companion_available_on_sortie_launch(), "fresh profile received riding availability")

	_write_json(LEGACY_PATH, _v4_payload())
	var legacy := ExpansionProfileState.new(LEGACY_PATH, true)
	var migration: Dictionary = legacy.load_profile()
	_expect(migration.get("status") == "migrated_v4", "v4 profile did not report deterministic migration: %s" % migration)
	_expect(not legacy.has_committed_companion(), "v4 migration invented a companion")
	_expect(not legacy.active_companion_available_on_sortie_launch(), "v4 migration invented riding availability")
	var migrated_payload := _read_json(LEGACY_PATH)
	_expect(migrated_payload.get("schema_version") == ExpansionProfileState.SCHEMA_VERSION, "v4 profile was not rewritten at the current version")
	_expect(
		typeof(migrated_payload.get("companion_profile")) == TYPE_DICTIONARY
		and (migrated_payload["companion_profile"] as Dictionary).get("individual", {}).is_empty(),
		"v4 migration did not write the empty companion default"
	)


func _test_exact_once_round_trip() -> void:
	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var before_launch := profile.active_companion_available_on_sortie_launch()
	var rescue: Dictionary = profile.commit_companion_rescue(
		CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
		SPECIES_ID,
		CALLSIGN,
		true
	)
	_expect(bool(rescue.get("changed", false)), "rescue commitment did not persist")
	_expect(not before_launch, "fresh sortie snapshot unexpectedly had a companion")
	var duplicate_rescue: Dictionary = profile.commit_companion_rescue(
		CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
		SPECIES_ID,
		"Rerolled Name",
		true
	)
	_expect(duplicate_rescue.get("reason") == "already_committed", "duplicate rescue was not idempotent")
	_expect(profile.companion_report().get("individual", {}).get("callsign") == CALLSIGN, "duplicate rescue rerolled callsign")

	var early_adaptation: Dictionary = profile.select_companion_adaptation(ANCHOR_ADAPTATION_ID, true)
	_expect(early_adaptation.get("reason") == "missing_required_memory", "adaptation ignored its memory requirement")
	var memory: Dictionary = profile.earn_companion_memory(FLOW_MEMORY_ID, true)
	_expect(bool(memory.get("changed", false)), "earned memory did not persist")
	var duplicate_memory: Dictionary = profile.earn_companion_memory(FLOW_MEMORY_ID, true)
	_expect(duplicate_memory.get("reason") == "already_earned", "duplicate memory was not idempotent")
	var adaptation: Dictionary = profile.select_companion_adaptation(ANCHOR_ADAPTATION_ID, true)
	_expect(bool(adaptation.get("changed", false)), "eligible adaptation did not persist")
	var duplicate_adaptation: Dictionary = profile.select_companion_adaptation(ANCHOR_ADAPTATION_ID, true)
	_expect(duplicate_adaptation.get("reason") == "already_selected", "duplicate adaptation was not idempotent")
	profile.earn_companion_memory(GROUND_MEMORY_ID, true)
	var exclusive_adaptation: Dictionary = profile.select_companion_adaptation(GUARDIAN_ADAPTATION_ID, true)
	_expect(exclusive_adaptation.get("reason") == "adaptation_already_selected", "mutually exclusive adaptation replaced the committed choice")

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload: Dictionary = reloaded.load_profile()
	var companion: Dictionary = reloaded.companion_report()
	_expect(reload.get("status") == "loaded", "companion profile did not reload: %s" % reload)
	_expect(reloaded.has_committed_companion(), "reload lost rescue commitment")
	_expect(reloaded.active_companion_available_on_sortie_launch(), "next sortie could not derive riding availability")
	_expect(companion.get("individual", {}).get("callsign") == CALLSIGN, "reload lost callsign")
	_expect(companion.get("individual", {}).get("earned_memory_ids", []).has(FLOW_MEMORY_ID), "reload lost earned memory")
	_expect(companion.get("individual", {}).get("selected_adaptation_id") == ANCHOR_ADAPTATION_ID, "reload lost selected adaptation")
	_expect(not _contains_transient_state(companion), "profile report exposed transient companion state")


func _test_transient_state_rejection() -> void:
	var payload := _read_json(PROFILE_PATH)
	if payload.is_empty():
		_expect(false, "could not read committed companion fixture")
		return
	var companion: Dictionary = payload.get("companion_profile", {})
	companion["mounted"] = true
	_write_json(PROFILE_PATH, payload)
	var invalid := ExpansionProfileState.new(PROFILE_PATH, true)
	var report: Dictionary = invalid.load_profile()
	_expect(report.get("status") == "invalid_schema", "persisted mounted state was accepted")
	_expect(not invalid.has_committed_companion(), "invalid transient profile leaked committed state")


func _test_storage_rollback() -> void:
	var blocked_absolute := ProjectSettings.globalize_path(BLOCKED_PATH)
	DirAccess.make_dir_recursive_absolute(blocked_absolute)
	var profile := ExpansionProfileState.new(BLOCKED_PATH, true)
	profile.load_profile()
	var rescue: Dictionary = profile.commit_companion_rescue(
		CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
		SPECIES_ID,
		CALLSIGN,
		true
	)
	_expect(rescue.get("reason") == "storage_error", "failed rescue save did not report storage error")
	_expect(not profile.has_committed_companion(), "failed rescue save did not roll back companion state")
	DirAccess.remove_absolute(blocked_absolute)


func _test_review_profile_isolation() -> void:
	var isolated := ExpansionProfileState.new(ISOLATED_PATH, false)
	isolated.load_profile()
	isolated.commit_companion_rescue(
		CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
		SPECIES_ID,
		CALLSIGN,
		true
	)
	isolated.earn_companion_memory(FLOW_MEMORY_ID, true)
	isolated.select_companion_adaptation(ANCHOR_ADAPTATION_ID, true)
	_expect(isolated.has_committed_companion(), "isolated review fixture could not model committed state in memory")
	_expect(not FileAccess.file_exists(ISOLATED_PATH), "isolated review fixture mutated disk profile")
	var normal := ExpansionProfileState.new(ISOLATED_PATH, true)
	normal.load_profile()
	_expect(not normal.has_committed_companion(), "isolated review state leaked into normal profile")


func _v4_payload() -> Dictionary:
	return {
		"schema_version": 4,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
		"material_inventory": {},
		"completed_projects": [],
		"banked_tool_target_ids": [],
	}


func _contains_transient_state(value) -> bool:
	var forbidden := ["position", "velocity", "control_mode", "mounted", "target", "palette_selection", "cooldown", "animation", "encounter_progress"]
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
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write fixture %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _cleanup() -> void:
	for base_path in [PROFILE_PATH, LEGACY_PATH, ISOLATED_PATH]:
		for suffix in ["", ".tmp", ".bak"]:
			var path := "%s%s" % [base_path, suffix]
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var blocked_absolute := ProjectSettings.globalize_path(BLOCKED_PATH)
	if DirAccess.dir_exists_absolute(blocked_absolute):
		DirAccess.remove_absolute(blocked_absolute)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
