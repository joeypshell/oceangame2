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
	var profile = _two_individual_profile()
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
	_expect(int(initial.get("individual_count", 0)) == 2, "habitat did not project both committed individuals")
	_expect(bool(initial.get("panel", {}).get("visible", false)), "habitat panel was not visible at the boat")
	_expect((initial.get("panel", {}).get("rows", []) as Array).size() == 2, "habitat panel did not render two named rows")
	_expect(release_probe.count == 1, "boat entry did not release the live companion exactly once")

	_expect(habitat.handle_input(_action(&"companion_command", true)), "BOND did not open two-individual selection")
	_expect(bool(habitat.report().get("selection_open", false)), "selection did not remain open after BOND press")
	_expect(not player.is_physics_processing(), "open selection did not lock player movement")
	_expect(habitat.handle_input(_action(&"companion_command", false)), "mobile-style BOND release escaped selection routing")
	_expect(bool(habitat.report().get("selection_open", false)), "BOND release closed the selector before confirmation")
	_expect(habitat.handle_input(_action(&"active_tool_cycle_next", true)), "TOOL did not cycle companion selection")
	_expect(habitat.handle_input(_action(&"active_tool_use", true)), "USE did not confirm companion selection")
	var mica_id := CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID
	_expect(profile.companion_report().get("active_individual_id") == mica_id, "Mica was not selected for the next sortie")
	_expect(not bool(habitat.report().get("selection_open", true)), "selector remained open after confirmation")
	_expect(player.is_physics_processing(), "confirmation did not restore player movement")
	_expect(note_probe.notes.has("Next sortie: Mica"), "selection did not emit concise next-sortie feedback")

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

	var one_profile := ExpansionProfileState.new("user://unused_habitat_single.json", false)
	one_profile.load_profile()
	one_profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "Kite", false)
	habitat.bind_map(world, player, one_profile, Callable(release_probe, "release"))
	habitat.sync_presence()
	_expect(habitat.handle_input(_action(&"companion_command", true)), "single-companion BOND did not provide habitat feedback")
	_expect(not bool(habitat.report().get("selection_open", true)), "single-companion habitat opened a meaningless selector")
	_expect(note_probe.notes.has("Kite is ready for the next sortie"), "single-companion habitat feedback was unclear")

	await process_frame
	habitat.layout_for_size(Vector2(844, 390))
	var rect: Rect2 = habitat.report().get("panel", {}).get("rect", Rect2())
	_expect(rect.position.x >= 0.0 and rect.position.y >= 0.0, "compact habitat panel started outside the viewport")
	_expect(rect.position.x >= 592.0, "compact habitat panel overlapped the accepted cargo HUD region: %s" % rect)
	_expect(
		rect.end.x <= 844.0 and rect.end.y <= 390.0,
		"compact habitat panel exceeded the viewport: %s" % rect
	)
	habitat.queue_free()
	player.queue_free()
	world.queue_free()
	await process_frame
	_finish()


func _two_individual_profile():
	var profile := ExpansionProfileState.new("user://unused_habitat_two.json", false)
	profile.load_profile()
	profile.commit_companion_rescue(CompanionProfileState.FIRST_PROOF_INDIVIDUAL_ID, "spark_ray", "Kite", false)
	profile.commit_companion_rescue(CompanionProfileState.SECOND_PROOF_INDIVIDUAL_ID, "veil_cuttle", "Mica", false)
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
	print("PASS: Companion habitat individuals=2 boat_only=true release_on_return=true BOND_open=true TOOL_cycle=true USE_confirm=true active=mica mid_sortie_switch=false mobile_actions=true single_selector=false compact_bounds=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
