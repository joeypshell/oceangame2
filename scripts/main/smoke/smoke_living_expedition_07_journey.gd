extends SceneTree

const Main := preload("res://scenes/main/Main.tscn")
const ReviewDriver := preload("res://scripts/main/smoke/marl_review_driver.gd")
const Debrief := preload("res://scripts/main/expedition_day_debrief.gd")
const MARL := "silt_hound_juvenile_01"
const MEMORY := "guarded_the_nest"
const MAP := "res://maps/production_level_01.greybox.json"

# Reuse real physical/input choreography, adding the authoritative survival
# owners to each deterministic field step. No completed event is seeded.
class JourneyDriver extends ReviewDriver:
	func tick() -> Dictionary:
		var event: Dictionary = await super.tick()
		main._update_oxygen(STEP)
		main._expedition_day_state.advance_daylight(STEP)
		expect(not main._sortie_state.failed, "field choreography exhausted survival budget")
		expect(event.get("kind") != "contact", "field choreography depended on an unhandled eel hit")
		return event

var main
var driver
var profile
var failures: Array[String] = []
var evidence := {}
var start: Vector2
var source_before: Dictionary
var capabilities_before: Array


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if not args.has("--smoke-living-expedition-07") or not args.has("--review-checkpoint=living_expedition_07_refuge") or not args.has("--show-mobile-controls"):
		_expect(false, "requires --smoke-living-expedition-07 --review-checkpoint=living_expedition_07_refuge --show-mobile-controls")
		await _finish()
		return
	main = Main.instantiate()
	root.add_child(main)
	await _settle()
	profile = main._anomaly_survey.profile_state()
	driver = JourneyDriver.new(main)
	_expect(main._review_checkpoint_report.get("ready", false) and not profile._persistence_enabled, "actual Main checkpoint/isolation rejected")
	if not failures.is_empty():
		await _finish()
		return
	start = main._player.global_position
	source_before = main._world._map_data.duplicate(true)
	capabilities_before = profile.report()["unlocked_capabilities"].duplicate()
	_expect(_individual().get("earned_memory_ids", []).is_empty() and _individual().get("selected_adaptation_id") == "", "journey pre-seeded growth")
	await driver.pause_probe()
	driver.freeze_live()
	await _false_positives()
	await _reload_field()
	_fill_cargo()
	await driver.refuge()
	_evidence("first_event")
	_expect(_pending().get("memory_id") == MEMORY and _individual()["earned_memory_ids"].is_empty(), "field result was not pending only")
	main._sortie_state.oxygen_seconds = 0.0
	main._handle_oxygen_depleted()
	_expect(main._sortie_state.failed and not main._player.is_physics_processing(), "failure did not lock swimming")
	_expect(_pending().is_empty() and _individual()["earned_memory_ids"].is_empty(), "failure before boat retained growth")
	_expect(main._sortie_state.held_salvage == 0, "failure retained unbanked cargo")
	main._reset_run()
	_expect(not main._sortie_state.failed, "Retry did not clear failure")
	await _reload_field()
	var full_ids := _fill_cargo()
	var oxygen: float = main._sortie_state.oxygen_seconds
	var daylight: float = main._expedition_day_state.daylight_remaining_seconds
	await driver.refuge()
	_expect(main._sortie_state.held_salvage_ids == full_ids, "refuge changed full cargo")
	_expect(main._sortie_state.oxygen_seconds < oxygen and main._expedition_day_state.daylight_remaining_seconds < daylight, "event stopped survival clocks")
	_expect(not main._companion_sortie.commit_memories_at_boat()["marl_memory"].get("changed", false), "field location committed memory")
	_expect(not driver.control().excavate_runtime().dispatch("excavate").get("changed", false), "duplicate event restarted")
	_evidence("pending_return")
	_return_to_boat()
	_expect(_individual()["earned_memory_ids"] == [MEMORY], "canonical boat did not secure exactly one memory")
	_expect(_individual()["selected_adaptation_id"] == "", "boat auto-adapted Marl")
	_expect(main._sortie_state.held_salvage == 0 and main._expedition_day_state.banked_salvage == full_ids.size(), "full cargo did not bank alongside memory")
	var committed: Dictionary = profile.companion_report().duplicate(true)
	for repeat in range(3): main._cargo_collection.update(0.0)
	_expect(profile.companion_report() == committed, "duplicate boat callback changed memory")
	_evidence("boat_committed")
	await _night(true)
	await _next_day()
	_expect(_individual()["earned_memory_ids"] == [MEMORY] and _individual()["selected_adaptation_id"] == "", "deferred choice did not survive day transition")
	_expect(main._world.burrow_refuge_presentation().report()["sheltered"], "committed refuge lost after next day")
	await _enter_field()
	_expect(not main._companion_sortie.companion().get_node("Presentation").report()["root_claws_visible"] and driver.command_index("ground_pin") == -1, "deferred memory granted growth on sortie")
	_return_to_boat()
	await _night(false)
	await _next_day()
	_expect(_individual()["selected_adaptation_id"] == "root_claws", "confirmed growth lost on next day")
	await _enter_field()
	_expect(main._companion_sortie.companion().get_node("Presentation").report()["root_claws_visible"], "fresh sortie omitted permanent fin growth")
	_evidence("adapted_sortie")
	driver.capture = Callable(self, "_record_action")
	await driver.ground_pin()
	driver.capture = Callable()
	await driver.recovery()
	_expect(main._hostiles.state_for(driver.EEL)["health"] == 3, "retreat payoff damaged the eel")
	_expect(not main._world.is_salvage_collected("salvage_deep_right_cache"), "pin granted its guarded reward")
	_evidence("released_follow")
	main._sortie_state.oxygen_seconds = 0.0
	main._handle_oxygen_depleted()
	_expect(_individual()["selected_adaptation_id"] == "root_claws", "failure after commitment removed growth")
	main._reset_run()
	await _reload_field()
	_expect(_individual()["earned_memory_ids"] == [MEMORY] and _individual()["selected_adaptation_id"] == "root_claws", "reload lost committed growth")
	_expect(driver.control().ground_pin_runtime().report()["state"] == "idle" and is_zero_approx(driver.control().ground_pin_runtime().report()["cooldown_seconds"]), "reload retained transient hold")
	_expect(main._world._map_data == source_before, "journey mutated source map")
	_expect(profile.report()["unlocked_capabilities"] == capabilities_before, "growth granted a diver equipment capability")
	_expect(profile.companion_report()["active_individual_id"] == MARL, "journey changed selected individual")
	await _finish()


