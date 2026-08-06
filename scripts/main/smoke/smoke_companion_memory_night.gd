extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const CompanionAdaptationDebrief := preload("res://scripts/companion/companion_adaptation_debrief.gd")
const CompanionMemoryRuntime := preload("res://scripts/companion/companion_memory_runtime.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://oceangame2_companion_memory_night_smoke.json"
const FLOW_MEMORY_ID := "held_the_flow"
const GROUND_MEMORY_ID := "stood_ground"
const ANCHOR_ADAPTATION_ID := "anchor_fins"
const GUARDIAN_ADAPTATION_ID := "guardian_pulse"
const CURRENT_GATE_ID := "lower_right_west_current_gate"
const HOSTILE_ID := "deep_cache_territorial_eel"

var _failures: Array[String] = []
var _access_allowed := true


class HostileFixture:
	extends RefCounted
	var state := {}

	func state_for(_hostile_id: String) -> Dictionary:
		return state.duplicate(true)


class DayFixture:
	extends RefCounted
	var phase := "debrief"


class RequiredAdaptationFixture:
	extends RefCounted

	func requires_adaptation_selection() -> bool:
		return true


class DebriefMainFixture:
	extends RefCounted
	var _expedition_day_state := DayFixture.new()
	var _wreck_network_investigation = null
	var _companion_sortie := RequiredAdaptationFixture.new()
	var _last_status_note := ""
	var status_refresh_count := 0

	func _update_status_label() -> void:
		status_refresh_count += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame
	var opportunities: Array = world.get_creature_memory_opportunities()
	var opportunity_ids: Array[String] = []
	for opportunity in opportunities:
		opportunity_ids.append(str((opportunity as Dictionary).get("id", "")))
	_expect(
		opportunity_ids.has("spark_ray_current_memory_01")
		and opportunity_ids.has("spark_ray_eel_memory_01"),
		"full level did not preserve both source-authored Spark Ray memory opportunities"
	)

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var rescue: Dictionary = profile.commit_companion_rescue(
		CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID,
		"spark_ray",
		"Kite",
		true
	)
	_expect(bool(rescue.get("changed", false)), "could not create committed Spark Ray fixture")
	var memory := CompanionMemoryRuntime.new()
	memory.bind_map(world, profile, Callable(self, "_has_access"), Callable(), false)

	_test_current_memory(world, profile, memory)
	_test_territorial_memory(profile, memory)
	_test_night_choice(profile)

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload: Dictionary = reloaded.load_profile()
	var individual: Dictionary = reloaded.companion_report().get("individual", {})
	_expect(reload.get("status") == "loaded", "profile reload failed after night consolidation")
	_expect((individual.get("earned_memory_ids", []) as Array).has(FLOW_MEMORY_ID), "reload lost Held the Flow")
	_expect((individual.get("earned_memory_ids", []) as Array).has(GROUND_MEMORY_ID), "reload lost Stood Ground")
	_expect(individual.get("selected_adaptation_id") == GUARDIAN_ADAPTATION_ID, "reload lost the deliberate Guardian Pulse choice")

	world.queue_free()
	_cleanup()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Companion memory/night smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"Companion memory/night smoke passed: source_opportunities=%d current_independent=true current_mounted=true territorial_independent=true territorial_mounted=true trivial_actions_blocked=true failure_reload_rollback=true canonical_boat_commit=true night_earned_only=true adaptation=%s mutual_exclusion=true profile_reload=true." % [opportunities.size(), GUARDIAN_ADAPTATION_ID]
	)
	quit(0)


