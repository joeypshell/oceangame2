extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")

const HOSTILE_ID := "deep_cache_territorial_eel"
const HARVEST_ID := "deep_cache_eel_electrocyte_harvest"
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
	_camera.name = "LivingExpedition04CaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "LivingExpedition04CaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(capture_dir: String, state_id: String, camera_test: Dictionary, expectation: Dictionary) -> bool:
	for spec in CAPTURE_SIZES:
		var canvas_size: Vector2i = spec["canvas_size"]
		var touch_visible := bool(spec["touch"])
		_main.get_window().size = spec["window_size"]
		_mobile_controls.set_context_mode("dive")
		_mobile_controls.visible = touch_visible
		_layout_huds(canvas_size, touch_visible)
		_frame_camera(camera_test)
		if bool(expectation.get("replay_shock", false)):
			_replay_shock_discharge()
		await _settle_frames()
		if not _verify_controls(touch_visible) or not _verify_hud(expectation, touch_visible):
			return false
		if not _verify_state(expectation, touch_visible) or not _verify_world_subjects(touch_visible):
			return false
		var image: Image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, canvas_size):
			await _settle_frames()
			image = _main.get_viewport().get_texture().get_image()
		if not _image_is_usable(image, canvas_size):
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


func _layout_huds(canvas_size: Vector2i, touch_visible: bool) -> void:
	if _main._active_tool_hud != null:
		_main._active_tool_hud.set_mobile_controls_visible(touch_visible)
		_main._active_tool_hud.layout_for_size(Vector2(canvas_size))
	if _main._held_cargo_hud != null:
		_main._held_cargo_hud.layout_for_size(Vector2(canvas_size))


func _frame_camera(camera_test: Dictionary) -> void:
	var tile_size := float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.64))
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
	var stick_rect: Rect2 = report.get("stick_rect", Rect2())
	if not _bounded(stick_rect, viewport_rect):
		return _fail("landscape-mobile movement control escaped the canvas")
	var command_rects: Dictionary = report.get("command_rects", {})
	for required_id in [&"bond", &"tool", &"use"]:
		if not command_rects.has(required_id):
			return _fail("landscape-mobile capture omitted %s" % str(required_id).to_upper())
	for command_id in command_rects:
		if not _bounded(command_rects[command_id], viewport_rect):
			return _fail("landscape-mobile %s control escaped the canvas" % str(command_id))
	return true


func _verify_hud(expectation: Dictionary, touch_visible: bool) -> bool:
	if _main._status_label == null or not _main._status_label.visible or _main._status_label.text.is_empty():
		return _fail("encounter status feedback was not visible")
	var report: Dictionary = _main._active_tool_hud.get_test_report()
	var owned = report.get("owned_tool_ids", PackedStringArray())
	for tool_id in [
		ExpansionProfileState.SURVEY_SCANNER_CAPABILITY_ID,
		ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID,
		ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID,
	]:
		if not owned.has(tool_id):
			return _fail("active-tool hotbar omitted %s" % tool_id)
	if not bool(report.get("visible", false)) or not _bounded(report.get("rect", Rect2()), _viewport_rect()):
		return _fail("active-tool hotbar was not readable inside the canvas")
	if str(expectation.get("kind", "")) in ["shock_damage", "defeat_harvest"]:
		if str(report.get("selected_tool_id", "")) != ExpansionProfileState.SHOCK_PROD_CAPABILITY_ID:
			return _fail("Shock Prod evidence did not own the selected hotbar slot")
	if touch_visible and not _avoids_touch_controls(report.get("rect", Rect2())):
		return _fail("active-tool hotbar overlapped landscape-mobile controls")
	return true


