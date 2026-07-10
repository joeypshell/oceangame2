extends SceneTree

const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var day := ExpeditionDayState.new(5.0)
	_expect(day.phase == ExpeditionDayState.PHASE_ACTIVE, "day did not start active")
	_expect(is_equal_approx(day.daylight_remaining_seconds, 5.0), "daylight override was ignored")

	var first_tick := day.advance_daylight(1.25)
	_expect(not bool(first_tick.get("nightfall_triggered", false)), "nightfall triggered before zero")
	_expect(is_equal_approx(day.daylight_remaining_seconds, 3.75), "daylight countdown mismatch")

	day.record_sortie_started()
	day.record_bank(1, 100)
	day.on_map_transition("production_slice_04")
	_expect(is_equal_approx(day.daylight_remaining_seconds, 3.75), "connector reset daylight")
	_expect(day.sortie_count == 1 and day.banked_score == 100, "connector reset day ledger")

	var nightfall_tick := day.advance_daylight(3.75)
	_expect(bool(nightfall_tick.get("nightfall_triggered", false)), "zero did not trigger nightfall")
	_expect(day.phase == ExpeditionDayState.PHASE_NIGHTFALL_PENDING, "nightfall phase mismatch")
	_expect(day.nightfall_event_count == 1, "nightfall did not trigger exactly once")

	var repeated_tick := day.advance_daylight(30.0)
	_expect(not bool(repeated_tick.get("nightfall_triggered", false)), "nightfall retriggered")
	_expect(day.nightfall_event_count == 1 and day.daylight_remaining_seconds == 0.0, "nightfall state drifted after zero")

	day.end_day("nightfall")
	_expect(day.phase == ExpeditionDayState.PHASE_DEBRIEF, "debrief transition mismatch")
	day.begin_next_day()
	_expect(day.day_number == 2 and day.phase == ExpeditionDayState.PHASE_ACTIVE, "next day did not restart")
	_expect(is_equal_approx(day.daylight_remaining_seconds, 5.0), "next day did not restore daylight")
	_expect(day.nightfall_event_count == 0, "next day retained nightfall event")

	if not _failures.is_empty():
		for failure in _failures:
			push_error("Daylight runtime smoke failed: %s" % failure)
		quit(1)
		return
	print("Daylight runtime smoke passed: initial=5.0 connector_remaining=3.75 nightfall_events=1 next_day=2 reset=5.0.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
