extends SceneTree

const CompanionHabitatSelection := preload("res://scripts/companion/companion_habitat_selection.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

var _failures: Array[String] = []
var _interaction_allowed := true


class FakeWorld extends Node2D:
	var at_boat := true

	func is_inside_boat(_position: Vector2) -> bool:
		return at_boat


class ReleaseProbe extends RefCounted:
	var count := 0

	func release() -> bool:
		count += 1
		return true


class NoteProbe extends RefCounted:
	var notes: Array[String] = []

	func push(note: String) -> void:
		notes.append(note)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile = _three_individual_profile()
	var world := FakeWorld.new()
	var player := Node2D.new()
	var release_probe := ReleaseProbe.new()
	var note_probe := NoteProbe.new()
	var habitat := CompanionHabitatSelection.new()
	get_root().add_child(world)
	get_root().add_child(player)
	get_root().add_child(habitat)
	player.set_physics_process(true)
	habitat.bind_interface(Callable(note_probe, "push"), Callable(self, "_can_interact"))
	habitat.bind_map(world, player, profile, Callable(release_probe, "release"))
	await process_frame
	habitat.sync_presence()
	var initial: Dictionary = habitat.report()
	_expect(bool(initial.get("at_boat", false)), "habitat did not recognize canonical boat presence")
	_expect(int(initial.get("individual_count", 0)) == 3, "habitat did not project all three committed individuals")
	_expect(bool(initial.get("panel", {}).get("visible", false)), "habitat panel was not visible at the boat")
	var rows: Array = initial.get("panel", {}).get("rows", [])
	_expect(rows.size() == 3, "habitat panel did not render three named rows")
	if rows.size() == 3:
		_expect(str(rows[0].get("history_label", "")).contains("Anchor Fins"), "Kite history disappeared from the habitat")
		_expect(str(rows[1].get("history_label", "")).contains("sensing partner"), "Mica role disappeared from the habitat")
		_expect(str(rows[2].get("history_label", "")).contains("excavation partner"), "Marl role was not readable in the habitat")
	_expect(release_probe.count == 1, "boat entry did not release the live companion exactly once")

	_expect(habitat.handle_input(_action(&"companion_command", true)), "BOND did not open three-individual selection")
	_expect(bool(habitat.report().get("selection_open", false)), "selection did not remain open after BOND press")
	_expect(not player.is_physics_processing(), "open selection did not lock player movement")
	_expect(habitat.handle_input(_action(&"companion_command", false)), "mobile-style BOND release escaped selection routing")
	_expect(bool(habitat.report().get("selection_open", false)), "BOND release closed the selector before confirmation")
	_expect(habitat.handle_input(_action(&"active_tool_cycle_next", true)), "TOOL did not cycle companion selection")
	_expect(habitat.handle_input(_action(&"active_tool_cycle_next", true)), "TOOL did not reach the third companion")
	_expect(habitat.handle_input(_action(&"active_tool_use", true)), "USE did not confirm companion selection")
	var marl_id := CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID
	_expect(profile.companion_report().get("active_individual_id") == marl_id, "Marl was not selected for the next sortie")
	_expect(not bool(habitat.report().get("selection_open", true)), "selector remained open after confirmation")
	_expect(player.is_physics_processing(), "confirmation did not restore player movement")
	_expect(note_probe.notes.has("Next sortie: Marl"), "selection did not emit concise next-sortie feedback")

	world.at_boat = false
	habitat.sync_presence()
	var selected_away := str(profile.companion_report().get("active_individual_id", ""))
	_expect(not bool(habitat.report().get("panel", {}).get("visible", true)), "habitat panel remained visible away from boat")
	_expect(not habitat.handle_input(_action(&"companion_command", true)), "habitat intercepted BOND away from the boat")
	_expect(profile.companion_report().get("active_individual_id") == selected_away, "away input changed active selection")

	world.at_boat = true
	habitat.sync_presence()
	_expect(release_probe.count == 2, "return to boat did not release the active sortie instance exactly once")
	_interaction_allowed = false
	_expect(not habitat.handle_input(_action(&"companion_command", true)), "blocked game state opened habitat selection")
	_interaction_allowed = true

	await process_frame
	habitat.layout_for_size(Vector2(1280, 720))
	var desktop_rect: Rect2 = habitat.report().get("panel", {}).get("rect", Rect2())
	_expect(desktop_rect.position.x >= 960.0 and desktop_rect.end.x <= 1280.0, "three-row desktop habitat escaped its right-side region: %s" % desktop_rect)
	_expect(desktop_rect.position.y >= 0.0 and desktop_rect.end.y <= 720.0, "three-row desktop habitat clipped vertically: %s" % desktop_rect)
	habitat.layout_for_size(Vector2(844, 390))
	var compact_rect: Rect2 = habitat.report().get("panel", {}).get("rect", Rect2())
	_expect(compact_rect.position.x >= 592.0, "three-row compact habitat overlapped the accepted cargo HUD region: %s" % compact_rect)
	_expect(compact_rect.position.y >= 0.0 and compact_rect.end.x <= 844.0 and compact_rect.end.y <= 390.0, "three-row compact habitat exceeded the viewport: %s" % compact_rect)

	var one_profile := ExpansionProfileState.new("user://unused_habitat_single.json", false)
	one_profile.load_profile()
	one_profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "Kite", false)
	habitat.bind_map(world, player, one_profile, Callable(release_probe, "release"))
	habitat.sync_presence()
	_expect(habitat.handle_input(_action(&"companion_command", true)), "single-companion BOND did not provide habitat feedback")
	_expect(not bool(habitat.report().get("selection_open", true)), "single-companion habitat opened a meaningless selector")
	_expect(note_probe.notes.has("Kite is ready for the next sortie"), "single-companion habitat feedback was unclear")

	habitat.queue_free()
	player.queue_free()
	world.queue_free()
	await process_frame
	_finish()


func _three_individual_profile():
	var profile := ExpansionProfileState.new("user://unused_habitat_three.json", false)
	profile.load_profile()
	profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "Kite", false)
	profile.earn_companion_memory("held_the_flow", false)
	profile.select_companion_adaptation("anchor_fins", false)
	profile.commit_companion_rescue(CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, "veil_cuttle", "Mica", false)
	profile.commit_companion_rescue(CompanionProfileState.THIRD_PROOF_INDIVIDUAL_ID, "silt_hound", "Marl", false)
	return profile


func _action(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _can_interact() -> bool:
	return _interaction_allowed


func _finish() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Companion habitat smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Companion habitat individuals=3 history=true boat_only=true release_on_return=true BOND_open=true TOOL_cycle=true USE_confirm=true active=marl mid_sortie_switch=false mobile_actions=true single_selector=false desktop_mobile_bounds=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
