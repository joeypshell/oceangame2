extends RefCounted

const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")


static func run() -> Dictionary:
	var failures: Array[String] = []
	var empty := CompanionProfileState.new()
	_expect(empty.individuals().is_empty(), "empty profile invented a companion", failures)

	var v1 := CompanionProfileState.new()
	var v1_failures: Array[String] = v1.load_payload({
		"schema_version": CompanionProfileState.LEGACY_PROFILE_SCHEMA_VERSION,
		"individual": _individual(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "Kite"),
		"active_individual_id": "",
	})
	_expect(v1_failures.is_empty(), "schema v1 migration failed: %s" % [v1_failures], failures)
	_expect(v1.individuals().size() == 1 and not _has_marl(v1.individuals()), "schema v1 migration invented Marl", failures)

	var v2 := CompanionProfileState.new()
	var v2_failures: Array[String] = v2.load_payload({
		"schema_version": CompanionProfileState.COLLECTION_PROFILE_SCHEMA_VERSION,
		"individuals": [
			_individual(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "Kite"),
			_individual(CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, "veil_cuttle", "Mica"),
		],
		"active_individual_id": CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID,
	})
	_expect(v2_failures.is_empty(), "schema v2 migration failed: %s" % [v2_failures], failures)
	_expect(v2.individuals().size() == 2 and not _has_marl(v2.individuals()), "schema v2 migration invented Marl", failures)
	_expect(v2.payload().get("schema_version") == CompanionProfileState.PROFILE_SCHEMA_VERSION, "schema v2 migration did not reach v3", failures)
	return {
		"ready": failures.is_empty(),
		"failures": failures,
		"profile_schema": CompanionProfileState.PROFILE_SCHEMA_VERSION,
		"migrations": ["empty", "v1", "v2"],
		"silent_marl_commit": false,
	}


static func _individual(individual_id: String, species_id: String, callsign: String) -> Dictionary:
	return {
		"individual_id": individual_id,
		"species_id": species_id,
		"callsign": callsign,
		"rescue_committed": true,
		"earned_memory_ids": [],
		"selected_adaptation_id": "",
	}


static func _has_marl(individuals: Array) -> bool:
	return individuals.any(func(value): return str((value as Dictionary).get("individual_id", "")) == CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID)


static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
