extends RefCounted

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
const MAP_ID := "production_level_01"
const RESULT_LABEL_CONTENT_WIDTH := 238.0
const CAPTURE_SIZES := [
	{
		"suffix": "1280x720",
		"window_size": Vector2i(1280, 720),
		"canvas_size": Vector2i(1280, 720),
		"touch": false,
	},
	{
		"suffix": "mobile_844x390",
		"window_size": Vector2i(844, 390),
		"canvas_size": Vector2i(693, 390),
		"touch": true,
	},
]

var _main
var _camera: Camera2D
var _mobile_controls


func _init(main_node) -> void:
	_main = main_node
	_camera = Camera2D.new()
	_camera.name = "Expansion15ExpeditionPlanningCaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "Expansion15CaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(
	capture_dir: String,
	state_id: String,
	camera_test: Dictionary,
	expect_planner: bool
) -> bool:
	for spec in CAPTURE_SIZES:
		var expected_size: Vector2i = spec["canvas_size"]
		var show_touch := bool(spec["touch"])
		_main.get_window().size = spec["window_size"]
		_mobile_controls.visible = show_touch
		_frame_camera(camera_test)
		await _refresh_result_panel_layout()
		await _settle_frames()
		if not _verify_layout(show_touch, expect_planner):
			return false
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, expected_size):
			_fail("capture %s rendered blank or wrong-sized image %s" % [
				state_id,
				str(image.get_size()),
			])
			return false
		var filename := "%s_%s_%s.png" % [MAP_ID, state_id, str(spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func prepare_to_quit() -> void:
	_main.get_window().size = Vector2i(1280, 720)
	_mobile_controls.visible = false
	await _settle_frames()


func _verify_layout(touch_visible: bool, expect_planner: bool) -> bool:
	var cargo_rect: Rect2 = _main._held_cargo_hud.get_test_report().get("rect", Rect2())
	var tool_rect: Rect2 = _main._active_tool_hud.get_test_report().get("rect", Rect2())
	var planner_report: Dictionary = _main._expedition_plan_panel.get_test_report()
	var planner_rect: Rect2 = planner_report.get("rect", Rect2())
	var result_rect := Rect2(
		_main._result_panel.global_position,
		_main._result_panel.size
	)
	var result_label_rect := Rect2(
		_main._result_label.global_position,
		_main._result_label.size
	)
	var viewport_rect := Rect2(
		Vector2.ZERO,
		_main.get_viewport().get_visible_rect().size
	)
	if cargo_rect.intersects(tool_rect):
		_fail("held cargo overlaps the active-tool HUD")
		return false
	if bool(planner_report.get("visible", false)) != expect_planner:
		_fail("planner visibility did not match capture state")
		return false
	if expect_planner and planner_rect.intersects(result_rect):
		_fail("planner overlaps the debrief summary")
		return false
	if expect_planner and planner_rect.intersects(cargo_rect):
		_fail("planner overlaps the cargo or equipment strip")
		return false
	if expect_planner and (
		not _main._result_label.is_visible_in_tree()
		or _main._result_label.text.strip_edges().is_empty()
		or not viewport_rect.grow(1.0).encloses(result_rect)
		or not result_rect.grow(1.0).encloses(result_label_rect)
	):
		_fail("debrief summary text is hidden or outside its panel: viewport=%s panel=%s label=%s" % [
			str(viewport_rect),
			str(result_rect),
			str(result_label_rect),
		])
		return false
	if not touch_visible:
		return true

	var controls: Dictionary = _mobile_controls.get_test_report()
	if not bool(controls.get("enabled", false)) or controls.get("command_rects", {}).size() != 9:
		_fail("landscape-mobile controls are incomplete")
		return false
	var touch_rects: Array[Rect2] = [controls.get("stick_rect", Rect2())]
	for rect in controls.get("command_rects", {}).values():
		touch_rects.append(rect)
	for rect in touch_rects:
		if cargo_rect.intersects(rect) or tool_rect.intersects(rect):
			_fail("landscape-mobile controls overlap cargo or active tool")
			return false
	for rect in controls.get("command_rects", {}).values():
		if expect_planner and (planner_rect.intersects(rect) or result_rect.intersects(rect)):
			_fail("landscape-mobile command overlaps planning or debrief content")
			return false
	return true


func _frame_camera(camera_test: Dictionary) -> void:
	var tile_size: float = float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.5))
	_camera.zoom = Vector2(zoom, zoom)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = Vector2(
		float(camera_test.get("center_x", 0.0)) * tile_size,
		float(camera_test.get("center_y", 0.0)) * tile_size
	)
	_camera.make_current()
	_camera.force_update_scroll()


func _refresh_result_panel_layout() -> void:
	_main._result_label.custom_minimum_size = Vector2(
		RESULT_LABEL_CONTENT_WIDTH,
		0.0
	)
	_main._result_label.size.x = RESULT_LABEL_CONTENT_WIDTH
	_main._result_label.update_minimum_size()
	await _main.get_tree().process_frame

	var margin := _main._result_label.get_parent() as Control
	if margin != null:
		margin.update_minimum_size()
		if margin is Container:
			(margin as Container).queue_sort()
	await _main.get_tree().process_frame

	_main._result_panel.update_minimum_size()
	_queue_container_sort(_main._result_panel)
	_main._result_panel.reset_size()
	await _main.get_tree().process_frame


func _queue_container_sort(node: Node) -> void:
	if node is Container:
		(node as Container).queue_sort()
	for child in node.get_children():
		_queue_container_sort(child)


func _settle_frames() -> void:
	RenderingServer.force_draw()
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _image_is_usable(image: Image, expected_size: Vector2i) -> bool:
	if image.get_size() != expected_size:
		return false
	var colors := {}
	var black_count := 0
	for x_step in range(1, 8):
		for y_step in range(1, 8):
			var x := int(float(image.get_width() - 1) * float(x_step) / 8.0)
			var y := int(float(image.get_height() - 1) * float(y_step) / 8.0)
			var color := image.get_pixel(x, y)
			colors[color.to_html(true)] = true
			if color.r < 0.01 and color.g < 0.01 and color.b < 0.01:
				black_count += 1
	return colors.size() >= 4 and black_count <= 4


func _save_capture(capture_dir: String, filename: String, image: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var error := image.save_png(output_path)
	if error != OK:
		_fail("could not save %s (error %d)" % [output_path, error])
		return false
	print("Saved Expansion 15 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> void:
	push_error("Expansion 15 expedition-planning capture failed: %s." % message)
	_main.get_tree().quit(1)
