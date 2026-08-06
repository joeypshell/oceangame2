extends RefCounted

const ACTIVE_PHASE := "active"
const ANCHOR_FINS := "anchor_fins"
const GUARDIAN_PULSE := "guardian_pulse"
const VEIL_CUTTLE := "veil_cuttle"
const VEIL_CUTTLE_TRACE_ID := "veil_cuttle_trace_01"


func objective_text(world, player, profile, sortie_runtime, day_state) -> String:
	if not _dependencies_valid(world, player, profile, sortie_runtime, day_state):
		return ""
	if str(day_state.phase) != ACTIVE_PHASE:
		return ""

	var profile_report: Dictionary = profile.companion_report()
	if not bool(profile_report.get("rescue_committed", false)):
		return ""
	var individual: Dictionary = profile_report.get("individual", {})
	if individual.is_empty():
		return "PARTNERS: Hold Shift/BOND at the boat to select the next companion" if world.is_inside_boat(player.global_position) else "PARTNERS: Return to the surface boat to select a companion"
	var callsign := str(individual.get("callsign", "Kite"))
	var species_id := str(individual.get("species_id", "spark_ray"))
	var at_boat := bool(world.is_inside_boat(player.global_position))
	var memory_report: Dictionary = sortie_runtime.memory_report()
	var pending_memory_ids: Array = memory_report.get("pending_memory_ids", [])
	var earned_memory_ids: Array = individual.get("earned_memory_ids", [])
	var adaptation_id := str(individual.get("selected_adaptation_id", ""))

	if species_id != VEIL_CUTTLE and not pending_memory_ids.is_empty():
		return "PARTNER: %s formed a memory | Return together to the surface boat" % callsign
	if species_id != VEIL_CUTTLE and adaptation_id.is_empty() and not earned_memory_ids.is_empty():
		if at_boat:
			return "PARTNER: Memory secured | Press N at the boat | choose %s's adaptation tonight" % callsign
		return "PARTNER: Memory secured | Return to the boat, then press N for night"

	var companion = sortie_runtime.companion()
	if companion == null or not is_instance_valid(companion):
		if not at_boat:
			return "PARTNER: Return to the surface boat to begin a new dive with %s" % callsign
		if (profile_report.get("individuals", []) as Array).size() > 1:
			return "PARTNERS: BOND opens habitat | Tab/TOOL chooses the next partner | Space/USE confirms"
		if int(day_state.sortie_count) > 0:
			return "PARTNER: %s bonded | Press N at the boat to end the day | %s joins next dive" % [callsign, callsign]
		return "PARTNER: %s is bonded | Leave the boat to begin a dive together" % callsign

	var control = sortie_runtime.control_runtime()
	var control_report: Dictionary = control.report() if control != null else {}
	if bool(control_report.get("command_mode", false)):
		return "PARTNER: BOND open | Tab/TOOL selects a command | Space/USE confirms"
	if bool(control_report.get("mounted", false)):
		return _mounted_text(callsign, adaptation_id)
	if species_id == VEIL_CUTTLE:
		return _veil_cuttle_text(world, callsign)
	return _independent_text(callsign, adaptation_id)


func _independent_text(callsign: String, adaptation_id: String) -> String:
	if adaptation_id == ANCHOR_FINS:
		return "PARTNER: Anchor Fins ready | Hold Shift/BOND to Brace Flow or Mount | test the lower-right current"
	if adaptation_id == GUARDIAN_PULSE:
		return "PARTNER: Guardian Pulse ready | Hold Shift/BOND to Pulse or Mount | face the deep-cache eel"
	return "PARTNER: %s is following | Move close, hold Shift/BOND | Tab selects Mount | Space/USE confirms" % callsign


func _mounted_text(callsign: String, adaptation_id: String) -> String:
	if adaptation_id == ANCHOR_FINS:
		return "PARTNER: Riding %s | Tab/TOOL selects Brace Flow | Space/USE at the lower-right current" % callsign
	if adaptation_id == GUARDIAN_PULSE:
		return "PARTNER: Riding %s | Tab/TOOL selects Guardian Pulse | Space/USE near the deep-cache eel" % callsign
	return "PARTNER: Riding %s | Tab/TOOL selects Glide Surge | Space/USE activates | seek lower-right current or eel" % callsign


func _veil_cuttle_text(world, callsign: String) -> String:
	var trace_state := _ecological_trace_state(world)
	if trace_state == "identified":
		return "PARTNER: %s's optional ecological trace is identified | No cargo or access reward" % callsign
	if trace_state == "revealed":
		return "PARTNER: %s revealed a trace | Tab Scanner | Hold Space/USE to identify it" % callsign
	if trace_state == "hidden":
		return "PARTNER: %s senses a concealed trace | Stay close, hold Shift/BOND | Tab Reveal Trace | Space/USE" % callsign
	return "PARTNER: %s is investigating nearby water | Hold Shift/BOND for Recall or Reveal Trace" % callsign


func _ecological_trace_state(world) -> String:
	if world == null or not world.has_method("get_ecological_traces"):
		return ""
	for trace in world.get_ecological_traces():
		if str(trace.get("id", "")) == VEIL_CUTTLE_TRACE_ID:
			return str(trace.get("state", "hidden"))
	return ""


func _dependencies_valid(world, player, profile, sortie_runtime, day_state) -> bool:
	return (
		world != null
		and player != null
		and profile != null
		and profile.has_method("companion_report")
		and sortie_runtime != null
		and sortie_runtime.has_method("memory_report")
		and sortie_runtime.has_method("companion")
		and day_state != null
		and world.has_method("is_inside_boat")
	)
