extends SceneTree

const DailyConditionState := preload("res://scripts/main/daily_condition_state.gd")
const DailyConditionPresentation := preload("res://scripts/main/daily_condition_presentation.gd")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const MaterialCandidateSelector := preload("res://scripts/main/material_candidate_selector.gd")

const CONDITION_ID := "southwest_jellyfish_bloom"
const CANDIDATE_ID := "material_coil_southwest_bloom"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := DailyConditionState.new()
	var definitions := [{
		"id": CONDITION_ID,
		"schedule": "even_days_v1",
		"forecast_label": "Tomorrow: Southwest jellyfish bloom",
		"active_label": "Southwest bloom: jellyfish + coil trace",
	}]
	var day_one := state.sync(definitions, 1)
	_expect(day_one["current_condition_ids"].is_empty(), "day one activated bloom")
	_expect(day_one["next_condition_ids"] == [CONDITION_ID], "day one omitted bloom forecast")
	_expect(day_one["forecast_label"] == "Tomorrow: Southwest jellyfish bloom", "bloom forecast label drifted")
	var debrief_day := ExpeditionDayState.new()
	debrief_day.end_day("voluntary")
	var debrief_text := ExpeditionDayDebrief.build_text(debrief_day, null, state)
	_expect(debrief_text.find("Tomorrow: Southwest jellyfish bloom") != -1, "night debrief omitted bloom forecast")
	_expect(debrief_text.find("Tomorrow: Southwest jellyfish bloom") < debrief_text.find("N: Start day 2"), "forecast appeared after next-day action")

	var connector_report := state.sync([], 1)
	_expect(connector_report["next_condition_ids"] == [CONDITION_ID], "connector sync lost definitions")
	var day_two := state.sync([], 2)
	_expect(day_two["current_condition_ids"] == [CONDITION_ID], "day two omitted bloom")
	_expect(day_two["next_condition_ids"].is_empty(), "day three forecast retained bloom")
	_expect(day_two["forecast_label"] == DailyConditionState.BASELINE_FORECAST_LABEL, "baseline forecast label drifted")
	_expect(DailyConditionPresentation.active_line(state) == "Southwest bloom: jellyfish + coil trace", "active condition line drifted")

	var pools := [
		{"id": "normal", "candidate_ids": ["normal_material"], "select_count": 1},
		{"id": "bonus", "candidate_ids": [CANDIDATE_ID], "select_count": 1, "daily_condition_id": CONDITION_ID},
	]
	var baseline := MaterialCandidateSelector.select_for_day("production_slice_01", pools, 1)
	var bloom := MaterialCandidateSelector.select_for_day("production_slice_01", pools, 2, [], [CONDITION_ID])
	_expect(baseline == ["normal_material"], "baseline selected condition bonus")
	_expect(bloom.has("normal_material") and bloom.has(CANDIDATE_ID), "bloom omitted normal or bonus material")

	if not _failures.is_empty():
		for failure in _failures:
			push_error("Daily condition state smoke failed: %s" % failure)
		quit(1)
		return
	print("Daily condition state smoke passed: day1=baseline next=bloom day2=bloom next=baseline connector_preserved=true baseline_material=1 bloom_bonus=1.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
