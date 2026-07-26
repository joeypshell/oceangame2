extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const ExpeditionDayDebrief := preload("res://scripts/main/expedition_day_debrief.gd")
const ExpeditionDayPresentation := preload("res://scripts/main/expedition_day_presentation.gd")
const ExpeditionDayState := preload("res://scripts/main/expedition_day_state.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")

const RELAY_ID := "upper_left_wreck_relay_route"
const BLOOM_ID := "southwest_jellyfish_bloom"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	await process_frame
	main.set_process(false)
	main._player.set_physics_process(false)

	var profile = main._anomaly_survey.profile_state()
	profile.complete_discovery(
		ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
		false
	)
	main._expedition_day_state.end_day("voluntary")
	var plan_report: Dictionary = main._refresh_expedition_plan()
	main._update_status_label()
	await process_frame

	_expect(
		plan_report.get("eligible_ids") == [RELAY_ID, BLOOM_ID],
		"debrief did not expose the two source-ordered leads"
	)
	var panel_report: Dictionary = main._expedition_plan_panel.get_test_report()
	_expect(bool(panel_report.get("visible", false)), "two-choice panel was hidden")
	_expect(
		panel_report.get("highlighted_lead_id") == RELAY_ID,
		"panel did not open on the first source lead"
	)
	_expect(
		_rows_contain_contract_text(panel_report.get("row_texts", [])),
		"planner rows omitted destination, opportunity, or readiness text"
	)
	_expect(
		str(panel_report.get("instruction_text", "")).find("N/DAY requires") != -1,
		"unpinned planner omitted next-day gate guidance"
	)

	var blocked: Dictionary = ExpeditionDayDebrief.handle_day_key(main)
	_expect(
		blocked.get("reason") == "plan_required"
		and main._expedition_day_state.phase == ExpeditionDayState.PHASE_DEBRIEF,
		"next day started without a pinned plan"
	)

	var active_tool_before := str(main._active_tools.selected_tool_id())
	main._unhandled_input(_key_event(KEY_TAB))
	panel_report = main._expedition_plan_panel.get_test_report()
	_expect(
		panel_report.get("highlighted_lead_id") == BLOOM_ID,
		"desktop Tab did not cycle the planner"
	)
	_expect(
		str(main._active_tools.selected_tool_id()) == active_tool_before,
		"debrief Tab cycled the active tool"
	)
	main._unhandled_input(_key_event(KEY_E))
	_expect(
		main._expedition_plan_state.selected_lead_id() == BLOOM_ID,
		"desktop E did not pin the highlighted bloom"
	)

	main._unhandled_input(_key_event(KEY_TAB))
	panel_report = main._expedition_plan_panel.get_test_report()
	_expect(
		str(panel_report.get("row_texts", [])[0]).begins_with(">")
		and str(panel_report.get("row_texts", [])[1]).find("[PINNED]") != -1,
		"highlight and pinned markers did not remain independent"
	)
	main._unhandled_input(_key_event(KEY_E))
	_expect(
		main._expedition_plan_state.selected_lead_id() == RELAY_ID,
		"desktop input did not replace the pinned plan"
	)
	panel_report = main._expedition_plan_panel.get_test_report()
	_expect(
		str(panel_report.get("row_texts", [])[0]).find("[PINNED]") != -1,
		"pinned and highlighted states were not visibly distinct"
	)
	var build_result := ExpeditionDayDebrief.handle_debrief_key(main, KEY_P)
	_expect(
		build_result.get("reason") != "ignored"
		and main._expedition_plan_state.selected_lead_id() == RELAY_ID,
		"project build command was intercepted or changed the plan"
	)

	main._expedition_day_state.begin_next_day()
	main._daily_conditions.sync(
		main._world.get_daily_conditions(),
		main._expedition_day_state.day_number
	)
	main._refresh_expedition_plan()
	var relay_guidance := ExpeditionDayPresentation.selected_plan_line(main)
	_expect(
		relay_guidance == "Plan: Follow the archive signal northwest",
		"relay selection did not produce source guidance"
	)

	main._expedition_day_state.begin_day(1)
	main._daily_conditions.sync(main._world.get_daily_conditions(), 1)
	main._expedition_day_state.end_day("voluntary")
	main._refresh_expedition_plan()
	main._update_status_label()
	main._unhandled_input(_action_event(&"active_tool_cycle_next"))
	_expect(
		main._expedition_plan_panel.highlighted_lead_id() == BLOOM_ID,
		"mobile TOOL action did not cycle the planner"
	)
	main._unhandled_input(_key_event(KEY_E))
	_expect(
		main._expedition_plan_state.selected_lead_id() == BLOOM_ID,
		"mobile ACT key path did not pin the bloom"
	)

	var controls := MobileTestControls.new()
	controls.force_visible = true
	get_root().add_child(controls)
	await process_frame
	var controls_report: Dictionary = controls.get_test_report()
	_expect(
		_mobile_commands_match(controls_report.get("commands", [])),
		"landscape controls omitted TOOL, ACT, BUILD, or DAY"
	)
	var planner_rect: Rect2 = main._expedition_plan_panel.get_test_report().get(
		"rect",
		Rect2()
	)
	var debrief_rect := Rect2(main._result_panel.position, main._result_panel.size)
	_expect(
		not planner_rect.intersects(debrief_rect),
		"planner covered the existing debrief summary"
	)
	for rect in controls_report.get("command_rects", {}).values():
		_expect(
			not planner_rect.intersects(rect),
			"planner overlapped a landscape-mobile command"
		)

	var started: Dictionary = ExpeditionDayDebrief.handle_day_key(main)
	_expect(
		bool(started.get("changed", false))
		and started.get("reason") == "next_day_started",
		"pinned plan did not permit next-day start"
	)
	_expect(
		main._expedition_plan_state.selected_lead_id() == BLOOM_ID,
		"next-day map load cleared the pinned bloom"
	)
	_expect(
		not bool(main._expedition_plan_panel.get_test_report().get("visible", true)),
		"full planner remained visible during active play"
	)
	var bloom_guidance := ExpeditionDayPresentation.selected_plan_line(main)
	_expect(
		bloom_guidance == "Plan: Search the southwest migration lane",
		"bloom selection did not produce source guidance"
	)
	_expect(
		not relay_guidance.is_empty() and relay_guidance != bloom_guidance,
		"relay and bloom guidance were not distinct"
	)
	var decorated := ExpeditionDayPresentation.decorate_status(main, "Immediate status")
	_expect(
		decorated.find(bloom_guidance) != -1
		and decorated.find("Immediate status") != -1,
		"active guidance replaced immediate status feedback"
	)
	main._run_complete = true
	_expect(
		ExpeditionDayPresentation.selected_plan_line(main).is_empty(),
		"selected plan leaked into result presentation"
	)
	main._run_complete = false
	main._sortie_state.failed = true
	_expect(
		ExpeditionDayPresentation.selected_plan_line(main).is_empty(),
		"selected plan competed with failure feedback"
	)

	controls.queue_free()
	main.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Expedition plan presentation smoke failed: %s" % failure)
		quit(1)
		return
	print(
		"Expedition plan presentation passed: choices=relay,bloom "
		+ "desktop=Tab+E mobile=TOOL+ACT build=P day_gate=plan_required "
		+ "pin_replace=true active_guidance=distinct panel_active_only=true "
		+ "landscape_controls=reachable_nonoverlap."
	)
	quit(0)


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _rows_contain_contract_text(rows: Array) -> bool:
	if rows.size() != 2:
		return false
	return (
		str(rows[0]).find("Northwest Wreck Relay") != -1
		and str(rows[0]).find("Current Stabilizer") != -1
		and str(rows[0]).find("Prepare |") != -1
		and str(rows[1]).find("Southwest Jellyfish Bloom") != -1
		and str(rows[1]).find("migration lane") != -1
		and str(rows[1]).find("Ready |") != -1
	)


func _mobile_commands_match(commands: Array) -> bool:
	var by_id := {}
	for command in commands:
		by_id[StringName(command.get("id", ""))] = command
	return (
		by_id.get(&"tool", {}).get("action") == &"active_tool_cycle_next"
		and int(by_id.get(&"interact", {}).get("keycode", 0)) == KEY_E
		and int(by_id.get(&"project", {}).get("keycode", 0)) == KEY_P
		and int(by_id.get(&"day", {}).get("keycode", 0)) == KEY_N
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