func _false_positives() -> void:
	_fill_cargo()
	main._companion_sortie.observe_ecological_identification("southwest_bloom_migration_trace_01")
	for frame in range(90): await driver.tick()
	_expect(_pending().is_empty() and _individual()["earned_memory_ids"].is_empty(), "pickup/scan/time/live threat alone qualified memory")
	_expect(driver.control().ground_pin_runtime().dispatch().get("reason") == "root_claws_required", "unadapted Marl gained Pin")


func _reload_field() -> void:
	# Travel is elided at source-authored review boundaries; actual collision/input
	# checks and source return-path proofs remain separate release gates.
	main._load_playable_map(MAP, false)
	main._player.global_position = start
	main._process(0.0)
	driver.freeze_live()
	await _settle()
	driver.freeze_live()
	_expect(driver.body_clear(main._player) and driver.body_clear(main._companion_sortie.companion()), "reload spawned a body in terrain")


func _return_to_boat() -> void:
	main._player.global_position = main._world.get_entry_position("surface_boat_entry")
	_expect(main._world.is_inside_boat(main._player.global_position), "return is not canonical boat")
	main._process(0.0)


func _night(defer: bool) -> void:
	var before: Dictionary = profile.companion_report().duplicate(true)
	driver.key(KEY_N)
	Debrief.update(main, 0.0)
	_expect(main._expedition_day_state.phase == "debrief", "N did not begin real night")
	_expect(main._companion_sortie.requires_adaptation_selection(), "night omitted deliberate choice")
	if defer: driver.key(KEY_B)
	driver.key(KEY_SPACE)
	var after: Dictionary = profile.companion_report().duplicate(true)
	_expect(not main._companion_sortie.requires_adaptation_selection(), "choice did not unblock next day")
	_expect(after == before if defer else _individual()["selected_adaptation_id"] == "root_claws", "wrong night result")
	driver.key(KEY_SPACE)
	_expect(profile.companion_report() == after, "repeat confirmation changed profile")
	_evidence("night_deferred" if defer else "night_confirmed")


