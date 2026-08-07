extends RefCounted

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
const SCANNER_TARGET_HALF_HEIGHT := 13.0
const SCANNER_CARD_GAP := 10.0
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
	_camera.name = "LivingExpedition03CaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "LivingExpedition03CaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(
	capture_dir: String,
	state_id: String,
	camera_test: Dictionary,
	expectation := {}
) -> bool:
	for spec in CAPTURE_SIZES:
		_main.get_window().size = spec["window_size"]
		_mobile_controls.set_context_mode(
			"debrief" if str(expectation.get("kind", "")) == "result_panel" else "dive"
		)
		_mobile_controls.visible = bool(spec["touch"])
		_main._held_cargo_hud.layout_for_size(Vector2(spec["window_size"]))
		_frame_camera(camera_test)
		await _settle_frames()
		if not _verify_controls(bool(spec["touch"])):
			return false
		if not _verify_state(expectation, bool(spec["touch"])):
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
	var viewport_rect := _viewport_rect()
	if not bool(report.get("enabled", false)):
		return _fail("landscape-mobile capture omitted touch controls")
	var command_rects: Dictionary = report.get("command_rects", {})
	var debrief := str(report.get("context_mode", "")) == "debrief"
	var stick_rect: Rect2 = report.get("stick_rect", Rect2())
	if debrief:
		if stick_rect.has_area() or command_rects.keys() != [&"tool", &"project", &"day", &"use"]:
			return _fail("landscape-mobile debrief controls did not use the compact context")
	else:
		if not _bounded(stick_rect, viewport_rect):
			return _fail("landscape-mobile movement control escaped the visible canvas")
		if not command_rects.has(&"bond"):
			return _fail("landscape-mobile capture omitted the contextual BOND control")
	for command_id in command_rects:
		var rect: Rect2 = command_rects[command_id]
		if not _bounded(rect, viewport_rect):
			return _fail("landscape-mobile %s control escaped the visible canvas" % str(command_id))
	return true


func _verify_state(expectation: Dictionary, touch_visible: bool) -> bool:
	var kind := str(expectation.get("kind", ""))
	match kind:
		"mica_reaction":
			var report: Dictionary = _mica_report().get("presentation", {})
			var palette: Dictionary = _main._companion_sortie.control_runtime().report().get("palette", {})
			return _expect(
				bool(report.get("ecology_interest_visible", false))
				and str(report.get("ecology_lead_label", "")) == "MICA FOUND A TRACE"
				and (report.get("ecology_lead_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO,
				"Mica reaction did not provide a readable directional lead"
			) and _expect(
				bool(palette.get("discovery_prompt_visible", false))
				and str(palette.get("discovery_prompt_text", "")).find("hold BOND") != -1,
				"Mica reaction omitted the screen-space BOND handoff"
			)
		"migration_filament":
			var report: Dictionary = _mica_report().get("presentation", {})
			return _expect(
				str(report.get("trace_state", "")) == "revealed"
				and int(report.get("trace_path_point_count", 0)) >= 2
				and (report.get("trace_movement_direction", Vector2.ZERO) as Vector2) != Vector2.ZERO,
				"migration evidence collapsed to a generic point cue"
			)
		"scanner_card":
			return _verify_scanner_card(touch_visible)
		"result_panel":
			return _verify_control_rect(_main._result_panel, "night result panel", touch_visible)
		"drift_projection":
			var report: Dictionary = _mica_report().get("drift_projection", {})
			return _expect(
				bool(report.get("visible", false)) and int(report.get("path_point_count", 0)) >= 2,
				"Read Drift projection was not visible"
			)
	return true


func _verify_scanner_card(touch_visible: bool) -> bool:
	var report: Dictionary = _main._player.get_scanner_presentation_report()
	if not bool(report.get("card_visible", false)) or not bool(report.get("held", false)):
		return _fail("held Scanner card was not visible")
	var size: Vector2 = report.get("card_size", Vector2.ZERO)
	var target: Vector2 = report.get("target_local_position", Vector2.ZERO)
	var local_rect := Rect2(
		target + Vector2(-size.x * 0.5, -SCANNER_TARGET_HALF_HEIGHT - size.y - SCANNER_CARD_GAP),
		size
	)
	var scanner_field := _main._player.get_node("ScannerField") as Node2D
	var screen_rect := _transformed_rect(scanner_field, local_rect)
	if not _bounded(screen_rect, _viewport_rect()):
		return _fail("held Scanner card escaped the visible canvas: %s" % str(screen_rect))
	if touch_visible and not _avoids_touch_controls(screen_rect):
		return _fail("held Scanner card overlapped landscape-mobile controls")
	return true


func _verify_control_rect(control: Control, label: String, touch_visible: bool) -> bool:
	if control == null or not control.visible:
		return _fail("%s was not visible" % label)
	var rect := control.get_global_rect()
	if not _bounded(rect, _viewport_rect()):
		return _fail("%s escaped the visible canvas: %s" % [label, str(rect)])
	if touch_visible and not _avoids_touch_controls(rect):
		return _fail("%s overlapped landscape-mobile controls" % label)
	return true


func _mica_report() -> Dictionary:
	var mica = _main._companion_sortie.companion()
	return mica.report() if mica != null else {}


func _transformed_rect(node: CanvasItem, local_rect: Rect2) -> Rect2:
	var transform := node.get_global_transform_with_canvas()
	var points := [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0.0),
		local_rect.end,
		local_rect.position + Vector2(0.0, local_rect.size.y),
	]
	var result := Rect2(transform * points[0], Vector2.ZERO)
	for point in points.slice(1):
		result = result.expand(transform * (point as Vector2))
	return result


func _avoids_touch_controls(ui_rect: Rect2) -> bool:
	var controls: Dictionary = _mobile_controls.get_test_report()
	var stick_rect: Rect2 = controls.get("stick_rect", Rect2())
	if stick_rect.has_area() and ui_rect.intersects(stick_rect):
		return false
	for value in (controls.get("command_rects", {}) as Dictionary).values():
		var command_rect := value as Rect2
		if command_rect.has_area() and ui_rect.intersects(command_rect):
			return false
	return true


func _viewport_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _main.get_viewport().get_visible_rect().size)


func _bounded(rect: Rect2, boundary: Rect2) -> bool:
	return rect.has_area() and boundary.grow(1.0).encloses(rect)


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
	print("Saved Living Expedition 03 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 03 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