func _test_current_memory(world, profile, memory) -> void:
	var gate := _gate_by_id(world, CURRENT_GATE_ID)
	_expect(not gate.is_empty(), "missing authored current memory target")
	if gate.is_empty():
		return
	var independent := _context("independent")
	var mounted := _context("mounted")

	_run_current_crossing(world, memory, gate, independent, false)
	_expect(memory.report().get("pending_memory_ids", []).is_empty(), "same-side current exit qualified a memory")
	_access_allowed = false
	_run_current_crossing(world, memory, gate, independent, true)
	_expect(memory.report().get("pending_memory_ids", []).is_empty(), "current memory bypassed Propulsion Fins access")
	_access_allowed = true

	var independent_result := _run_current_crossing(world, memory, gate, independent, true)
	_expect(independent_result.get("memory_id") == FLOW_MEMORY_ID and independent_result.get("mode") == "independent", "independent current completion did not qualify Held the Flow")
	memory.bind_map(world, profile, Callable(self, "_has_access"), Callable(), false)
	_expect(memory.report().get("pending_memory_ids", []).is_empty() and not _earned(profile).has(FLOW_MEMORY_ID), "checkpoint reload retained uncommitted current memory")
	_run_current_crossing(world, memory, gate, independent, true)
	var retry: Dictionary = memory.discard_uncommitted("retry")
	_expect(bool(retry.get("changed", false)), "Retry did not discard pending current memory")
	_expect(not _earned(profile).has(FLOW_MEMORY_ID), "uncommitted current memory leaked into profile")

	var mounted_result := _run_current_crossing(world, memory, gate, mounted, true)
	_expect(mounted_result.get("memory_id") == FLOW_MEMORY_ID and mounted_result.get("mode") == "mounted", "mounted current completion did not qualify Held the Flow")
	memory.bind_map(world, profile, Callable(self, "_has_access"), Callable(), true)
	_expect(memory.report().get("pending_memory_ids", []).has(FLOW_MEMORY_ID), "continuous map bind discarded pending memory")
	var off_boat: Dictionary = memory.commit_at_boat(false)
	_expect(off_boat.get("reason") == "canonical_boat_required" and not _earned(profile).has(FLOW_MEMORY_ID), "memory committed away from canonical boat")
	var commit: Dictionary = memory.commit_at_boat(true)
	_expect(bool(commit.get("changed", false)) and _earned(profile).has(FLOW_MEMORY_ID), "canonical boat did not commit Held the Flow")
	var duplicate := _run_current_crossing(world, memory, gate, mounted, true)
	_expect(not bool(duplicate.get("changed", false)) and memory.report().get("pending_memory_ids", []).is_empty(), "duplicate current exposure farmed memory")


func _test_territorial_memory(profile, memory) -> void:
	var hostiles := HostileFixture.new()
	var player_position := Vector2(100.0, 100.0)
	var territory := Rect2(Vector2.ZERO, Vector2(200.0, 200.0))
	var independent := _context("independent")
	var mounted := _context("mounted")

	hostiles.state = _hostile_state("warning", territory)
	memory.observe_hostiles(hostiles, _hostile_event("warning"), player_position, independent)
	hostiles.state = _hostile_state("returning", territory)
	memory.observe_hostiles(hostiles, _hostile_event("retreat"), player_position, independent)
	_expect(memory.report().get("pending_memory_ids", []).is_empty(), "warning then retreat qualified Stood Ground")

	var independent_result := _run_hostile_cycle(memory, hostiles, territory, player_position, independent, false)
	_expect(independent_result.get("memory_id") == GROUND_MEMORY_ID and independent_result.get("mode") == "independent", "independent threat cycle did not qualify Stood Ground")
	var discarded: Dictionary = memory.discard_uncommitted("oxygen_failure")
	_expect(bool(discarded.get("changed", false)) and not _earned(profile).has(GROUND_MEMORY_ID), "oxygen failure did not discard pending territorial memory")

	var mounted_result := _run_hostile_cycle(memory, hostiles, territory, player_position, mounted, true)
	_expect(mounted_result.get("memory_id") == GROUND_MEMORY_ID and mounted_result.get("mode") == "mounted", "mounted threat cycle did not qualify Stood Ground")
	var commit: Dictionary = memory.commit_at_boat(true)
	_expect(bool(commit.get("changed", false)) and _earned(profile).has(GROUND_MEMORY_ID), "canonical boat did not commit Stood Ground")
	var duplicate := _run_hostile_cycle(memory, hostiles, territory, player_position, mounted, true)
	_expect(not bool(duplicate.get("changed", false)) and memory.report().get("pending_memory_ids", []).is_empty(), "duplicate eel cycle farmed memory")


