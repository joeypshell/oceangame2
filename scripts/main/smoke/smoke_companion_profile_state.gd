extends SceneTree

const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SignalReefJourneyProfileState := preload("res://scripts/main/signal_reef_journey_profile_state.gd")

const PROFILE_PATH := "user://oceangame2_companion_profile_smoke.json"
const LEGACY_PATH := "user://oceangame2_companion_profile_v4_smoke.json"
const COMPANION_V1_PATH := "user://oceangame2_companion_profile_v1_smoke.json"
const COMPANION_V2_PATH := "user://oceangame2_companion_profile_v2_smoke.json"
const ISOLATED_PATH := "user://oceangame2_companion_profile_isolated_smoke.json"
const BLOCKED_PATH := "user://oceangame2_companion_profile_blocked"
const SPECIES_ID := "spark_ray"
const SECOND_SPECIES_ID := "veil_cuttle"
const THIRD_SPECIES_ID := "silt_hound"
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
	_test_companion_v1_migration_and_collection()
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
		"Companion profile smoke passed: outer_schema=%d companion_schema=%d individuals=%s,%s,%s v1_v2_migration_exact=true active_selection=marl riding_derived=false rescue_exact_once=true memories_exact_once=true adaptation=%s reload_unmounted=true v4_migration=true review_isolated=true." % [
			ExpansionProfileState.SCHEMA_VERSION,
			CompanionProfileState.PROFILE_SCHEMA_VERSION,
			CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
			CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID,
			CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID,
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
		and (migrated_payload["companion_profile"] as Dictionary).get("individuals", []).is_empty(),
		"v4 migration did not write the empty companion default"
	)


func _test_companion_v1_migration_and_collection() -> void:
	var empty_v1 := CompanionProfileState.new()
	_expect(empty_v1.load_payload({"schema_version": 1, "individual": {}, "active_individual_id": ""}).is_empty(), "empty schema v1 profile did not migrate")
	_expect(empty_v1.payload().get("schema_version") == 3 and empty_v1.individuals().is_empty(), "empty schema v1 migration invented a companion")
	_write_json(COMPANION_V1_PATH, _outer_payload_with_companion_v1())
	var profile := ExpansionProfileState.new(COMPANION_V1_PATH, true)
	var migration: Dictionary = profile.load_profile()
	_expect(migration.get("status") == "migrated_companion_v1_to_v3", "companion v1 payload did not report migration: %s" % migration)
	var persisted: Dictionary = _read_json(COMPANION_V1_PATH).get("companion_profile", {})
	_expect(persisted.get("schema_version") == CompanionProfileState.PROFILE_SCHEMA_VERSION, "companion migration did not write schema v3")
	var persisted_individuals: Array = persisted.get("individuals", [])
	_expect(persisted_individuals.size() == 1, "companion migration duplicated or lost Kite")
	_expect(persisted.get("active_individual_id") == "", "companion migration changed empty active selection")
	if persisted_individuals.is_empty():
		return
	var migrated_kite: Dictionary = persisted_individuals[0]
	_expect(migrated_kite.get("callsign") == CALLSIGN, "companion migration changed Kite callsign")
	_expect(migrated_kite.get("earned_memory_ids", []).has(FLOW_MEMORY_ID), "companion migration lost Kite memory")
	_expect(migrated_kite.get("selected_adaptation_id") == ANCHOR_ADAPTATION_ID, "companion migration lost Kite adaptation")
	_test_companion_v2_migration()
	var second_load := ExpansionProfileState.new(COMPANION_V1_PATH, true)
	_expect(second_load.load_profile().get("status") == "loaded", "companion migration was not idempotent")
	_expect((second_load.companion_report().get("individuals", []) as Array).size() == 1, "second load duplicated Kite")
	_expect(bool(second_load.select_active_companion(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, true).get("changed", false)), "could not explicitly select migrated Kite")
	var mica: Dictionary = second_load.commit_companion_rescue(
		CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID,
		SECOND_SPECIES_ID,
		"Mica",
		true
	)
	_expect(bool(mica.get("changed", false)), "second companion commitment failed")
	var two_report := second_load.companion_report()
	_expect((two_report.get("individuals", []) as Array).size() == 2, "two-individual collection did not persist")
	_expect(two_report.get("active_individual_id") == CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "second commitment replaced Kite selection")
	_expect(second_load.commit_companion_rescue(CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, SECOND_SPECIES_ID, "Again", true).get("reason") == "already_committed", "duplicate Mica commitment was not idempotent")
	var marl: Dictionary = second_load.commit_companion_rescue(
		CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, THIRD_SPECIES_ID, "Marl", true
	)
	_expect(bool(marl.get("changed", false)), "third companion commitment failed")
	_expect(second_load.commit_companion_rescue(CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, THIRD_SPECIES_ID, "Again", true).get("reason") == "already_committed", "duplicate Marl commitment was not idempotent")
	var three_report := second_load.companion_report()
	_expect((three_report.get("individuals", []) as Array).size() == 3, "three-individual collection did not persist")
	_expect(three_report.get("active_individual_id") == CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "third commitment replaced Kite selection")
	_expect(bool(second_load.select_active_companion(CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, true).get("changed", false)), "could not select Marl")
	var marl_report: Dictionary = second_load.companion_report()
	_expect(marl_report.get("individual", {}).get("individual_id") == CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, "active compatibility projection did not follow Marl selection")
	_expect(not bool(marl_report.get("riding_available_on_sortie_launch", true)), "Marl incorrectly derived riding availability")
	_expect(second_load.earn_companion_memory(FLOW_MEMORY_ID, false).get("reason") == "unsupported_memory", "Marl accepted Spark Ray memory")
	var reloaded := ExpansionProfileState.new(COMPANION_V1_PATH, true)
	reloaded.load_profile()
	_expect((reloaded.companion_report().get("individuals", []) as Array).size() == 3, "reload lost three-individual collection")
	_expect(reloaded.companion_report().get("active_individual_id") == CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, "reload lost Marl selection")
	_test_invalid_collection_payloads()


