extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const DestinationPayoffFeedback := preload("res://scripts/main/destination_payoff_feedback.gd")
const MAP_PATH := "res://maps/production_slice_01.greybox.json"
const GATE_ID := "upper_right_current_pocket_gate"
const TARGET_ID := "salvage_current_pocket_cache"
const PAYOFF_ROUTE := "propulsion_fins_payoff"
const RETURN_PROMPT := "Fins ready | Return: upper-right current pocket"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world = WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	world.load_greybox()
	var feedback := DestinationPayoffFeedback.new()
	feedback.reset(world.get_salvage_centers(), world.get_current_gates())
	var target := _salvage_by_id(world, TARGET_ID)
	_expect(not target.is_empty(), "current-pocket payoff source missing")
	_expect(str(target.get("tier", "")) == "valuable", "current-pocket payoff is not valuable")
	_expect(str(target.get("validation_route", "")) == PAYOFF_ROUTE, "current-pocket payoff route drifted")
	_expect(not world.is_salvage_collected(TARGET_ID), "payoff was hidden before gate unlock")

	var affordance := world.get_node_or_null("Markers/%sCurrentAffordance" % GATE_ID)
	_expect(affordance != null, "source-derived current affordance missing")
	if affordance != null:
		_expect(str(affordance.get_meta("current_direction", "")) == "left", "current affordance direction drifted")
		var line_count := 0
		for child in affordance.get_children():
			if child is Line2D:
				line_count += 1
		_expect(line_count == 8, "current affordance expected two boundaries and six arrow lines")

	var boat_position: Vector2 = world.get_entry_position("surface_boat_entry")
	_expect(world.is_inside_boat(boat_position), "return cue fixture is not at the boat")
	_expect(feedback.return_prompt(world, boat_position, Callable(self, "_has_no_capability"), [], []).is_empty(), "return cue appeared before fins")
	_expect(feedback.return_prompt(world, boat_position, Callable(self, "_has_fins"), [], []) == RETURN_PROMPT, "fins return cue drifted")
	_expect(feedback.return_prompt(world, boat_position, Callable(self, "_has_fins"), [TARGET_ID], []).is_empty(), "return cue ignored held payoff")
	_expect(feedback.return_prompt(world, boat_position, Callable(self, "_has_fins"), [], [TARGET_ID]).is_empty(), "return cue ignored banked payoff")

	_expect(world.collect_salvage_by_id(TARGET_ID), "payoff could not use normal salvage collection")
	_expect(feedback.return_prompt(world, boat_position, Callable(self, "_has_fins"), [], []).is_empty(), "return cue ignored collected payoff")
	world.restore_salvage([TARGET_ID])
	_expect(not world.is_salvage_collected(TARGET_ID), "normal failure restoration did not restore payoff")
	_expect(feedback.collection_feedback(TARGET_ID, 300) == "Upper-right current pocket +300", "payoff collection feedback drifted")
	_expect(feedback.route_label(PAYOFF_ROUTE) == "Upper-right current pocket", "payoff result label drifted")
	_expect(feedback.is_collection_note("Upper-right current pocket +300"), "payoff collection note was not classified")

	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Current pocket feedback state smoke failed: %s" % failure)
		quit(1)
		return
	print("Current pocket feedback state smoke passed: affordance=source_direction+boundary locked_visible=true return_cue=boat_context payoff=normal_cargo+restore+route_result.")
	quit(0)


func _salvage_by_id(world, salvage_id: String) -> Dictionary:
	for salvage in world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _has_no_capability(_capability_id: String) -> bool:
	return false


func _has_fins(capability_id: String) -> bool:
	return capability_id == "propulsion_fins"


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