func _test_night_choice(profile) -> void:
	var debrief := CompanionAdaptationDebrief.new()
	debrief.bind_profile(profile)
	debrief.begin()
	var initial: Dictionary = debrief.report()
	_expect(initial.get("eligible_adaptation_ids", []) == [ANCHOR_ADAPTATION_ID, GUARDIAN_ADAPTATION_ID], "night offered an option not backed by earned memories or omitted an earned option")
	_expect(str(initial.get("selected_adaptation_id", "")).is_empty() and debrief.requires_selection(), "night automatically selected an adaptation")
	var gate_main := DebriefMainFixture.new()
	var day_gate: Dictionary = ExpeditionDayDebrief.handle_day_key(gate_main)
	_expect(day_gate.get("reason") == "companion_adaptation_required" and gate_main.status_refresh_count == 1, "next day started before deliberate adaptation selection")
	var lines := "\n".join(debrief.debrief_lines())
	_expect(lines.find("Held the Flow") != -1 and lines.find("Anchor Fins") != -1, "night option omitted remembered event or adaptation name")
	_expect(lines.find("beside diver or while mounted") != -1, "night option omitted independent/mounted visible change")
	_expect(lines.find("Propulsion Fins still required") != -1 and lines.find("Exclusive with Guardian Pulse") != -1, "night option omitted payoff or mutual exclusion")

	var cycle := InputEventAction.new()
	cycle.action = "companion_command"
	cycle.pressed = true
	var cycle_result: Dictionary = debrief.handle_input(cycle)
	_expect(cycle_result.get("adaptation_id") == GUARDIAN_ADAPTATION_ID, "BOND did not deliberately cycle the night choice")
	var guardian_lines := "\n".join(debrief.debrief_lines())
	_expect(guardian_lines.find("Stood Ground") != -1 and guardian_lines.find("Shock Prod still required") != -1, "Guardian Pulse option omitted event or equipment-protected payoff")

	var use := InputEventAction.new()
	use.action = "active_tool_use"
	use.pressed = true
	var selection: Dictionary = debrief.handle_input(use)
	_expect(bool(selection.get("changed", false)) and selection.get("adaptation_id") == GUARDIAN_ADAPTATION_ID, "Space/USE did not consolidate the highlighted adaptation")
	_expect(not debrief.requires_selection(), "night still required selection after consolidation")
	var second: Dictionary = profile.select_companion_adaptation(ANCHOR_ADAPTATION_ID, true)
	_expect(second.get("reason") == "adaptation_already_selected", "mutually exclusive adaptation replaced the night choice")

	var empty_profile := ExpansionProfileState.new("", false)
	empty_profile.load_profile()
	empty_profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "No Memory", true)
	var empty_debrief := CompanionAdaptationDebrief.new()
	empty_debrief.bind_profile(empty_profile)
	empty_debrief.begin()
	_expect(empty_debrief.debrief_lines().is_empty() and not empty_debrief.requires_selection(), "night offered an unearned adaptation")


func _run_current_crossing(world, memory, gate: Dictionary, context: Dictionary, opposite_exit: bool) -> Dictionary:
	memory.discard_uncommitted("fixture_reset")
	var rect: Rect2 = gate.get("rect", Rect2())
	var push := _direction_vector(str(gate.get("current_direction", "")))
	var half_span := rect.size.x * 0.5 if absf(push.x) > 0.0 else rect.size.y * 0.5
	var entry := rect.get_center() + push * (half_span + 12.0)
	var exit := rect.get_center() - push * (half_span + 12.0) if opposite_exit else entry
	memory.observe_current(null, entry, {}, context)
	memory.observe_current(world, rect.get_center(), {"inside": true, "blocked": false, "id": CURRENT_GATE_ID}, context)
	return memory.observe_current(null, exit, {}, context)


func _run_hostile_cycle(memory, hostiles, territory: Rect2, player_position: Vector2, context: Dictionary, contact_finish: bool) -> Dictionary:
	memory.discard_uncommitted("fixture_reset")
	hostiles.state = _hostile_state("warning", territory)
	memory.observe_hostiles(hostiles, _hostile_event("warning"), player_position, context)
	hostiles.state = _hostile_state("lunge", territory)
	memory.observe_hostiles(hostiles, _hostile_event("lunge"), player_position, context)
	if contact_finish:
		return memory.observe_hostiles(hostiles, _hostile_event("contact"), player_position, context)
	hostiles.state = _hostile_state("recovery", territory)
	return memory.observe_hostiles(hostiles, {}, player_position, context)


func _gate_by_id(world, gate_id: String) -> Dictionary:
	for gate in world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _hostile_state(phase: String, territory: Rect2) -> Dictionary:
	return {"id": HOSTILE_ID, "phase": phase, "territory_rect": territory}


func _hostile_event(kind: String) -> Dictionary:
	return {"id": HOSTILE_ID, "kind": kind}


func _context(mode: String) -> Dictionary:
	return {"active": true, "together": true, "mode": mode, "callsign": "Kite"}


func _earned(profile) -> Array:
	return profile.companion_report().get("individual", {}).get("earned_memory_ids", [])


func _has_access(_access_id: String) -> bool:
	return _access_allowed


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
	return Vector2.ZERO


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
