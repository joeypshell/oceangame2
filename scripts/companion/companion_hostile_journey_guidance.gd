extends RefCounted

const RELATIONSHIP_ID := "deep_cache_eel_companion_response"
const HOSTILE_ID := "deep_cache_territorial_eel"
const KITE_ID := "spark_ray_juvenile_01"
const GUARDIAN_PULSE := "guardian_pulse"


func boat_choice_text(world, profile_report: Dictionary) -> String:
	var relationship := _relationship(world)
	if relationship.is_empty():
		return ""
	var individuals: Array = profile_report.get("individuals", [])
	if not _has_ready_individual(individuals, relationship, KITE_ID, GUARDIAN_PULSE):
		return ""
	return "PARTNERS: Deep Cache Eel | BOND opens habitat | TOOL picks Kite for Guardian Pulse | USE confirms"


func active_text(world, individual: Dictionary, sortie_report: Dictionary) -> String:
	var relationship := _relationship(world)
	var response := _matching_response(relationship, individual)
	if response.is_empty():
		return ""
	return _kite_text(sortie_report) if str(individual.get("individual_id", "")) == KITE_ID else ""


func _kite_text(sortie_report: Dictionary) -> String:
	var presentation: Dictionary = sortie_report.get("presentation", {})
	if bool(presentation.get("guardian_opening", false)):
		return "PARTNER: Kite made a %.1fs opening | Pass, retreat, or attempt cache | No damage" % float(presentation.get("guardian_opening_seconds", 0.0))
	var control: Dictionary = sortie_report.get("control", {})
	if bool(control.get("mounted", false)):
		return "PARTNER: Riding Kite | Tab/TOOL Guardian Pulse | Space/USE during WARNING/LUNGE | No damage"
	return "PARTNER: Kite can open the Deep Cache Eel | B, then 3 during WARNING/LUNGE | No damage"


func _relationship(world) -> Dictionary:
	if world == null or not world.has_method("get_companion_hostile_responses"):
		return {}
	for value in world.get_companion_hostile_responses():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var relationship := value as Dictionary
		if (
			str(relationship.get("id", "")) == RELATIONSHIP_ID
			and str(relationship.get("hostile_id", "")) == HOSTILE_ID
		):
			return relationship.duplicate(true)
	return {}


func _has_ready_individual(
	individuals: Array,
	relationship: Dictionary,
	individual_id: String,
	adaptation_id: String
) -> bool:
	for value in individuals:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var individual := value as Dictionary
		if (
			str(individual.get("individual_id", "")) == individual_id
			and str(individual.get("selected_adaptation_id", "")) == adaptation_id
			and not _matching_response(relationship, individual).is_empty()
		):
			return true
	return false


func _matching_response(relationship: Dictionary, individual: Dictionary) -> Dictionary:
	if relationship.is_empty():
		return {}
	for value in relationship.get("responses", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var response := value as Dictionary
		if (
			str(response.get("individual_id", "")) == str(individual.get("individual_id", ""))
			and str(response.get("species_id", "")) == str(individual.get("species_id", ""))
			and str(response.get("required_adaptation_id", "")) == str(individual.get("selected_adaptation_id", ""))
		):
			return response.duplicate(true)
	return {}
