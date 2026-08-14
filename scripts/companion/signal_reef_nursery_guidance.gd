extends RefCounted

const KITE_ID := "spark_ray_juvenile_01"
const ANCHOR_ADAPTATION_ID := "anchor_fins"
const GUARDIAN_ADAPTATION_ID := "guardian_pulse"
const ANCHOR_ACTION_ID := "anchor_brace"
const GUARDIAN_ACTION_ID := "guardian_pulse_action"
const LANDMARK_ID := "lower_right_signal_reef_landmark"
const DISCOVERY_ID := "lower_right_signal_reef_discovery"
const UNRESOLVED := "unresolved"
const SHELTERED_PENDING_RETURN := "sheltered_pending_return"
const COMMITTED_WAITING_NEXT_DAY := "committed_waiting_next_day"
const RESTORED := "restored"
const APPROACH_RADIUS_PX := 440.0


func evaluate(world, player, profile, sortie_runtime) -> Dictionary:
	if not _dependencies_valid(world, player, profile, sortie_runtime):
		return _result(false)
	var nursery_runtime = sortie_runtime.signal_reef_nursery_runtime()
	var nursery: Dictionary = nursery_runtime.report()
	if not bool(nursery.get("configured", false)):
		return _result(false)
	var state := str(nursery.get("state", UNRESOLVED))
	var at_boat := bool(world.is_inside_boat(player.global_position))
	if state == SHELTERED_PENDING_RETURN:
		return _result(true, "PARTNER: Filter skates sheltered | Return with Kite to the surface boat")
	if state == COMMITTED_WAITING_NEXT_DAY:
		return _result(true, "PARTNER: Signal Reef nursery secured | Press N at the boat for night" if at_boat else "PARTNER: Signal Reef nursery secured | Return after nightfall")
	if state == RESTORED:
		return _restored_text(world, player, at_boat)
	if state in ["anchor_active", "guardian_active"]:
		return _result(true, "PARTNER: Kite is guiding the filter skates into shelter")

	var companion: Dictionary = profile.companion_report()
	var active: Dictionary = companion.get("individual", {})
	var active_id := str(companion.get("active_individual_id", ""))
	var adaptation_id := str(active.get("selected_adaptation_id", ""))
	var near_reef := _near_reef(world, player.global_position, nursery)
	if active_id != KITE_ID:
		return _result(true, "PARTNER: This nursery needs adapted Kite | Mica and Marl cannot shelter it") if near_reef else _result(false)
	if adaptation_id not in [ANCHOR_ADAPTATION_ID, GUARDIAN_ADAPTATION_ID]:
		return _result(true, "PARTNER: Kite recognizes the nursery, but has no matching adaptation") if near_reef else _result(false)

	var action_id := ANCHOR_ACTION_ID if adaptation_id == ANCHOR_ADAPTATION_ID else GUARDIAN_ACTION_ID
	var context: Dictionary = nursery_runtime.context_for_action(action_id)
	if not context.is_empty():
		var denial := str(context.get("access_denial_reason", ""))
		if not denial.is_empty():
			return _result(true, _access_text(denial))
		return _result(
			true,
			"PARTNER: The school needs a stable lee | Press B/BOND | choose Brace Flow"
			if action_id == ANCHOR_ACTION_ID
			else "PARTNER: Jellyfish are displacing the school | Press B/BOND | choose Guardian Pulse"
		)
	if at_boat and _signal_reef_known(profile):
		return _result(true, "PARTNER LEAD: Filter skates are being pushed from Signal Reef | Return east with Kite")
	if near_reef:
		return _result(true, "PARTNER: Jellyfish pressure is pushing filter skates from the nursery | Follow the school")
	return _result(false)


func _restored_text(world, player, at_boat: bool) -> Dictionary:
	if at_boat:
		return _result(true, "PARTNER: Signal Reef remembers Kite | Revisit the occupied nursery")
	var landmark: Dictionary = world.get_marker_zone(LANDMARK_ID)
	return _result(true, "PARTNER: Seven filter skates now shelter here | Signal Reef remembers") if _inside_zone(landmark, player.global_position, world.tile_size, 96.0) else _result(false)


func _near_reef(world, position: Vector2, nursery: Dictionary) -> bool:
	var school_center: Vector2 = nursery.get("school_center", Vector2.ZERO)
	if school_center != Vector2.ZERO and position.distance_to(school_center) <= APPROACH_RADIUS_PX:
		return true
	return _inside_zone(world.get_marker_zone(LANDMARK_ID), position, world.tile_size, 160.0)


func _inside_zone(zone: Dictionary, position: Vector2, tile_size: int, margin: float) -> bool:
	if zone.is_empty():
		return false
	var rect := Rect2(
		Vector2(float(zone.get("x", 0)), float(zone.get("y", 0))) * tile_size,
		Vector2(float(zone.get("w", 0)), float(zone.get("h", 0))) * tile_size
	)
	return rect.grow(margin).has_point(position)


func _access_text(reason: String) -> String:
	return "PARTNER: Signal Reef nursery requires Dive Light" if reason == "need_dive_light" else "PARTNER: Signal Reef nursery requires Propulsion Fins" if reason == "need_propulsion_fins" else "PARTNER: Signal Reef nursery access is incomplete"


func _signal_reef_known(profile) -> bool:
	return profile.has_method("has_completed_discovery") and bool(profile.has_completed_discovery(DISCOVERY_ID))


func _dependencies_valid(world, player, profile, sortie_runtime) -> bool:
	return (
		world != null
		and player != null
		and profile != null
		and profile.has_method("companion_report")
		and sortie_runtime != null
		and sortie_runtime.has_method("signal_reef_nursery_runtime")
		and world.has_method("get_marker_zone")
		and world.has_method("is_inside_boat")
	)


func _result(handled: bool, text := "") -> Dictionary:
	return {"handled": handled, "text": text}
