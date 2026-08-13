extends RefCounted

const PROFILE_SCHEMA_VERSION := 1
const JOURNEY_ID := "signal_reef_nursery_journey_01"
const COMMITMENT_EVENT_ID := "signal_reef_nursery_commit_01"
const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const MAP_ID := "production_level_01"
const COMMIT_ENTRY_ID := "surface_boat_entry"
const ADAPTATION_IDS := ["anchor_fins", "guardian_pulse"]
const PROFILE_KEYS := {
	"schema_version": true,
	"journey_id": true,
	"commitment_event_id": true,
	"individual_id": true,
	"adaptation_id": true,
	"committed": true,
	"committed_day_number": true,
	"restored": true,
	"restoration_day_number": true,
}

var _adaptation_id := ""
var _committed := false
var _committed_day_number := 0
var _restored := false
var _restoration_day_number := 0


func reset() -> void:
	_adaptation_id = ""
	_committed = false
	_committed_day_number = 0
	_restored = false
	_restoration_day_number = 0


func load_payload(value: Dictionary) -> Array[String]:
	var failures := validate_payload(value)
	if not failures.is_empty():
		return failures
	_adaptation_id = str(value["adaptation_id"])
	_committed = bool(value["committed"])
	_committed_day_number = int(value["committed_day_number"])
	_restored = bool(value["restored"])
	_restoration_day_number = int(value["restoration_day_number"])
	return []


func payload() -> Dictionary:
	return {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"journey_id": JOURNEY_ID,
		"commitment_event_id": COMMITMENT_EVENT_ID,
		"individual_id": INDIVIDUAL_ID,
		"adaptation_id": _adaptation_id,
		"committed": _committed,
		"committed_day_number": _committed_day_number,
		"restored": _restored,
		"restoration_day_number": _restoration_day_number,
	}


func report() -> Dictionary:
	var value := payload()
	value["state"] = (
		"restored" if _restored
		else "committed_waiting_next_day" if _committed
		else "unresolved"
	)
	return value


func commit(
	journey_id: String,
	commitment_event_id: String,
	individual_id: String,
	adaptation_id: String,
	map_id: String,
	entry_id: String,
	day_number: int
) -> Dictionary:
	if journey_id != JOURNEY_ID or commitment_event_id != COMMITMENT_EVENT_ID:
		return _result(false, "unsupported_journey")
	if individual_id != INDIVIDUAL_ID:
		return _result(false, "individual_mismatch")
	if not ADAPTATION_IDS.has(adaptation_id):
		return _result(false, "unsupported_adaptation")
	if map_id != MAP_ID or entry_id != COMMIT_ENTRY_ID:
		return _result(false, "wrong_commit_location")
	if day_number <= 0:
		return _result(false, "invalid_day_number")
	if _committed:
		return _result(false, "already_committed")
	_adaptation_id = adaptation_id
	_committed = true
	_committed_day_number = day_number
	return _result(true, "committed")


func advance_day(day_number: int) -> Dictionary:
	if not _committed:
		return _result(false, "not_committed")
	if _restored:
		return _result(false, "already_restored")
	if day_number <= _committed_day_number:
		return _result(false, "waiting_next_day")
	_restored = true
	_restoration_day_number = day_number
	return _result(true, "restored")


func validate_payload(value: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	for required_key in PROFILE_KEYS:
		if not value.has(required_key):
			failures.append("regional_journey_profile missing %s" % required_key)
	for key in value:
		if not PROFILE_KEYS.has(str(key)):
			failures.append("regional_journey_profile contains unsupported field %s" % key)
	if int(value.get("schema_version", 0)) != PROFILE_SCHEMA_VERSION:
		failures.append("regional_journey_profile schema_version must be %d" % PROFILE_SCHEMA_VERSION)
	for field in {
		"journey_id": JOURNEY_ID,
		"commitment_event_id": COMMITMENT_EVENT_ID,
		"individual_id": INDIVIDUAL_ID,
	}:
		if value.get(field) != field_value(field):
			failures.append("regional_journey_profile %s must be %s" % [field, field_value(field)])
	var adaptation = value.get("adaptation_id")
	if typeof(adaptation) != TYPE_STRING or (not str(adaptation).is_empty() and not ADAPTATION_IDS.has(str(adaptation))):
		failures.append("regional_journey_profile adaptation_id is unsupported")
	if typeof(value.get("committed")) != TYPE_BOOL:
		failures.append("regional_journey_profile committed must be a boolean")
	if typeof(value.get("restored")) != TYPE_BOOL:
		failures.append("regional_journey_profile restored must be a boolean")
	var committed_day: Variant = value.get("committed_day_number")
	var restoration_day: Variant = value.get("restoration_day_number")
	var committed_day_valid := _nonnegative_integer(committed_day)
	var restoration_day_valid := _nonnegative_integer(restoration_day)
	if not committed_day_valid:
		failures.append("regional_journey_profile committed_day_number must be a non-negative integer")
	if not restoration_day_valid:
		failures.append("regional_journey_profile restoration_day_number must be a non-negative integer")
	var committed_day_number := int(committed_day) if committed_day_valid else 0
	var restoration_day_number := int(restoration_day) if restoration_day_valid else 0
	var committed := bool(value.get("committed", false))
	var restored := bool(value.get("restored", false))
	if not committed and (not str(adaptation).is_empty() or committed_day_number != 0 or restored or restoration_day_number != 0):
		failures.append("regional_journey_profile uncommitted state must be empty")
	if committed and (not ADAPTATION_IDS.has(str(adaptation)) or committed_day_number <= 0):
		failures.append("regional_journey_profile committed state requires adaptation and day")
	if restored and (not committed or restoration_day_number <= committed_day_number):
		failures.append("regional_journey_profile restoration must occur after commitment")
	if not restored and restoration_day_number != 0:
		failures.append("regional_journey_profile unrestored state cannot have restoration day")
	return failures


func validate_companion_reference(value: Dictionary, companion_payload: Dictionary) -> Array[String]:
	if not bool(value.get("committed", false)):
		return []
	var individuals = companion_payload.get("individuals")
	if typeof(individuals) != TYPE_ARRAY:
		return []
	for item in individuals:
		if typeof(item) != TYPE_DICTIONARY or str(item.get("individual_id", "")) != INDIVIDUAL_ID:
			continue
		if str(item.get("selected_adaptation_id", "")) != str(value.get("adaptation_id", "")):
			return ["regional_journey_profile adaptation must match committed Kite"]
		return []
	return ["regional_journey_profile requires committed Kite"]


func field_value(field: String) -> String:
	match field:
		"journey_id": return JOURNEY_ID
		"commitment_event_id": return COMMITMENT_EVENT_ID
		"individual_id": return INDIVIDUAL_ID
	return ""


func _nonnegative_integer(value) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return float(value) >= 0.0 and is_equal_approx(float(value), float(int(value)))


func _result(changed: bool, reason: String) -> Dictionary:
	var value := report()
	value["changed"] = changed
	value["reason"] = reason
	return value
