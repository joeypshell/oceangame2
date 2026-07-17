extends RefCounted

const ActiveToolController := preload("res://scripts/main/active_tool_controller.gd")
const PASSIVE_CAPABILITY_IDS := [
	"propulsion_fins",
	"oxygen_tank_1",
	"cargo_capacity_1",
	"dive_light_1",
	"pressure_suit_1",
	"current_stabilizer",
	"shock_prod_capacitor",
]

var _main
var _owned := {}
var _dispatched_tool_ids := PackedStringArray()


func _init(main_node) -> void:
	_main = main_node


func smoke_and_quit() -> void:
	var controller := ActiveToolController.new()
	var has_capability := Callable(self, "_has_capability")

	if not _verify_input_actions():
		_fail("Active-tool input bindings mismatch: cycle=%s use=%s expected=%s/%s." % [
			InputMap.action_get_events("active_tool_cycle_next"),
			InputMap.action_get_events("active_tool_use"),
			KEY_TAB,
			KEY_Q,
		])
		return
	if not _expect_selection(controller.refresh_ownership(has_capability), "", []):
		return

	for capability_id in PASSIVE_CAPABILITY_IDS:
		_owned[capability_id] = true
	if not _expect_selection(controller.refresh_ownership(has_capability), "", []):
		_fail("Passive capabilities entered the active-tool catalog.")
		return

	_owned[ActiveToolController.SHOCK_PROD_TOOL_ID] = true
	if not _expect_selection(controller.refresh_ownership(has_capability), ActiveToolController.SHOCK_PROD_TOOL_ID, [ActiveToolController.SHOCK_PROD_TOOL_ID]):
		return
	_owned[ActiveToolController.SCANNER_TOOL_ID] = true
	if not _expect_selection(controller.refresh_ownership(has_capability), ActiveToolController.SHOCK_PROD_TOOL_ID, [ActiveToolController.SCANNER_TOOL_ID, ActiveToolController.SHOCK_PROD_TOOL_ID]):
		return

	var cycled: Dictionary = controller.cycle_next(has_capability)
	if not _expect_selection(cycled, ActiveToolController.SCANNER_TOOL_ID, [ActiveToolController.SCANNER_TOOL_ID, ActiveToolController.SHOCK_PROD_TOOL_ID]):
		return
	_owned[ActiveToolController.CUTTER_TOOL_ID] = true
	cycled = controller.cycle_next(has_capability)
	if not _expect_selection(cycled, ActiveToolController.CUTTER_TOOL_ID, ActiveToolController.ordered_tool_ids()):
		return

	if not _expect_use(controller, has_capability, ActiveToolController.CUTTER_TOOL_ID):
		return
	cycled = controller.cycle_next(has_capability)
	if not _expect_selection(cycled, ActiveToolController.SHOCK_PROD_TOOL_ID, ActiveToolController.ordered_tool_ids()):
		return
	if not _expect_use(controller, has_capability, ActiveToolController.SHOCK_PROD_TOOL_ID):
		return
	cycled = controller.cycle_next(has_capability)
	if not _expect_selection(cycled, ActiveToolController.SCANNER_TOOL_ID, ActiveToolController.ordered_tool_ids()):
		return
	if not _expect_use(controller, has_capability, ActiveToolController.SCANNER_TOOL_ID):
		return
	cycled = controller.cycle_next(has_capability)
	if not _expect_selection(cycled, ActiveToolController.CUTTER_TOOL_ID, ActiveToolController.ordered_tool_ids()):
		return

	_owned.erase(ActiveToolController.CUTTER_TOOL_ID)
	if not _expect_selection(controller.refresh_ownership(has_capability), ActiveToolController.SCANNER_TOOL_ID, [ActiveToolController.SCANNER_TOOL_ID, ActiveToolController.SHOCK_PROD_TOOL_ID]):
		return
	_owned.erase(ActiveToolController.SCANNER_TOOL_ID)
	_owned.erase(ActiveToolController.SHOCK_PROD_TOOL_ID)
	var no_tool_result: Dictionary = controller.use_selected(has_capability, Callable(self, "_dispatch_tool"))
	if str(no_tool_result.get("status", "")) != "no_tool" or _dispatched_tool_ids.size() != 3:
		_fail("No-tool use mutated dispatch state: result=%s dispatched=%s." % [no_tool_result, _dispatched_tool_ids])
		return

	print("Active-tool selection smoke passed: order=%s bindings=Tab/Q passive_excluded=true dispatch=%s normalized=%s." % [
		ActiveToolController.ordered_tool_ids(),
		_dispatched_tool_ids,
		controller.selected_tool_id(),
	])
	_main.get_tree().quit()


func _has_capability(capability_id: String) -> bool:
	return bool(_owned.get(capability_id, false))


func _dispatch_tool(tool_id: String) -> Dictionary:
	_dispatched_tool_ids.append(tool_id)
	return {"status": "used"}


func _expect_use(controller, has_capability: Callable, expected_tool_id: String) -> bool:
	var previous_count := _dispatched_tool_ids.size()
	var result: Dictionary = controller.use_selected(has_capability, Callable(self, "_dispatch_tool"))
	if str(result.get("status", "")) == "used" and _dispatched_tool_ids.size() == previous_count + 1 and _dispatched_tool_ids[-1] == expected_tool_id:
		return true
	_fail("Active-tool use did not dispatch only %s: result=%s dispatched=%s." % [expected_tool_id, result, _dispatched_tool_ids])
	return false


func _expect_selection(report: Dictionary, expected_selected: String, expected_owned) -> bool:
	var actual_selected := str(report.get("selected_tool_id", ""))
	var actual_owned: PackedStringArray = report.get("owned_tool_ids", PackedStringArray())
	var expected_ids := PackedStringArray(expected_owned)
	if actual_selected == expected_selected and actual_owned == expected_ids:
		return true
	_fail("Active-tool selection mismatch: selected=%s expected=%s owned=%s expected_owned=%s." % [actual_selected, expected_selected, actual_owned, expected_ids])
	return false


func _verify_input_actions() -> bool:
	return (
		InputMap.has_action("active_tool_cycle_next")
		and InputMap.has_action("active_tool_use")
		and _action_has_key("active_tool_cycle_next", KEY_TAB)
		and _action_has_key("active_tool_use", KEY_Q)
	)


func _action_has_key(action: StringName, expected_key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == expected_key or key_event.physical_keycode == expected_key:
				return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	_main.get_tree().quit(1)
