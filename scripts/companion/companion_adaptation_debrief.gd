extends RefCounted

const OPTIONS := [
	{
		"species_id": "spark_ray",
		"adaptation_id": "anchor_fins",
		"memory_id": "held_the_flow",
		"adaptation_label": "Anchor Fins",
		"memory_label": "Held the Flow - crossed Signal Reef current together",
		"visible_change": "Broader fin tips; low brace beside diver or while mounted",
		"payoff": "Brace the downstream current; Propulsion Fins still required",
		"exclusive_label": "Guardian Pulse",
	},
	{
		"species_id": "spark_ray",
		"adaptation_id": "guardian_pulse",
		"memory_id": "stood_ground",
		"adaptation_label": "Guardian Pulse",
		"memory_label": "Stood Ground - endured a full territorial eel cycle together",
		"visible_change": "Charged wing arcs beside diver or under mounted control",
		"payoff": "Aim an interrupt/knockback pulse; Shock Prod still required",
		"exclusive_label": "Anchor Fins",
	},
	{
		"species_id": "veil_cuttle",
		"adaptation_id": "drift_lens",
		"memory_id": "followed_the_bloom",
		"adaptation_label": "Drift Lens",
		"memory_label": "Followed the Bloom - traced the Southwest Jellyfish Bloom together",
		"visible_change": "A lens shimmer follows Mica's gaze toward migrating wildlife",
		"payoff": "Read a jellyfish patrol's path and direction; the hazard remains active",
		"exclusive_label": "",
	},
]

var _profile
var _active := false
var _highlighted_index := 0


func bind_profile(profile) -> void:
	_profile = profile
	_highlighted_index = 0


func begin() -> void:
	_active = true
	_highlighted_index = 0


func end() -> void:
	_active = false
	_highlighted_index = 0


func handle_input(event: InputEvent) -> Dictionary:
	if not _active:
		return _result(false, false, "inactive")
	var repeated := event is InputEventKey and (event as InputEventKey).echo
	if event.is_action_pressed("companion_command") and not repeated:
		return _cycle()
	if event.is_action_pressed("active_tool_use") and not repeated:
		return _consolidate()
	return _result(false, false, "ignored")


func requires_selection() -> bool:
	return _selected_adaptation_id().is_empty() and not _eligible_options().is_empty()


func debrief_lines() -> Array[String]:
	var selected_id := _selected_adaptation_id()
	if not selected_id.is_empty():
		var selected := _option_by_adaptation(selected_id)
		if selected.is_empty():
			return []
		return [
			"%s adaptation: %s" % [_active_callsign(), selected["adaptation_label"]],
			"Memory consolidated | %s" % selected["payoff"],
		]
	var eligible := _eligible_options()
	if eligible.is_empty():
		return []
	var option: Dictionary = eligible[clampi(_highlighted_index, 0, eligible.size() - 1)]
	var lines: Array[String] = [
		"%s adaptation %d/%d" % [_active_callsign(), _highlighted_index + 1, eligible.size()],
		"Memory: %s" % option["memory_label"],
		"Choice: %s" % option["adaptation_label"],
		"Visible: %s" % option["visible_change"],
		"Payoff: %s" % option["payoff"],
	]
	var exclusive_label := str(option.get("exclusive_label", ""))
	if not exclusive_label.is_empty():
		lines.append("Exclusive with %s" % exclusive_label)
	lines.append("B: Choose | Space/USE: Consolidate")
	return lines


func report() -> Dictionary:
	var eligible := _eligible_options()
	var highlighted_id := ""
	if not eligible.is_empty():
		highlighted_id = str(eligible[clampi(_highlighted_index, 0, eligible.size() - 1)].get("adaptation_id", ""))
	return {
		"active": _active,
		"eligible_adaptation_ids": eligible.map(func(option): return str(option.get("adaptation_id", ""))),
		"highlighted_adaptation_id": highlighted_id,
		"selected_adaptation_id": _selected_adaptation_id(),
		"requires_selection": requires_selection(),
	}


func _cycle() -> Dictionary:
	var eligible := _eligible_options()
	if eligible.is_empty():
		return _result(false, false, "no_earned_memory")
	_highlighted_index = (_highlighted_index + 1) % eligible.size()
	var option: Dictionary = eligible[_highlighted_index]
	return {
		"handled": true,
		"changed": true,
		"reason": "highlight_changed",
		"adaptation_id": str(option["adaptation_id"]),
		"note": "Night choice: %s" % option["adaptation_label"],
	}


func _consolidate() -> Dictionary:
	var eligible := _eligible_options()
	if eligible.is_empty():
		return _result(false, false, "no_earned_memory")
	if _profile == null or not _profile.has_method("select_companion_adaptation"):
		return _result(true, false, "profile_unavailable")
	var option: Dictionary = eligible[clampi(_highlighted_index, 0, eligible.size() - 1)]
	var adaptation_id := str(option["adaptation_id"])
	var selected: Dictionary = _profile.select_companion_adaptation(adaptation_id, true)
	var changed := bool(selected.get("changed", false))
	return {
		"handled": true,
		"changed": changed,
		"reason": str(selected.get("reason", "selection_failed")),
		"adaptation_id": adaptation_id,
		"note": (
			"%s consolidated | Begins next day" % option["adaptation_label"]
			if changed
			else "%s adaptation could not be saved" % _active_callsign()
		),
	}


func _eligible_options() -> Array:
	var individual := _active_individual()
	if individual.is_empty() or not str(individual.get("selected_adaptation_id", "")).is_empty():
		return []
	var earned: Array = individual.get("earned_memory_ids", [])
	var species_id := str(individual.get("species_id", ""))
	var eligible := []
	for option in OPTIONS:
		if str(option.get("species_id", "")) == species_id and earned.has(str(option["memory_id"])):
			eligible.append(option)
	return eligible


func _active_individual() -> Dictionary:
	if _profile == null or not _profile.has_method("companion_report"):
		return {}
	var companion: Dictionary = _profile.companion_report()
	var individual: Dictionary = companion.get("individual", {})
	if individual.is_empty() or str(companion.get("active_individual_id", "")) != str(individual.get("individual_id", "")):
		return {}
	return individual


func _selected_adaptation_id() -> String:
	return str(_active_individual().get("selected_adaptation_id", ""))


func _active_callsign() -> String:
	return str(_active_individual().get("callsign", "Companion"))


func _option_by_adaptation(adaptation_id: String) -> Dictionary:
	for option in OPTIONS:
		if str(option.get("adaptation_id", "")) == adaptation_id:
			return option
	return {}


func _result(handled: bool, changed: bool, reason: String) -> Dictionary:
	return {"handled": handled, "changed": changed, "reason": reason}
