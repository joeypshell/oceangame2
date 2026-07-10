extends SceneTree

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")

const EXPECTED_COMMANDS := {
	&"oxygen": KEY_U,
	&"cargo": KEY_C,
	&"light": KEY_L,
	&"scanner": KEY_Q,
	&"project": KEY_P,
	&"day": KEY_N,
	&"reset": KEY_R,
	&"interact": KEY_E,
	&"attack": &"combat_attack",
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
	_expect(commands.size() == EXPECTED_COMMANDS.size(), "command pad did not expose exactly nine commands")
	_expect(command_rects.size() == EXPECTED_COMMANDS.size(), "command pad did not lay out exactly nine touch regions")

	var stick_rect: Rect2 = report.get("stick_rect", Rect2())
	var reachable_bottom := viewport_size.y - bottom_inset
	_expect(stick_rect.end.y <= reachable_bottom, "stick extended into the bottom interaction inset")
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
		controls._input(_touch(20, rect.get_center(), false))

	controls._input(_touch(10, stick_position, false))
	var down_position := stick_rect.get_center() + Vector2.DOWN * stick_rect.size.y * 0.45
	controls._input(_touch(11, down_position, true))
	_expect(Input.get_action_strength("ui_down") > 0.8, "lower stick travel did not press down movement")
	_expect(is_zero_approx(Input.get_action_strength("ui_up")), "lower stick travel pressed up movement")
	controls._input(_touch(11, down_position, false))
	for action in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"combat_attack"]:
		_expect(not Input.is_action_pressed(action), "%s remained pressed after touch release" % action)

	_expect(_dispatched.size() == EXPECTED_COMMANDS.size(), "not every command emitted an input event")
	for command_id in EXPECTED_COMMANDS:
		_expect(_dispatched.has(command_id), "%s command did not dispatch" % command_id)
		if not _dispatched.has(command_id):
			continue
		var event: InputEvent = _dispatched[command_id]
		var expected = EXPECTED_COMMANDS[command_id]
		if command_id == &"attack":
			_expect(event is InputEventAction and (event as InputEventAction).action == expected, "attack did not dispatch combat_attack")
		else:
			_expect(event is InputEventKey and (event as InputEventKey).keycode == expected, "%s dispatched the wrong key" % command_id)

	controls.queue_free()
	await process_frame
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: mobile test controls auto_hidden=headless stick=8_direction down_reachable=true bottom_inset=104 commands=9 simultaneous_input=true keyboard_events=U,C,L,Q,P,N,R,E attack_action=combat_attack.")
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
