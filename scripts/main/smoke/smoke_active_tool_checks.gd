extends RefCounted

const ActiveToolController := preload("res://scripts/main/active_tool_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const ReviewCheckpointFixture := preload("res://scripts/main/review_checkpoint_fixture.gd")
const ScannerSmokePose := preload("res://scripts/main/smoke/scanner_smoke_pose.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const HOSTILE_ID := "deep_cache_territorial_eel"
const RELAY_SURVEY_ID := "upper_left_wreck_relay_survey"
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
			KEY_SPACE,
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

	print("Active-tool selection smoke passed: order=%s bindings=Tab/Space passive_excluded=true dispatch=%s normalized=%s." % [
		ActiveToolController.ordered_tool_ids(),
		_dispatched_tool_ids,
		controller.selected_tool_id(),
	])
	_main.get_tree().quit()


func smoke_checkpoint_shock_prod_and_quit() -> void:
	var checkpoint_report: Dictionary = _main._review_checkpoint_report
	if not bool(checkpoint_report.get("ready", false)) or str(checkpoint_report.get("checkpoint_id", "")) != ReviewCheckpointFixture.EXPANSION_14_START:
		_fail("Named checkpoint was not ready: %s." % checkpoint_report)
		return
	var profile = _main._anomaly_survey.profile_state()
	if not (
		profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID)
		and profile.has_capability(ExpansionProfileState.SHOCK_PROD_CAPACITOR_CAPABILITY_ID)
	):
		_fail("Checkpoint omitted the Shock Prod or capacitor capability.")
		return
	var initial: Dictionary = _main._refresh_active_tools()
	if str(initial.get("selected_tool_id", "")) != ActiveToolController.SCANNER_TOOL_ID:
		_fail("Checkpoint did not begin with Scanner selected: %s." % initial)
		return
	var unselected_overlay: String = _main._combat_overlay_text()
	if unselected_overlay.find("Shock prod owned") == -1 or unselected_overlay.find("Shock prod +capacitor ready") != -1:
		_fail("Unselected Shock Prod was described as ready: %s." % unselected_overlay)
		return

	var relay_target := _record_by_id(_main._world.get_survey_targets(), RELAY_SURVEY_ID)
	if relay_target.is_empty() or not bool(ScannerSmokePose.new().place(_main._world, _main._player, relay_target).get("found", false)):
		_fail("Checkpoint could not pose the Scanner at the wreck relay.")
		return
	_press_action("active_tool_use")
	var partial_scan: Dictionary = _main._anomaly_survey.update(_main._world, _main._player, 0.75)
	var partial_progress := float(partial_scan.get("survey", {}).get("progress", 0.0))
	if partial_progress <= 0.0 or partial_progress >= 1.0:
		_fail("Held Scanner input did not create partial relay progress: %s." % partial_scan)
		return
	_press_action("active_tool_cycle_next")
	if (
		_main._active_tools.selected_tool_id() != ActiveToolController.CUTTER_TOOL_ID
		or not is_zero_approx(float(_main._anomaly_survey.report().get("interaction", {}).get("progress", -1.0)))
	):
		_fail("Switching away from Scanner did not cancel relay progress.")
		return
	_press_action("active_tool_cycle_next")
	_press_action("active_tool_cycle_next")
	if _main._active_tools.selected_tool_id() != ActiveToolController.SCANNER_TOOL_ID:
		_fail("Scanner cancellation fixture did not restore the checkpoint selection.")
		return

	var state: Dictionary = _main._hostiles.state_for(HOSTILE_ID)
	if state.is_empty():
		_fail("Full-level checkpoint omitted %s." % HOSTILE_ID)
		return
	_main._player.global_position = state.get("home_center", Vector2.ZERO) + Vector2(-60, 0)
	_main._player.swim_in_direction(Vector2.RIGHT, 0.0)
	_main._hostiles.update(_main._world, _main._player.global_position, 0.0)
	var wrong_tool_prompt: String = _main._active_tool_runtime.combat_prompt()
	if wrong_tool_prompt.find("Tab/TOOL select Shock prod") == -1 or wrong_tool_prompt.find("Space/USE") == -1:
		_fail("Encounter did not explain selected-tool use: %s." % wrong_tool_prompt)
		return
	_press_action("active_tool_cycle_next")
	if _main._active_tools.selected_tool_id() != ActiveToolController.CUTTER_TOOL_ID:
		_fail("Wrong-tool handoff fixture did not select Cutter.")
		return
	var wrong_tool_use: Dictionary = _main._active_tool_runtime.use()
	if (
		str(wrong_tool_use.get("status", "")) != "wrong_context"
		or str(wrong_tool_use.get("note", "")).find("Space/USE") == -1
		or str(wrong_tool_use.get("note", "")).find("Q Use") != -1
	):
		_fail("Wrong-tool handoff drifted from Space/USE: %s." % wrong_tool_use)
		return
	_main._update_status_label()
	if _main._status_label.text.find(wrong_tool_prompt) == -1:
		_fail("Selected-tool encounter guidance did not reach the status overlay: %s." % _main._status_label.text)
		return
	_press_action("active_tool_cycle_next")
	if _main._active_tools.selected_tool_id() != ActiveToolController.SHOCK_PROD_TOOL_ID:
		_fail("Real cycle input did not select Shock Prod: %s." % _main._active_tools.report(Callable(profile, "has_capability")))
		return
	var ready_prompt: String = _main._active_tool_runtime.combat_prompt()
	if ready_prompt.find("in Shock prod range") == -1 or _main._combat_overlay_text().find("Shock prod +capacitor ready") == -1:
		_fail("Selected in-range Shock Prod was not clearly ready: %s | %s." % [ready_prompt, _main._combat_overlay_text()])
		return
	if _main._status_label.text.find(ready_prompt) == -1:
		_fail("In-range discharge guidance did not reach the status overlay: %s." % _main._status_label.text)
		return
	_press_action("active_tool_use")
	var hit_state: Dictionary = _main._hostiles.state_for(HOSTILE_ID)
	if int(hit_state.get("health", -1)) != 2 or str(hit_state.get("phase", "")) != "recovery" or not _main._last_status_note.begins_with("Shock prod capacitor hit"):
		_fail("Real Space/USE dispatch did not interrupt the eel: state=%s note=%s." % [hit_state, _main._last_status_note])
		return
	var discharge: Dictionary = _main._player.get_shock_prod_presentation_report()
	if (
		not bool(discharge.get("visible", false))
		or not bool(discharge.get("connected", false))
		or str(discharge.get("target_id", "")) != HOSTILE_ID
		or not is_equal_approx(float(discharge.get("range_pixels", 0.0)), ShockProdController.ATTACK_RANGE_PX)
		or not is_equal_approx(float(discharge.get("arc_half_angle_degrees", 0.0)), ShockProdController.ATTACK_HALF_ANGLE_DEGREES)
	):
		_fail("Real Space/USE hit did not produce authoritative range/target feedback: %s." % discharge)
		return

	print("Checkpoint Shock Prod smoke passed: checkpoint=expansion_14_start scanner_switch_cancel=true default=Scanner selected=Shock_prod range=72 cone=35 discharge=visible_connected hit=1 recoil=44 health=2/3 phase=recovery capacitor=true.")
	_main.get_tree().quit()


func _press_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_main._unhandled_input(event)


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
		and _action_has_key("active_tool_use", KEY_SPACE)
		and not _action_has_key("active_tool_use", KEY_Q)
	)


func _action_has_key(action: StringName, expected_key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == expected_key or key_event.physical_keycode == expected_key:
				return true
	return false


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for record in records:
		if str(record.get("id", "")) == record_id:
			return record
	return {}


func _fail(message: String) -> void:
	push_error(message)
	_main.get_tree().quit(1)
