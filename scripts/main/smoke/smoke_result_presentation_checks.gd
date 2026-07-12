extends "res://scripts/main/smoke/smoke_check_base.gd"

const CONNECTOR_ID := "lower_left_loop_connector"
const PAYOFF_TARGET_ID := "slice_04_destination_cache"
const RELAY_RESULT_LABEL := "Lower-left relay investigated"
const FINAL_RESULT_LABEL := "Final dive signal found"
const FINAL_CUE_LABEL := "Final dive signal locked"


func _smoke_pass_26_result_presentation_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("loaded unexpected origin map: %s" % _world.map_id)
		return

	if not _complete_route_outcome_review_state():
		_fail("could not build default-slice completed result state")
		return
	_assert_line_order(
		_result_text(),
		PackedStringArray([
			"Expedition complete",
			"Objective: Relay trail complete",
			"Next dive: Investigate east current",
			"Route: Deep route",
			"Score ",
			"Salvage score ",
			"Oxygen bonus +",
			"Best ",
			"Salvage ",
			"Wallet ",
			"Oxygen ",
			"Press R to retry",
		]),
		"default completed result"
	)

	_reset_run()
	_prepare_final_dive_destination()
	if _world.map_id != "production_slice_04":
		_fail("loaded wrong final-dive destination map: %s" % _world.map_id)
		return

	var target := _salvage_by_id(PAYOFF_TARGET_ID)
	if target.is_empty():
		_fail("did not find final-dive payoff target %s" % PAYOFF_TARGET_ID)
		return
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = target["center"]
	if not _collect_salvage_for_smoke(target):
		_fail("did not collect final-dive payoff target %s" % PAYOFF_TARGET_ID)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)

	_main._run_complete = true
	_main._sortie_state.failed = false
	_main._update_result_panel()
	_assert_line_order(
		_result_text(),
		PackedStringArray([
			"Expedition complete",
			RELAY_RESULT_LABEL,
			FINAL_RESULT_LABEL,
			FINAL_CUE_LABEL,
			"Score ",
			"Salvage score ",
			"Oxygen bonus +",
			"Best ",
			"Salvage ",
			"Wallet ",
			"Oxygen ",
			"Press R to retry",
		]),
		"final-dive completed result"
	)

	_main._run_complete = false
	_main._sortie_state.failed = true
	_main._update_result_panel()
	var failure_text := _result_text()
	if failure_text.find(FINAL_RESULT_LABEL) != -1 or failure_text.find(FINAL_CUE_LABEL) != -1 or failure_text.find(RELAY_RESULT_LABEL) != -1:
		_fail("failed result leaked completion text: %s" % failure_text)
		return
	_assert_line_order(
		failure_text,
		PackedStringArray([
			"Expedition failed",
			"Score ",
			"Salvage score ",
			"Oxygen bonus +",
			"Best ",
			"Salvage ",
			"Wallet ",
			"Oxygen depleted",
			"Press R to retry",
		]),
		"failed result"
	)

	_reset_run()
	_main._update_result_panel()
	if (_result_panel != null and _result_panel.visible) or not _result_text().is_empty():
		_fail("reset left result presentation visible: %s" % _result_text())
		return

	print("Pass 26 result presentation smoke passed: default objective order, final-dive cue order, failure suppression, and reset cleanup verified.")
	get_tree().quit()


func _prepare_final_dive_destination() -> void:
	var connector := _connector_by_id(CONNECTOR_ID)
	if connector.is_empty():
		_fail("did not find connector %s" % CONNECTOR_ID)
		return
	if not _prepare_profile_capability("current_stabilizer"):
		return
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = connector["center"]
	if not _main._try_world_connector_transition():
		_fail("did not trigger connector transition")


func _assert_line_order(result_text: String, expected_prefixes: PackedStringArray, label: String) -> void:
	var lines := result_text.split("\n", false)
	var previous_index := -1
	for prefix in expected_prefixes:
		var index := _line_index_after(lines, str(prefix), previous_index)
		if index == -1:
			_fail("%s missing line beginning with %s: %s" % [label, str(prefix), result_text])
			return
		if index <= previous_index:
			_fail("%s line order moved backwards at %s: %s" % [label, str(prefix), result_text])
			return
		previous_index = index


func _line_index_after(lines: PackedStringArray, prefix: String, previous_index: int) -> int:
	for index in range(previous_index + 1, lines.size()):
		if str(lines[index]).begins_with(prefix):
			return index
	return -1


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _fail(message: String) -> void:
	push_error("Pass 26 result presentation smoke %s." % message)
	get_tree().quit(1)
