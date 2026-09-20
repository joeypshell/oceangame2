extends RefCounted

const RESCUE_ID := "silt_hound_rescue_01"
const MARL_ID := "silt_hound_juvenile_01"
const TARGET_ID := "silt_hound_buried_titanium_01"
const SPECIES_ID := "silt_hound"
const ACTION_RADIUS_PX := 112.0
const RESCUE_GUIDANCE_RADIUS_PX := 192.0


func evaluate(world, player, profile, sortie_runtime) -> Dictionary:
	if not _dependencies_valid(world, player, profile, sortie_runtime):
		return _result(false)
	var rescue := _rescue(world)
	var source: Dictionary = world.get_material_candidate_state(TARGET_ID) if world.has_method("get_material_candidate_state") else {}
	if rescue.is_empty() and not bool(source.get("exists", false)):
		return _result(false)
	var companion_profile: Dictionary = profile.companion_report()
	var marl := _marl_record(companion_profile)
	if marl.is_empty():
		return _result(false) if rescue.is_empty() else _uncommitted_text(rescue, player)
	var growth := _growth_text(world, player, marl, companion_profile, sortie_runtime)
	if not growth.is_empty():
		return _result(true, growth)
	return _committed_text(world, player, companion_profile, sortie_runtime, source)


func _growth_text(world, player, marl: Dictionary, profile: Dictionary, sortie) -> String:
	if str(profile.get("active_individual_id", "")) != MARL_ID:
		return ""
	var control: Dictionary = sortie.report().get("control", {})
	var refuge: Dictionary = control.get("refuge", {})
	if not (refuge.get("pending", {}) as Dictionary).is_empty():
		return "PARTNER: Marl sheltered the scallops | Return together to the surface boat to secure Guarded the Nest"
	var learned := str(marl.get("selected_adaptation_id", "")) == "root_claws"
	var secured := (marl.get("earned_memory_ids", []) as Array).has("guarded_the_nest")
	if secured and not learned:
		return "PARTNER: Guarded the Nest secured | At the boat, end the day to choose Root Claws or Not tonight"
	if world.is_inside_boat(player.global_position) and learned:
		return "PARTNER: Marl has Root Claws | Revisit the deep-cache floor; draw the eel low for Ground Pin"
	var visual = world.burrow_refuge_presentation() if world.has_method("burrow_refuge_presentation") else null
	if not is_instance_valid(visual) or player.global_position.distance_to(visual.target) > 192.0:
		return ""
	if learned:
		var pin: Dictionary = control.get("ground_pin", {})
		match str(pin.get("state", "idle")):
			"approaching": return "PARTNER: Marl is approaching the floor anchor | Stay close and dodge the eel"
			"holding": return "PARTNER: Marl is gripping the eel | Strike with Shock Prod or swim clear"
		if float(pin.get("cooldown_seconds", 0)) > 0:
			return "PARTNER: Marl released the eel | Ground Pin recovering %.1fs" % float(pin["cooldown_seconds"])
		for command in control.get("context_commands", []):
			if command.get("id") == "ground_pin":
				return "PARTNER: Ground Pin on the deep-cache eel | " + ("BOND > Ground Pin, then dodge aside" if command.get("enabled", false) else str(command.get("denial", "")))
	var dig: Dictionary = control.get("excavate", {})
	if bool(refuge.get("attempt_active", false)):
		return "PARTNER: Marl is opening the scallop refuge | Dodge the eel and stay beside the group"
	if bool(refuge.get("group", {}).get("opened", false)):
		return "PARTNER: Scallops sheltered | A quiet rescue gives no threat memory; try another day"
	if not bool(dig.get("busy", false)):
		for command in control.get("context_commands", []):
			if command.get("id") == "excavate" and command.get("target_id") == "deep_cache_burrow_refuge_01":
				if command.get("enabled", false) and not refuge.get("group", {}).get("threatened", false):
					return "PARTNER: Protect the scallops | Approach the eel; when it warns, BOND > Excavate"
				return "PARTNER: Scallops need shelter from the eel | " + ("BOND > Excavate to clear their silt arch" if command.get("enabled", false) else str(command.get("denial", "")))
	return "PARTNER: Scallops wait beside the silt-blocked arch | Bring Marl close to clear their refuge"


