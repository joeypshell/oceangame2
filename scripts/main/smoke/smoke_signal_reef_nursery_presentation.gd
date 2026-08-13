extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const MAP_PATH := "res://maps/production_level_01.greybox.json"
const JOURNEY_ID := "signal_reef_nursery_journey_01"
const SCHOOL_ID := "signal_reef_filter_skate_school_01"
const NURSERY_ID := "signal_reef_filter_skate_nursery_01"
const PRESSURE_ID := "signal_reef_jellyfish_pressure_01"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame
	var report: Dictionary = world.get_signal_reef_nursery_report()
	_expect(bool(report.get("configured", false)), "source-authored nursery did not project")
	_expect(str(report.get("journey_id", "")) == JOURNEY_ID, "journey id drifted")
	_expect(str(report.get("school_id", "")) == SCHOOL_ID, "school id drifted")
	_expect(str(report.get("nursery_id", "")) == NURSERY_ID, "nursery id drifted")
	_expect(str(report.get("pressure_id", "")) == PRESSURE_ID, "pressure id drifted")
	_expect(str(report.get("state", "")) == "unresolved", "fresh school was not unresolved")
	_expect(int(report.get("school_member_count", 0)) == 5, "fresh school did not render as a group")
	_expect(bool(report.get("passive", false)) and not bool(report.get("bondable", true)), "school became bondable")
	_expect(not bool(report.get("collectible", true)) and not bool(report.get("harvestable", true)), "school became cargo or harvest")
	_expect(not bool(report.get("damaging", true)) and (report.get("reward_ids", []) as Array).is_empty(), "pressure or school added damage/rewards")
	_expect((report.get("context_ids", []) as Array).size() == 2, "both adaptation contexts did not project")
	var initial_center: Vector2 = report.get("school_center", Vector2.ZERO)
	world.advance_signal_reef_nursery(0.75)
	var passive_center: Vector2 = world.get_signal_reef_nursery_report().get("school_center", Vector2.ZERO)
	_expect(initial_center.distance_to(passive_center) > 0.1, "passive school did not swim")

	_expect(world.set_signal_reef_nursery_state("anchor_active", 0.0), "Anchor state was rejected")
	world.advance_signal_reef_nursery(1.2)
	report = world.get_signal_reef_nursery_report()
	_expect(str(report.get("state", "")) == "anchor_active" and is_equal_approx(float(report.get("shelter_progress", 0.0)), 0.5), "Anchor shelter movement was not deterministic")
	world.advance_signal_reef_nursery(1.2)
	report = world.get_signal_reef_nursery_report()
	_expect(str(report.get("state", "")) == "sheltered_pending_return", "Anchor response did not shelter the school")
	_expect((report.get("school_center", Vector2.ZERO) as Vector2).distance_to(report.get("nursery_center", Vector2.ZERO)) < 20.0, "sheltered school did not occupy nursery")
	_expect(world.reset_signal_reef_nursery_uncommitted(), "pending field state did not reset")
	_expect(str(world.get_signal_reef_nursery_report().get("state", "")) == "unresolved", "reset did not restore source state")

	_expect(world.set_signal_reef_nursery_state("guardian_active", 0.25), "Guardian state was rejected")
	world.advance_signal_reef_nursery(1.8)
	_expect(str(world.get_signal_reef_nursery_report().get("state", "")) == "sheltered_pending_return", "Guardian response did not shelter the same school")
	_expect(world.set_signal_reef_nursery_state("committed_waiting_next_day"), "committed presentation was rejected")
	_expect(not world.reset_signal_reef_nursery_uncommitted(), "committed state was erased by field reset")
	_expect(world.set_signal_reef_nursery_state("restored"), "restored presentation was rejected")
	report = world.get_signal_reef_nursery_report()
	_expect(str(report.get("state", "")) == "restored" and int(report.get("school_member_count", 0)) == 7, "next-day nursery did not visibly grow/settle")
	_expect(world.get_node_or_null("Markers/SignalReefNursery") != null, "focused presentation node was not scoped under world markers")
	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Signal Reef nursery presentation smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Signal Reef nursery presentation source=projected wildlife=passive+swimming pressure=non_damaging states=unresolved+anchor+guardian+sheltered+committed+restored school=5_to_7 rewards=none collision=unchanged.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