func _next_day() -> void:
	var day: int = main._expedition_day_state.day_number
	var old_world: int = main._world.get_instance_id()
	# The initial review shortcut must not override the real next-day boat entry.
	main._review_checkpoint_report.erase("review_start_tile")
	var result: Dictionary = Debrief.handle_day_key(main)
	if result.get("reason") == "plan_required":
		var plan: Dictionary = main._refresh_expedition_plan()
		var eligible: Array = plan.get("eligible_ids", [])
		if not eligible.is_empty(): main._expedition_plan_state.select(str(eligible[0]), eligible, "debrief")
		result = Debrief.handle_day_key(main)
	main._player.set_physics_process(false)
	await _settle()
	_expect(result.get("reason") == "next_day_started" and main._expedition_day_state.day_number == day + 1, "day did not advance exactly once")
	_expect(main._world.get_instance_id() != old_world and main._world.is_inside_boat(main._player.global_position), "next day did not reload canonical boat")
	_expect(main._hostiles.state_for(driver.EEL)["phase"] == "home", "new day retained hostile phase")


func _enter_field() -> void:
	main._player.global_position = start
	main._process(0.0)
	driver.freeze_live()
	await _settle()
	driver.freeze_live()
	_expect(main._sortie_state.active and main._companion_sortie.companion() != null, "next sortie failed to launch Marl")


func _fill_cargo() -> Array[String]:
	var ids: Array[String] = []
	for salvage in main._world.get_salvage_centers():
		if salvage.get("interaction", "instant") != "instant": continue
		var id := str(salvage["id"])
		if not main._world.collect_salvage_by_id(id): continue
		main._collect_salvage_into_cargo(id)
		ids.append(id)
		if ids.size() == main._held_salvage_capacity(): break
	_expect(ids.size() == main._held_salvage_capacity(), "could not fill ordinary cargo fixture")
	return ids


func _record_action(state: String) -> void:
	_evidence(state)


func _evidence(stage: String) -> void:
	var control = main._companion_sortie.control_runtime()
	var hostile: Dictionary = main._hostiles.state_for(driver.EEL)
	evidence[stage] = {"individual": MARL, "event": "marl_guarded_nest_opportunity_01",
		"memory": _individual().get("earned_memory_ids", []), "adaptation": _individual().get("selected_adaptation_id", ""),
		"pending": _pending(), "pin": control.ground_pin_runtime().report(),
		"hostile": {"id": driver.EEL, "phase": hostile.get("phase"), "health": hostile.get("health"), "phase_seconds": hostile.get("phase_seconds")},
		"oxygen": main._sortie_state.oxygen_seconds, "health": main._player_health.report(),
		"held": main._sortie_state.held_salvage, "banked": main._expedition_day_state.banked_salvage,
		"day": main._expedition_day_state.day_number, "daylight": main._expedition_day_state.daylight_remaining_seconds}
	print("LE07 journey %s: %s" % [stage, evidence[stage]])


func _individual() -> Dictionary:
	return profile.companion_report().get("individual", {})


func _pending() -> Dictionary:
	return driver.control().refuge_runtime().report().get("pending", {})


func _settle() -> void:
	for frame in range(4):
		await process_frame
		await physics_frame


func _expect(value: bool, message: String) -> void:
	if not value: failures.append(message)


func _finish() -> void:
	paused = false
	if driver != null:
		failures.append_array(driver.failures)
		driver.capture = Callable()
	if is_instance_valid(main): main.queue_free()
	await process_frame
	for failure in failures: push_error("LE07 journey: " + failure)
	if failures.is_empty():
		print("PASS: LE07 actual Main journey pending->failure/retry->boat->defer->later night->Root Claws->physical pin/retreat->released follow->failure/reload; full_cargo=true source_unchanged=true normal_profile_untouched=true")
	quit(0 if failures.is_empty() else 1)
