extends RefCounted

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
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
	_camera.name = "LivingExpedition02CaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "LivingExpedition02CaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(
	capture_dir: String,
	state_id: String,
	camera_test: Dictionary,
	ui_expectation := {}
) -> bool:
	for spec in CAPTURE_SIZES:
		_main.get_window().size = spec["window_size"]
		_mobile_controls.visible = bool(spec["touch"])
		_main._held_cargo_hud.layout_for_size(Vector2(spec["window_size"]))
		_frame_camera(camera_test)
		await _settle_frames()
		if not _verify_controls(bool(spec["touch"])):
			return false
		if not _verify_ui(ui_expectation, bool(spec["touch"])):
			return false
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, spec["canvas_size"]):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, spec["canvas_size"]):
			return _fail("%s rendered blank or wrong-sized image %s" % [state_id, str(image.get_size())])
		var filename := "production_level_01_%s_%s.png" % [state_id, str(spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func prepare_to_quit() -> void:
	Engine.time_scale = 1.0
	_main.get_window().size = Vector2i(1280, 720)
	_mobile_controls.visible = false
	await _settle_frames()


func _frame_camera(camera_test: Dictionary) -> void:
	var tile_size := float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.55))
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


func _verify_controls(touch_visible: bool) -> bool:
	if not touch_visible:
		return true
	var report: Dictionary = _mobile_controls.get_test_report()
	var viewport_rect := Rect2(Vector2.ZERO, _main.get_viewport().get_visible_rect().size)
	if not bool(report.get("enabled", false)):
		return _fail("landscape-mobile capture omitted touch controls")
	var stick_rect: Rect2 = report.get("stick_rect", Rect2())
	if not stick_rect.has_area() or not viewport_rect.grow(1.0).encloses(stick_rect):
		return _fail("landscape-mobile movement control escaped the visible canvas")
	var command_rects: Dictionary = report.get("command_rects", {})
	if not command_rects.has(&"bond"):
		return _fail("landscape-mobile capture omitted the contextual BOND control")
	for command_id in command_rects:
		var rect: Rect2 = command_rects[command_id]
		if not rect.has_area() or not viewport_rect.grow(1.0).encloses(rect):
			return _fail("landscape-mobile %s control escaped the visible canvas" % str(command_id))
	return true


func _verify_ui(expectation: Dictionary, touch_visible: bool) -> bool:
	var kind := str(expectation.get("kind", ""))
	if kind.is_empty():
		return true
	var report := _ui_report(kind)
	if not bool(report.get("visible", false)):
		return _fail("expected companion %s was not visible" % kind)
	var rect: Rect2 = report.get("rect", Rect2())
	var viewport_rect := Rect2(Vector2.ZERO, _main.get_viewport().get_visible_rect().size)
	if not rect.has_area() or not viewport_rect.grow(1.0).encloses(rect):
		return _fail("companion %s escaped the visible canvas: %s" % [kind, str(rect)])
	if expectation.has("rows") and (report.get("rows", []) as Array).size() != int(expectation["rows"]):
		return _fail("companion habitat showed the wrong individual count")
	if expectation.has("active_id") and str(report.get("active_individual_id", "")) != str(expectation["active_id"]):
		return _fail("companion habitat showed the wrong next-sortie selection")
	if expectation.has("selection_open") and bool(report.get("selection_open", false)) != bool(expectation["selection_open"]):
		return _fail("companion habitat selection state was incorrect")
	if touch_visible and not _ui_avoids_touch_controls(rect):
		return _fail("companion %s overlapped landscape-mobile touch controls" % kind)
	return true


func _ui_report(kind: String) -> Dictionary:
	var sortie: Dictionary = _main._companion_sortie.report()
	var control: Dictionary = sortie.get("control", {})
	match kind:
		"habitat":
			return (sortie.get("habitat", {}) as Dictionary).get("panel", {})
		"palette":
			return control.get("palette", {})
		"action_hud":
			return control.get("action_hud", {})
	return {}


func _ui_avoids_touch_controls(ui_rect: Rect2) -> bool:
	var controls: Dictionary = _mobile_controls.get_test_report()
	var stick_rect: Rect2 = controls.get("stick_rect", Rect2())
	if stick_rect.has_area() and ui_rect.intersects(stick_rect):
		return false
	for value in (controls.get("command_rects", {}) as Dictionary).values():
		var command_rect := value as Rect2
		if command_rect.has_area() and ui_rect.intersects(command_rect):
			return false
	return true


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
	for x_step in range(1, 8):
		for y_step in range(1, 8):
			var x := int(float(image.get_width() - 1) * float(x_step) / 8.0)
			var y := int(float(image.get_height() - 1) * float(y_step) / 8.0)
			colors[image.get_pixel(x, y).to_html(true)] = true
	return colors.size() >= 4


func _save_capture(capture_dir: String, filename: String, image: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s" % [capture_dir, filename]
	var error := image.save_png(output_path)
	if error != OK:
		return _fail("could not save %s (error %d)" % [output_path, error])
	print("Saved Living Expedition 02 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> bool:
	push_error("Living Expedition 02 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