func _uncommitted_text(rescue: Dictionary, player) -> Dictionary:
	match str(rescue.get("state", "available")):
		"releasing":
			return _result(true, "PARTNER: Hold USE to cut Marl free from the dredge cable")
		"pending":
			return _result(true, "PARTNER: Marl is free | Return together to the surface boat")
		"committed":
			return _result(false)
		_:
			var center: Vector2 = rescue.get("center", Vector2.ZERO)
			if player.global_position.distance_to(center) > RESCUE_GUIDANCE_RADIUS_PX:
				return _result(false)
			return _result(true, "PARTNER LEAD: Lower-loop dredge cable traps a juvenile Silt Hound | bring Cutter")


func _committed_text(world, player, companion_profile: Dictionary, sortie_runtime, source: Dictionary) -> Dictionary:
	var at_boat := bool(world.is_inside_boat(player.global_position))
	var active_id := str(companion_profile.get("active_individual_id", ""))
	var depleted := bool(source.get("depleted", false))
	if active_id != MARL_ID:
		if depleted:
			return _result(false)
		return _result(true, "PARTNER: Marl bonded | BOND opens habitat | TOOL choose Marl | USE confirms") if at_boat else _result(false)
	var companion = sortie_runtime.companion()
	if companion == null or not is_instance_valid(companion) or str(companion.report().get("species_id", "")) != SPECIES_ID:
		return _result(
			true,
			"PARTNER: Marl selected | Leave the boat to begin the excavation dive"
			if at_boat
			else "PARTNER: Finish this sortie | Marl joins the next dive"
		)
	var control_report: Dictionary = sortie_runtime.report().get("control", {})
	var excavate: Dictionary = control_report.get("excavate", {})
	if bool(excavate.get("busy", false)):
		return _result(true, _action_text(str(excavate.get("state", "digging"))))
	if bool(source.get("revealed", false)):
		return _result(true, "PARTNER: Deposit opened | Collect the exposed titanium")
	if depleted:
		return _result(true, "" if at_boat else "PARTNER: Excavated titanium secured | Return to the surface boat to bank it")
	if not bool(source.get("active", false)):
		return _result(true, "")
	var target: Vector2 = source.get("candidate", {}).get("center", Vector2.ZERO)
	if player.global_position.distance_to(target) <= ACTION_RADIUS_PX:
		return _result(true, "PARTNER: Marl senses the buried mound | Press B, then 2: Excavate")
	return _result(true, "PARTNER: Revisit the visible lower-loop mound with Marl")


func _action_text(state: String) -> String:
	match state:
		"approaching":
			return "PARTNER: Marl is approaching the buried mound"
		"anticipating":
			return "PARTNER: Marl braces over the buried deposit"
		"impact":
			return "PARTNER: Marl breaks open the deposit"
		_:
			return "PARTNER: Marl is excavating the buried deposit"


func _rescue(world) -> Dictionary:
	if not world.has_method("get_creature_rescues"):
		return {}
	for value in world.get_creature_rescues():
		if str((value as Dictionary).get("id", "")) == RESCUE_ID:
			return (value as Dictionary).duplicate(true)
	return {}


func _marl_record(companion_profile: Dictionary) -> Dictionary:
	for value in companion_profile.get("individuals", []):
		if value is Dictionary and str(value.get("individual_id", "")) == MARL_ID:
			return (value as Dictionary).duplicate(true)
	return {}


func _result(handled: bool, text := "") -> Dictionary:
	return {"handled": handled, "text": text}


func _dependencies_valid(world, player, profile, sortie_runtime) -> bool:
	return (
		world != null
		and player != null
		and profile != null
		and profile.has_method("companion_report")
		and sortie_runtime != null
		and sortie_runtime.has_method("companion")
		and sortie_runtime.has_method("report")
		and world.has_method("is_inside_boat")
	)
