extends RefCounted

const ReviewProgressionFixture := preload("res://scripts/main/review_progression_fixture.gd")
const CONNECTOR_ID := "lower_left_loop_connector"
const TARGET_ID := "slice_04_destination_cache"
const RELAY_RESULT_LABEL := "Lower-left relay investigated"
const FINAL_RESULT_LABEL := "Final dive signal found"
const FINAL_CUE_LABEL := "Final dive signal locked"
const CAPTURE_ZOOM := Vector2(0.9, 0.9)
const CAMERA_OFFSET := Vector2(-80, -48)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 26 result presentation capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Pass 26 result presentation capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	if not _transition_to_final_dive_destination():
		return

	var target := _salvage_by_id(TARGET_ID)
	if target.is_empty():
		push_error("Pass 26 result presentation capture requires target %s." % TARGET_ID)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	_main._player.global_position = target["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._collect_salvage_for_review_state(target)

	_main._player.global_position = _main._world.get_extraction_center()
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._run_complete = true
	_main._sortie_state.failed = false
	_main._update_status_label()
	_main._update_result_panel()
	_main.set_process(false)

	var result_text: String = _main._result_label.text if _main._result_label != null else ""
	if result_text.find(RELAY_RESULT_LABEL) == -1 or result_text.find(FINAL_RESULT_LABEL) == -1 or result_text.find(FINAL_CUE_LABEL) == -1:
		push_error("Pass 26 result presentation capture expected relay/final-dive result panel, got: %s" % result_text)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass26ResultPresentationCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._world.get_extraction_center() + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_pass_26_result_presentation.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 26 result presentation capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _transition_to_final_dive_destination() -> bool:
	var connector := _connector_by_id(CONNECTOR_ID)
	if connector.is_empty():
		push_error("Pass 26 result presentation capture missing connector %s." % CONNECTOR_ID)
		_main.get_tree().quit(1)
		return false

	var fins: Dictionary = ReviewProgressionFixture.complete_capability(_main, "propulsion_fins")
	if not bool(fins.get("ready", false)):
		push_error("Pass 26 result presentation capture could not prepare recipe-built fins: %s." % str(fins))
		_main.get_tree().quit(1)
		return false
	_main._hazard_interactions_enabled = false
	_main._player.global_position = connector["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	if not _main._try_world_connector_transition():
		push_error("Pass 26 result presentation capture did not trigger connector transition.")
		_main.get_tree().quit(1)
		return false
	if _main._world.map_id != "production_slice_04":
		push_error("Pass 26 result presentation capture loaded wrong destination map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return false
	return true


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _main._world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