func _verify_state(expectation: Dictionary, touch_visible: bool) -> bool:
	var kind := str(expectation.get("kind", ""))
	var hostile := _hostile_state()
	var companion = _main._companion_sortie.companion()
	if companion == null:
		return _fail("active companion was absent")
	var companion_report: Dictionary = companion.report()
	var hostile_visual: Dictionary = _hostile_visual()
	if not bool(hostile_visual.get("root_visible", false)) or not bool(hostile_visual.get("visible", false)):
		return _fail("eel or health bar was not visible")
	match kind:
		"guardian_opening":
			var guardian: Dictionary = _main._companion_sortie.guardian_pulse_runtime().report()
			var presentation: Dictionary = companion_report.get("presentation", {})
			return _expect(
				str(companion_report.get("identity", {}).get("individual_id", "")) == "spark_ray_juvenile_01"
				and str(guardian.get("last_result", "")) == "hit"
				and int(guardian.get("last_damage", -1)) == 0
				and bool(presentation.get("guardian_opening", false))
				and str(hostile.get("phase", "")) == "recovery"
				and int(hostile.get("health", 0)) == 3
				and _status_contains("Guardian Pulse opening"),
				"Guardian opening did not read as a non-damaging interruption"
			)
		"shock_damage":
			var discharge: Dictionary = _main._player.get_shock_prod_presentation_report()
			return _expect(
				bool(discharge.get("visible", false))
				and bool(discharge.get("connected", false))
				and int(hostile.get("health", 0)) == 1
				and int(hostile_visual.get("health", 0)) == 1
				and _status_contains("Shock prod"),
				"Shock Prod damage, discharge, or health feedback was not readable"
			)
		"defeat_harvest":
			var resource_states: Dictionary = _main._world.get_biological_resource_visual_report().get("states", {})
			return _expect(
				str(hostile.get("phase", "")) == "defeated"
				and int(hostile_visual.get("health", -1)) == 0
				and str(resource_states.get(HARVEST_ID, "")) == "available"
				and _status_contains("Harvesting electrocyte"),
				"defeat and explicit harvest availability were not readable"
			)
	return true


func _verify_world_subjects(touch_visible: bool) -> bool:
	var companion = _main._companion_sortie.companion()
	var points := {
		"player": _main._player.global_position,
		"eel": _hostile_state().get("position", Vector2.ZERO),
		"companion": companion.global_position,
	}
	var safe_rect := _viewport_rect().grow(-18.0)
	var hotbar_rect: Rect2 = _main._active_tool_hud.get_test_report().get("rect", Rect2())
	for label in points:
		var screen_position: Vector2 = _main.get_viewport().get_canvas_transform() * (points[label] as Vector2)
		if not safe_rect.has_point(screen_position):
			return _fail("%s escaped the encounter frame: %s" % [label, str(screen_position)])
		if hotbar_rect.has_point(screen_position):
			return _fail("%s was hidden by the active-tool hotbar" % label)
		if touch_visible and _point_under_touch_control(screen_position):
			return _fail("%s was hidden by landscape-mobile controls" % label)
	return true


func _replay_shock_discharge() -> void:
	var state := _hostile_state()
	_main._player.show_shock_prod_action({
		"discharged": true,
		"connected": true,
		"reason": "damaged",
		"id": HOSTILE_ID,
		"target_position": state.get("position", Vector2.ZERO),
		"attack_range_px": ShockProdController.ATTACK_RANGE_PX,
		"attack_half_angle_degrees": ShockProdController.ATTACK_HALF_ANGLE_DEGREES,
	}, _main._player.get_facing_sign())


func _hostile_state() -> Dictionary:
	return _main._hostiles.state_for(HOSTILE_ID)


func _hostile_visual() -> Dictionary:
	return _main._world.get_hostile_visual_report().get("health_bars", {}).get(HOSTILE_ID, {})


func _status_contains(text: String) -> bool:
	return _main._status_label.text.find(text) != -1


func _point_under_touch_control(point: Vector2) -> bool:
	var controls: Dictionary = _mobile_controls.get_test_report()
	var stick: Rect2 = controls.get("stick_rect", Rect2())
	if stick.has_point(point):
		return true
	for value in (controls.get("command_rects", {}) as Dictionary).values():
		if (value as Rect2).has_point(point):
			return true
	return false


func _avoids_touch_controls(rect: Rect2) -> bool:
	var controls: Dictionary = _mobile_controls.get_test_report()
	var stick: Rect2 = controls.get("stick_rect", Rect2())
	if stick.has_area() and rect.intersects(stick):
		return false
	for value in (controls.get("command_rects", {}) as Dictionary).values():
		var command_rect := value as Rect2
		if command_rect.has_area() and rect.intersects(command_rect):
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
	print("Saved Living Expedition 04 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 04 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
