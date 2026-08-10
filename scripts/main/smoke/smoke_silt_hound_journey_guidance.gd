extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CompanionJourneyGuidance := preload("res://scripts/companion/companion_journey_guidance.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const RESCUE_ID := "silt_hound_rescue_01"
const TARGET_ID := "silt_hound_buried_titanium_01"
const MARL_ID := "silt_hound_juvenile_01"

var _failures: Array[String] = []
var _copy: Array[String] = []


class FakeCompanion:
	extends RefCounted

	func report() -> Dictionary:
		return {"species_id": "silt_hound"}


class FakeSortie:
	extends RefCounted
	var live_companion
	var report_value := {"control": {"excavate": {"busy": false}}}

	func companion():
		return live_companion

	func memory_report() -> Dictionary:
		return {"pending_memory_ids": [], "ecology": {}}

	func control_runtime():
		return self

	func report() -> Dictionary:
		return report_value.duplicate(true)


class DayState:
	extends RefCounted
	var phase := "active"
	var sortie_count := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player = PLAYER_SCENE.instantiate()
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame
	world.configure_material_candidates([TARGET_ID], [])
	var profile := ExpansionProfileState.new("", false)
	profile.load_profile()
	var checkpoint: Dictionary = ReviewCheckpointFixture.apply(ReviewCheckpointFixture.LIVING_EXPEDITION_05_START, profile)
	_expect(bool(checkpoint.get("ready", false)), "fresh Silt Hound checkpoint failed")
	var sortie := FakeSortie.new()
	var guidance := CompanionJourneyGuidance.new()
	var day := DayState.new()

	player.global_position = _rescue_center(world)
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["dredge cable", "Cutter"], "authored rescue lead")
	_expect(world.set_creature_rescue_state(RESCUE_ID, "releasing"), "could not set releasing rescue state")
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["Hold USE", "cut Marl free"], "release action")
	_expect(world.set_creature_rescue_state(RESCUE_ID, "pending"), "could not set pending rescue state")
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["Marl is free", "surface boat"], "pending return")

	_expect(world.set_creature_rescue_state(RESCUE_ID, "committed"), "could not set committed rescue state")
	var committed: Dictionary = profile.commit_companion_rescue(MARL_ID, "silt_hound", "Marl", false)
	_expect(bool(committed.get("changed", false)), "Marl did not commit to the real profile owner")
	player.global_position = world.get_extraction_center()
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["Marl bonded", "TOOL choose Marl", "USE confirms"], "habitat selection")
	player.global_position = _target_center(world)
	_expect(not "choose Marl" in guidance.objective_text(world, player, profile, sortie, day), "Marl guidance nagged during another companion's sortie")
	_expect(bool(profile.select_active_companion(MARL_ID, false).get("changed", false)), "Marl was not selectable for the next sortie")
	player.global_position = world.get_extraction_center()
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["Marl selected", "Leave the boat"], "next-sortie launch")

	sortie.live_companion = FakeCompanion.new()
	player.global_position = _target_center(world)
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["buried mound", "Press B, then 2", "Excavate"], "excavation action")
	for state in ["approaching", "anticipating", "digging", "impact"]:
		sortie.report_value = {"control": {"excavate": {"busy": true, "state": state}}}
		_expect_text(_text(guidance, world, player, profile, sortie, day), [_state_word(state)], "physical %s guidance" % state)
	sortie.report_value = {"control": {"excavate": {"busy": false}}}
	_expect(world.reveal_buried_material_candidate(TARGET_ID), "authored mound could not reveal")
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["Deposit opened", "Collect", "titanium"], "revealed pickup")
	_expect(world.collect_material_candidate(TARGET_ID), "normal material owner could not deplete the revealed pickup")
	_expect_text(_text(guidance, world, player, profile, sortie, day), ["titanium secured", "Return", "bank"], "bank return")
	player.global_position = world.get_extraction_center()
	_expect(_text(guidance, world, player, profile, sortie, day).is_empty(), "resolved Silt Hound guidance did not clear at the boat")

	for value in _copy:
		var lowered := value.to_lower()
		_expect(not "scan" in lowered and not "arrow" in lowered and not "press q" in lowered and not "mount" in lowered, "journey copy introduced an unrelated action: %s" % value)
	_finish(world, player)


func _text(guidance, world, player, profile, sortie, day) -> String:
	var value: String = guidance.objective_text(world, player, profile, sortie, day)
	if not value.is_empty():
		_copy.append(value)
	return value


func _expect_text(value: String, fragments: Array, stage: String) -> void:
	for fragment in fragments:
		_expect(str(fragment) in value, "%s omitted '%s': %s" % [stage, fragment, value])


func _state_word(state: String) -> String:
	return {"approaching": "approaching", "anticipating": "braces", "digging": "excavating", "impact": "breaks open"}.get(state, state)


func _target_center(world) -> Vector2:
	return world.get_material_candidate_state(TARGET_ID).get("candidate", {}).get("center", Vector2.ZERO)


func _rescue_center(world) -> Vector2:
	for rescue in world.get_creature_rescues():
		if str((rescue as Dictionary).get("id", "")) == RESCUE_ID:
			return (rescue as Dictionary).get("center", Vector2.ZERO)
	return Vector2.ZERO


func _finish(world, player) -> void:
	player.queue_free()
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Silt Hound journey-guidance smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Silt Hound journey guidance rescue=physical pending=boat habitat=select excavation=deliberate pickup=typed bank=canonical resolved=clear forbidden_copy=none.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
