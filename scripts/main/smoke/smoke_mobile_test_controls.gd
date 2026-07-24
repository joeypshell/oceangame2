extends SceneTree

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")

const EXPECTED_COMMANDS := {
	&"oxygen": KEY_U,
	&"cargo": KEY_C,
	&"tool": &"active_tool_cycle_next",
	&"project": KEY_P,
	&"day": KEY_N,
	&"reset": KEY_R,
	&"interact": KEY_E,
	&"use": &"active_tool_use",
}

var _failures: Array[String] = []
var _dispatched := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hidden_controls := MobileTestControls.new()
	get_root().add_child(hidden_controls)
	await process_frame
	_expect(not bool(hidden_controls.get_test_report().get("enabled", true)), "controls were visible in a normal headless run")
	hidden_controls.queue_free()
	await process_frame

	var controls := MobileTestControls.new()
	controls.force_visible = true
	controls.command_dispatched.connect(_on_command_dispatched)
	get_root().add_child(controls)
	await process_frame

	var report: Dictionary = controls.get_test_report()
	_expect(bool(report.get("enabled", false)), "forced controls did not enable")
	var commands: Array = report.get("commands", [])
	var command_rects: Dictionary = report.get("command_rects", {})
	var viewport_size: Vector2 = report.get("viewport_size", Vector2.ZERO)
	var bottom_inset := float(report.get("bottom_inset", 0.0))
	_expect(commands.size() == EXPECTED_COMMANDS.size(), "command pad did not expose exactly eight commands")
	_expect(command_rects.size() == EXPECTED_COMMANDS.size(), "command pad did not lay out exactly eight touch regions")

	var stick_rect: Rect2 = report.get("stick_rect", Rect2())
	var reachable_bottom := viewport_size.y - bottom_inset
	_expect(stick_rect.end.y <= reachable_bottom, "stick extended into the bottom interaction inset")
	if viewport_size == Vector2(1280, 720):
		_expect(stick_rect == Rect2(30, 392, 224, 224), "accepted landscape stick rect drifted: %s" % stick_rect)
		_expect(command_rects.get(&"tool", Rect2()) == Rect2(1122, 356, 128, 80), "TOOL left its accepted touch rect")
		_expect(command_rects.get(&"use", Rect2()) == Rect2(984, 536, 128, 80), "USE left its accepted touch rect")
	for command_id in command_rects:
		var command_rect: Rect2 = command_rects[command_id]
		_expect(command_rect.end.y <= reachable_bottom, "%s extended into the bottom interaction inset" % command_id)
	var stick_position := stick_rect.get_center() + Vector2(0.65, -0.55) * stick_rect.size.x * 0.5
	controls._input(_touch(10, stick_position, true))
	_expect(Input.get_action_strength("ui_right") > 0.5, "stick did not press right movement")
	_expect(Input.get_action_strength("ui_up") > 0.4, "stick did not press up movement")
	_expect(is_zero_approx(Input.get_action_strength("ui_left")), "stick pressed the opposite horizontal action")
	_expect(is_zero_approx(Input.get_action_strength("ui_down")), "stick pressed the opposite vertical action")

	for command in commands:
		var command_id := StringName(command["id"])
		var rect: Rect2 = command_rects.get(command_id, Rect2())
		controls._input(_touch(20, rect.get_center(), true))
		_expect(Input.get_action_strength("ui_right") > 0.5, "command touch released simultaneous movement")
		if bool(command.get("hold", false)):
			await process_frame
			_expect(Input.is_action_pressed(StringName(command["action"])), "%s action did not remain held with its touch" % command_id)
		controls._input(_touch(20, rect.get_center(), false))
		if bool(command.get("hold", false)):
			await process_frame
			_expect(not Input.is_action_pressed(StringName(command["action"])), "%s action remained held after touch release" % command_id)

	controls._input(_touch(10, stick_position, false))
	var down_position := stick_rect.get_center() + Vector2.DOWN * stick_rect.size.y * 0.45
	controls._input(_touch(11, down_position, true))
	_expect(Input.get_action_strength("ui_down") > 0.8, "lower stick travel did not press down movement")
	_expect(is_zero_approx(Input.get_action_strength("ui_up")), "lower stick travel pressed up movement")
	controls._input(_touch(11, down_position, false))
	for action in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"active_tool_cycle_next", &"active_tool_use"]:
		_expect(not Input.is_action_pressed(action), "%s remained pressed after touch release" % action)

	_expect(_dispatched.size() == EXPECTED_COMMANDS.size(), "not every command emitted an input event")
	for command_id in EXPECTED_COMMANDS:
		_expect(_dispatched.has(command_id), "%s command did not dispatch" % command_id)
		if not _dispatched.has(command_id):
			continue
		var event: InputEvent = _dispatched[command_id]
		var expected = EXPECTED_COMMANDS[command_id]
		if expected is StringName:
			_expect(event is InputEventAction and (event as InputEventAction).action == expected, "%s dispatched the wrong action" % command_id)
		else:
			_expect(event is InputEventKey and (event as InputEventKey).keycode == expected, "%s dispatched the wrong key" % command_id)

	var hud := ActiveToolHud.new()
	get_root().add_child(hud)
	await process_frame
	hud.refresh({"selected_tool_id": "", "selected_label": "", "owned_tool_ids": []})
	hud.layout_for_size(Vector2(1280, 720))
	var hud_report: Dictionary = hud.get_test_report()
	_expect(not bool(hud_report.get("visible", true)) and hud_report.get("slots", []).is_empty(), "no-tool hotbar remained visible")
	hud.refresh({"selected_tool_id": "survey_scanner_1", "selected_label": "Scanner", "owned_tool_ids": ["survey_scanner_1"]})
	hud_report = hud.get_test_report()
	var desktop_slots: Array = hud_report.get("slots", [])
	_expect(bool(hud_report.get("visible", false)) and desktop_slots.size() == 1, "owned Scanner did not create one hotbar slot")
	_expect(hud_report.get("selected_label") == "Scanner" and bool(desktop_slots[0].get("selected", false)), "desktop hotbar did not select Scanner")
	_expect(bool(desktop_slots[0].get("has_texture", false)) and str(desktop_slots[0].get("tooltip", "")) == "Scanner", "Scanner slot omitted its icon or tooltip")
	_expect(hud_report.get("rect") == Rect2(606, 634, 68, 68) and hud_report.get("bottom_gap") == 18.0, "desktop hotbar did not center in the bottom band: %s" % hud_report.get("rect"))
	hud.set_mobile_controls_visible(true)
	_expect(str(hud.get_test_report().get("prompt", "")).is_empty(), "touch hotbar duplicated TOOL/USE instructions")
	hud.set_mobile_controls_visible(false)
	hud.refresh({"selected_tool_id": "salvage_cutter", "selected_label": "Cutter", "owned_tool_ids": ["survey_scanner_1", "salvage_cutter", "shock_prod"]})
	hud_report = hud.get_test_report()
	var all_slots: Array = hud_report.get("slots", [])
	_expect(all_slots.map(func(slot): return str(slot.get("id", ""))) == ["survey_scanner_1", "salvage_cutter", "shock_prod"], "hotbar order drifted: %s" % [all_slots])
	_expect(all_slots.all(func(slot): return bool(slot.get("has_texture", false))), "one or more active tools retained a text placeholder")
	_expect(bool(all_slots[1].get("selected", false)) and not bool(all_slots[0].get("selected", true)) and not bool(all_slots[2].get("selected", true)), "cycling did not highlight only Cutter")
	var touch_hotbar_rect: Rect2 = hud_report.get("rect", Rect2())
	_expect(touch_hotbar_rect.position.y >= reachable_bottom and not touch_hotbar_rect.intersects(stick_rect), "desktop touch hotbar overlapped the interaction region")
	for command_rect in command_rects.values():
		_expect(not touch_hotbar_rect.intersects(command_rect), "desktop touch hotbar overlapped a command button")
	hud.layout_for_size(Vector2(1920, 1080))
	_expect(hud.get_test_report().get("rect") == Rect2(864, 994, 192, 68), "wide hotbar did not remain bottom-centered: %s" % hud.get_test_report().get("rect"))
	hud.layout_for_size(Vector2(844, 390))
	hud_report = hud.get_test_report()
	var compact_rect: Rect2 = hud_report.get("rect", Rect2())
	_expect(bool(hud_report.get("compact", false)) and str(hud_report.get("prompt", "")).is_empty(), "mobile hotbar did not use its compact icon state")
	_expect(compact_rect == Rect2(346, 324, 152, 54) and compact_rect.position.y >= 390.0 - bottom_inset, "mobile hotbar left its reserved bottom band: %s" % compact_rect)
	hud.queue_free()

	controls.queue_free()
	await process_frame
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: mobile test controls auto_hidden=headless stick=8_direction down_reachable=true bottom_inset=104 commands=8 simultaneous_input=true keyboard_events=U,C,P,N,R,E actions=TOOL+USE hold_until_release=true active_tool_hotbar=bottom_icons+desktop+844x390.")
	quit(0)


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _on_command_dispatched(command_id: StringName, event: InputEvent) -> void:
	_dispatched[command_id] = event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