func _test_companion_v2_migration() -> void:
	_write_json(COMPANION_V2_PATH, _outer_payload_with_companion_v2())
	var profile := ExpansionProfileState.new(COMPANION_V2_PATH, true)
	var migration: Dictionary = profile.load_profile()
	_expect(migration.get("status") == "migrated_companion_v2_to_v3", "companion v2 payload did not report migration: %s" % migration)
	var report: Dictionary = profile.companion_report()
	var values: Array = report.get("individuals", [])
	_expect(values.size() == 2, "v2 migration duplicated, lost, or invented an individual")
	if values.size() == 2:
		_expect(values[0].get("callsign") == CALLSIGN and values[0].get("earned_memory_ids", []).has(FLOW_MEMORY_ID), "v2 migration changed Kite identity or memory")
		_expect(values[0].get("selected_adaptation_id") == ANCHOR_ADAPTATION_ID and values[1].get("callsign") == "Mica", "v2 migration changed Kite adaptation or Mica identity")
		_expect(values[1].get("earned_memory_ids", []).has("followed_the_bloom") and values[1].get("selected_adaptation_id") == "drift_lens", "v2 migration changed Mica memory or adaptation")
	_expect(not profile.companion_report().get("individuals", []).any(func(value): return str(value.get("individual_id", "")) == CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID), "v2 migration silently committed Marl")
	_expect(report.get("active_individual_id") == CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, "v2 migration changed active selection")
	var persisted: Dictionary = _read_json(COMPANION_V2_PATH).get("companion_profile", {})
	_expect(persisted.get("schema_version") == CompanionProfileState.PROFILE_SCHEMA_VERSION, "v2 migration did not persist schema v3")
	_expect(ExpansionProfileState.new(COMPANION_V2_PATH, true).load_profile().get("status") == "loaded", "v2 migration was not idempotent")


