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
	_camera.name = "LivingExpedition01CaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "LivingExpedition01CaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(capture_dir: String, state_id: String, camera_test: Dictionary, expected_ui := "") -> bool:
	for spec in CAPTURE_SIZES:
		_main.get_window().size = spec["window_size"]
		_mobile_controls.visible = bool(spec["touch"])
		_main._held_cargo_hud.layout_for_size(Vector2(spec["window_size"]))
		_frame_camera(camera_test)
		await _settle_frames()
		if not _verify_controls(bool(spec["touch"])) or not _verify_companion_ui(expected_ui):
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
	_main._companion_sortie.reset_control("capture_complete")
	_main.get_tree().paused = false
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
	var command_rects: Dictionary = report.get("command_rects", {})
	if not bool(report.get("enabled", false)) or not command_rects.has(&"bond"):
		return _fail("landscape-mobile capture omitted the contextual BOND control")
	var viewport_rect := Rect2(Vector2.ZERO, _main.get_viewport().get_visible_rect().size)
	if not viewport_rect.grow(1.0).encloses(command_rects[&"bond"]):
		return _fail("landscape-mobile BOND control escaped the visible canvas")
	return true


func _verify_companion_ui(expected_ui: String) -> bool:
	if expected_ui.is_empty():
		return true
	var control: Dictionary = _main._companion_sortie.control_runtime().report()
	var report: Dictionary = control.get("palette", {}) if expected_ui == "palette" else control.get("action_hud", {})
	if not bool(report.get("visible", false)):
		return _fail("expected companion %s was not visible" % expected_ui)
	var rect: Rect2 = report.get("rect", Rect2())
	var viewport_rect := Rect2(Vector2.ZERO, _main.get_viewport().get_visible_rect().size)
	if not rect.has_area() or not viewport_rect.grow(1.0).encloses(rect):
		return _fail("companion %s escaped the visible canvas: %s" % [expected_ui, str(rect)])
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
	print("Saved Living Expedition 01 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _fail(message: String) -> bool:
	push_error("Living Expedition 01 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
