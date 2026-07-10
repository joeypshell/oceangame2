extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)

	var boat_line := ExpeditionDayPresentation.overlay_line(main)
	_expect(boat_line.find("Day 1 | 05:00 | Dive 0") != -1, "initial daylight line mismatch")
	_expect(boat_line.find("Boat N End") != -1, "boat end-day affordance missing")
	_expect(boat_line.length() <= 64 and boat_line.find("\n") == -1, "boat line was not compact")
	var review_panel := main._review_canvas.get_node("ReviewPanel") as PanelContainer
	_expect(review_panel != null and review_panel.custom_minimum_size.x == 300.0, "review panel width was not stable")

	var surface_center := _surface_center_outside_boat(main._world)
	main._player.global_position = surface_center
	main._process(0.0)
	main._expedition_day_state.daylight_remaining_seconds = 59.0
	var surface_line := ExpeditionDayPresentation.overlay_line(main)
	_expect(surface_line.find("00:59 DUSK") != -1, "dusk warning missing")
	_expect(surface_line.find("Surface O2") != -1 and surface_line.find("N End") == -1, "surface and boat actions were not distinct")
	var blocked := ExpeditionDayPresentation.try_request_voluntary_end(main)
	_expect(not bool(blocked.get("requested", false)) and blocked.get("reason") == "boat_required", "surface allowed end day")

	main._expedition_day_state.daylight_remaining_seconds = 29.0
	_expect(ExpeditionDayPresentation.overlay_line(main).find("NIGHT SOON") != -1, "night-soon warning missing")
	main._expedition_day_state.advance_daylight(29.0)
	_expect(ExpeditionDayPresentation.overlay_line(main).find("NIGHTFALL") != -1, "nightfall feedback missing")

	main._expedition_day_state.begin_day(1)
	main._player.global_position = main._world.get_extraction_center()
	main._process(0.0)
	main._sortie_state.held_salvage = 1
	blocked = ExpeditionDayPresentation.try_request_voluntary_end(main)
	_expect(not bool(blocked.get("requested", false)) and blocked.get("reason") == "cargo_held", "held cargo allowed end day")
	main._sortie_state.clear_held()

	var end_event := InputEventKey.new()
	end_event.pressed = true
	end_event.keycode = KEY_N
	main._unhandled_input(end_event)
	_expect(main._expedition_day_state.phase == ExpeditionDayState.PHASE_END_REQUESTED, "N did not request end day")
	_expect(main._expedition_day_state.end_reason == "voluntary", "voluntary end reason mismatch")
	_expect(ExpeditionDayPresentation.overlay_line(main).find("ENDING") != -1, "end-request feedback missing")

	if not _failures.is_empty():
		for failure in _failures:
			push_error("Daylight presentation smoke failed: %s" % failure)
		quit(1)
		return
	print("Daylight presentation smoke passed: initial=05:00 dusk=00:59 night_soon=00:29 nightfall=true surface_o2_only=true boat_end_key=N voluntary_request=true panel_width=300.")
	quit(0)


func _surface_center_outside_boat(world) -> Vector2:
	for center in world.get_open_surface_centers():
		if not world.is_inside_boat(center):
			return center
	return Vector2.ZERO


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