func _test_invalid_collection_payloads() -> void:
	var state := CompanionProfileState.new()
	var kite := _individual(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, SPECIES_ID, "Kite")
	var mica := _individual(CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, SECOND_SPECIES_ID, "Mica")
	var marl := _individual(CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, THIRD_SPECIES_ID, "Marl")
	var duplicate := {"schema_version": 3, "individuals": [kite, kite.duplicate(true)], "active_individual_id": CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID}
	_expect(_has_failure(state.validate_payload(duplicate), "duplicate individual_id"), "duplicate individual ids passed validation")
	var mismatch := {"schema_version": 3, "individuals": [mica], "active_individual_id": CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID}
	mismatch["individuals"][0]["species_id"] = SPECIES_ID
	_expect(_has_failure(state.validate_payload(mismatch), "does not match"), "individual/species mismatch passed validation")
	var invalid_active := {"schema_version": 3, "individuals": [kite], "active_individual_id": "missing_companion"}
	_expect(_has_failure(state.validate_payload(invalid_active), "reference a committed"), "unknown active id passed validation")
	var over_capacity := {"schema_version": 3, "individuals": [kite, mica, marl, kite.duplicate(true)], "active_individual_id": ""}
	_expect(_has_failure(state.validate_payload(over_capacity), "at most 3"), "over-capacity collection passed validation")
	var v2_with_marl := {"schema_version": 2, "individuals": [kite, marl], "active_individual_id": ""}
	_expect(_has_failure(state.validate_payload(v2_with_marl), "cannot contain the third"), "schema v2 accepted Marl")
	_expect(state.commit_rescue("unknown_companion", THIRD_SPECIES_ID, "Unknown").get("reason") == "unsupported_individual", "unknown individual commitment was accepted")
	_expect(state.commit_rescue(CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, SPECIES_ID, "Wrong").get("reason") == "individual_species_mismatch", "Marl accepted the wrong species")


func _individual(individual_id: String, species_id: String, callsign: String) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": species_id,
		"callsign": callsign,
		"rescue_committed": true,
		"earned_memory_ids": [],
		"selected_adaptation_id": "",
	}


func _has_failure(failures: Array[String], fragment: String) -> bool:
	for failure in failures:
		if fragment in failure:
			return true
	return false


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
	payload["companion_profile"] = []
	_write_json(PROFILE_PATH, payload)
	var wrong_shape := ExpansionProfileState.new(PROFILE_PATH, true)
	_expect(wrong_shape.load_profile().get("status") == "invalid_schema", "non-object companion profile was accepted")


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


func _outer_payload_with_companion_v1() -> Dictionary:
	var kite := _individual(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, SPECIES_ID, CALLSIGN)
	kite["earned_memory_ids"] = [FLOW_MEMORY_ID]
	kite["selected_adaptation_id"] = ANCHOR_ADAPTATION_ID
	return {
		"schema_version": ExpansionProfileState.SCHEMA_VERSION,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
		"material_inventory": {},
		"completed_projects": [],
		"banked_tool_target_ids": [],
		"companion_profile": {
			"schema_version": CompanionProfileState.LEGACY_PROFILE_SCHEMA_VERSION,
			"individual": kite,
			"active_individual_id": "",
		},
		"regional_journey_profile": SignalReefJourneyProfileState.new().payload(),
	}


func _outer_payload_with_companion_v2() -> Dictionary:
	var kite := _individual(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, SPECIES_ID, CALLSIGN)
	kite["earned_memory_ids"] = [FLOW_MEMORY_ID]
	kite["selected_adaptation_id"] = ANCHOR_ADAPTATION_ID
	var mica := _individual(CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, SECOND_SPECIES_ID, "Mica")
	mica["earned_memory_ids"] = ["followed_the_bloom"]
	mica["selected_adaptation_id"] = "drift_lens"
	return {
		"schema_version": ExpansionProfileState.SCHEMA_VERSION,
		"completed_discoveries": [],
		"unlocked_capabilities": [],
		"material_inventory": {},
		"completed_projects": [],
		"banked_tool_target_ids": [],
		"companion_profile": {
			"schema_version": CompanionProfileState.COLLECTION_PROFILE_SCHEMA_VERSION,
			"individuals": [kite, mica],
			"active_individual_id": CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID,
		},
		"regional_journey_profile": SignalReefJourneyProfileState.new().payload(),
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
	for base_path in [PROFILE_PATH, LEGACY_PATH, COMPANION_V1_PATH, COMPANION_V2_PATH, ISOLATED_PATH]:
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
