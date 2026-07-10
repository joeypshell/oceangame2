extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	get_root().add_child(main)
	main.set_process(false)
	main._player.set_physics_process(false)
	main._hazard_interactions_enabled = false

	var surface_center := _surface_center_outside_boat(main._world)
	_expect(surface_center != Vector2.ZERO, "no authored open surface outside boat")
	_expect(main._world.is_at_open_surface(surface_center), "source-derived surface center was not open surface")
	_expect(not main._world.is_inside_boat(surface_center), "surface probe overlapped boat")
	_expect(not main._world.is_inside_extraction(surface_center), "surface probe was treated as extraction")

	var salvage := _instant_salvage(main._world)
	_expect(not salvage.is_empty(), "no instant salvage available for cargo probe")
	main._player.global_position = salvage.get("center", Vector2.ZERO)
	main._process(0.0)
	_expect(main._sortie_state.held_salvage == 1, "cargo probe did not collect salvage")

	main._session_progression.grant_wallet_reward(1000)
	var wallet_before: int = main._session_wallet()
	var profile_before: Dictionary = main._anomaly_survey.report().get("profile", {}).duplicate(true)
	main._sortie_state.oxygen_seconds = 20.0
	main._player.global_position = surface_center
	var daylight_before: float = main._expedition_day_state.daylight_remaining_seconds
	main._process(1.0)

	_expect(is_equal_approx(main._sortie_state.oxygen_seconds, 45.0), "open surface did not refill oxygen")
	_expect(main._sortie_state.held_salvage == 1 and main._banked_salvage == 0, "open surface banked cargo")
	_expect(main._session_wallet() == wallet_before, "open surface changed wallet")
	_expect(not main._try_purchase_oxygen_tank_upgrade(), "open surface allowed upgrade purchase")
	_expect(main._session_wallet() == wallet_before, "blocked surface purchase charged wallet")
	_expect(main._anomaly_survey.report().get("profile", {}) == profile_before, "open surface changed profile")
	_expect(is_equal_approx(main._expedition_day_state.daylight_remaining_seconds, daylight_before - 1.0), "daylight did not continue at surface")

	main._player.global_position = main._world.get_extraction_center()
	_expect(main._world.is_inside_boat(main._player.global_position), "canonical extraction was not boat")
	main._process(0.0)
	_expect(main._sortie_state.held_salvage == 0 and main._banked_salvage == 1, "boat did not bank cargo")

	if not _failures.is_empty():
		for failure in _failures:
			push_error("Surface/boat semantics smoke failed: %s" % failure)
		quit(1)
		return
	print("Surface/boat semantics smoke passed: surface=%s oxygen=20.0->45.0 held_at_surface=1 banked_at_surface=0 boat_banked=1 daylight_delta=1.0 wallet_unchanged=true profile_unchanged=true." % str(surface_center))
	quit(0)


func _surface_center_outside_boat(world) -> Vector2:
	for center in world.get_open_surface_centers():
		if not world.is_inside_boat(center):
			return center
	return Vector2.ZERO


func _instant_salvage(world) -> Dictionary:
	for salvage in world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			return salvage
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
