extends RefCounted

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
const MAP_ID := "production_level_01"
const HUD_SAFE_FOCUS_OFFSET_PX := 96.0
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
var _capture_label: String


func _init(main_node, capture_label := "Expansion 16") -> void:
	_main = main_node
	_capture_label = str(capture_label)
	_camera = Camera2D.new()
	_camera.name = "FocusedReviewCaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "FocusedReviewCaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(
	capture_dir: String,
	state_id: String,
	camera_test: Dictionary,
	allow_status_overlap := false,
	mobile_focus_shift_px := 0.0
) -> bool:
	for spec in CAPTURE_SIZES:
		var expected_size: Vector2i = spec["canvas_size"]
		var show_touch := bool(spec["touch"])
		_main.get_window().size = spec["window_size"]
		_mobile_controls.visible = show_touch
		_main._held_cargo_hud.layout_for_size(Vector2(spec["window_size"]))
		_frame_camera(camera_test, float(mobile_focus_shift_px) if show_touch else 0.0)
		await _settle_frames()
		if not _verify_layout(show_touch, bool(allow_status_overlap)):
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
		var map_id := str(_main._world.map_id) if _main._world != null else MAP_ID
		var filename := "%s_%s_%s.png" % [map_id, state_id, str(spec["suffix"])]
		if not _save_capture(capture_dir, filename, image):
			return false
	return true


func prepare_to_quit() -> void:
	_main.get_window().size = Vector2i(1280, 720)
	_mobile_controls.visible = false
	await _settle_frames()


func _verify_layout(touch_visible: bool, allow_status_overlap: bool) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, _main.get_viewport().get_visible_rect().size)
	var cargo_rect: Rect2 = _main._held_cargo_hud.get_test_report().get("rect", Rect2())
	var tool_rect: Rect2 = _main._active_tool_hud.get_test_report().get("rect", Rect2())
	var status_rect := Rect2(_main._status_label.global_position, _main._status_label.size)
	var status_visible: bool = _main._status_label.is_visible_in_tree()
	var equipment: Dictionary = _main._held_cargo_hud.get_test_report().get("equipment", {})
	var expected_gear_slots := 3 if touch_visible else 6
	if bool(equipment.get("compact", false)) != touch_visible or equipment.get("slots", []).size() != expected_gear_slots:
		_fail("gear layout did not match capture mode: %s" % str(equipment))
		return false
	var visible_hud_rects: Array[Rect2] = [cargo_rect, tool_rect]
	if status_visible:
		visible_hud_rects.append(status_rect)
	for rect in visible_hud_rects:
		if not viewport_rect.grow(1.0).encloses(rect):
			_fail("HUD escaped the capture canvas: %s" % str(rect))
			return false
	if cargo_rect.intersects(tool_rect):
		_fail("held cargo overlaps the active-tool HUD")
		return false
	if status_visible and not allow_status_overlap and cargo_rect.intersects(status_rect):
		_fail("held cargo/gear overlaps the status HUD: cargo=%s status=%s" % [cargo_rect, status_rect])
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
	for touch_rect in touch_rects:
		if (
			cargo_rect.intersects(touch_rect)
			or tool_rect.intersects(touch_rect)
			or (status_visible and not allow_status_overlap and status_rect.intersects(touch_rect))
		):
			_fail("landscape-mobile controls overlap status, cargo, or active tool")
			return false
	return true


func _frame_camera(camera_test: Dictionary, focus_shift_px: float) -> void:
	var tile_size: float = float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.5))
	var safe_offset_world := HUD_SAFE_FOCUS_OFFSET_PX / zoom
	_camera.zoom = Vector2(zoom, zoom)
	_camera.limit_left = -int(ceil(safe_offset_world))
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x) + int(ceil(maxf(focus_shift_px / zoom, 0.0)))
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_camera.position = Vector2(
		float(camera_test.get("center_x", 0.0)) * tile_size - safe_offset_world + focus_shift_px / zoom,
		float(camera_test.get("center_y", 0.0)) * tile_size
	)
	_camera.make_current()
	_camera.force_update_scroll()


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
	print("Saved %s capture: %s" % [_capture_label, ProjectSettings.globalize_path(output_path)])
	return true


func _fail(message: String) -> void:
	push_error("%s capture failed: %s." % [_capture_label, message])
	_main.get_tree().quit(1)
