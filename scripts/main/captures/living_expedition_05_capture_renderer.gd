extends RefCounted

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")

const RESCUE_ID := "silt_hound_rescue_01"
const TARGET_ID := "silt_hound_buried_titanium_01"
const MARL_ID := "silt_hound_juvenile_01"
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
	_camera.name = "LivingExpedition05CaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "LivingExpedition05CaptureMobileControls"
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
		await _settle_frames()
		if not _verify_controls(touch_visible) or not _verify_common_huds(touch_visible):
			return false
		if not _verify_state(str(expectation.get("kind", "")), touch_visible):
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
	_main.get_tree().paused = false
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
	if _main._companion_sortie != null and _main._companion_sortie._habitat != null:
		_main._companion_sortie._habitat.layout_for_size(Vector2(canvas_size))


func _frame_camera(camera_test: Dictionary) -> void:
	var tile_size := float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.62))
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
	if not _bounded(report.get("stick_rect", Rect2()), viewport_rect):
		return _fail("landscape-mobile movement control escaped the canvas")
	var command_rects: Dictionary = report.get("command_rects", {})
	for required_id in [&"bond", &"tool", &"use"]:
		if not command_rects.has(required_id):
			return _fail("landscape-mobile capture omitted %s" % str(required_id).to_upper())
	for command_id in command_rects:
		if not _bounded(command_rects[command_id], viewport_rect):
			return _fail("landscape-mobile %s control escaped the canvas" % str(command_id))
	return true


func _verify_common_huds(touch_visible: bool) -> bool:
	if _main._status_label == null or not _main._status_label.visible or _main._status_label.text.is_empty():
		return _fail("status feedback was not visible")
	var viewport := _viewport_rect()
	var cargo: Dictionary = _main._held_cargo_hud.get_test_report()
	if not _bounded(cargo.get("rect", Rect2()), viewport):
		return _fail("cargo/equipment HUD escaped the canvas")
	var tools: Dictionary = _main._active_tool_hud.get_test_report()
	if not bool(tools.get("visible", false)) or not _bounded(tools.get("rect", Rect2()), viewport):
		return _fail("active-tool HUD was not readable inside the canvas")
	if touch_visible:
		for rect in [cargo.get("rect", Rect2()), tools.get("rect", Rect2())]:
			if not _avoids_touch_controls(rect):
				return _fail("HUD overlapped landscape-mobile controls")
	return true


func _verify_state(kind: String, touch_visible: bool) -> bool:
	var source: Dictionary = _main._world.get_material_candidate_state(TARGET_ID)
	var rescue_states: Dictionary = _main._world.get_creature_rescue_report().get("states", {})
	var companion = _active_or_pending_companion(kind)
	match kind:
		"rescue_cutting":
			var rescue_report: Dictionary = _main._companion_rescue.report()
			return _expect(
				str(rescue_states.get(RESCUE_ID, "")) == "releasing"
				and float(rescue_report.get("release_progress", 0.0)) > 0.0
				and float(rescue_report.get("release_progress", 1.0)) < 1.0
				and _selected_tool() == "salvage_cutter"
				and _node_visible(RESCUE_ID),
				"partial physical rescue was not visible"
			)
		"pending_return":
			return _expect(
				str(rescue_states.get(RESCUE_ID, "")) == "pending"
				and bool(_main._companion_rescue.report().get("pending_companion_spawned", false))
				and companion != null
				and str(companion.report().get("species_id", "")) == "silt_hound",
				"pending Marl return state was not visible"
			)
		"habitat":
			return _verify_habitat(touch_visible)
		"following":
			return _verify_marl(companion, "follow") and _verify_subjects(kind, touch_visible)
		"command":
			return _verify_palette(touch_visible) and _verify_subjects(kind, touch_visible)
		"anticipating", "impact":
			return _expect(
				_verify_marl(companion, kind)
				and str(_excavate_report().get("state", "")) == kind
				and str(source.get("mound", {}).get("state", "")) == kind
				and _verify_subjects(kind, touch_visible),
				"%s phase was not physically readable" % kind
			)
		"opened":
			return _expect(
				bool(source.get("revealed", false))
				and bool(source.get("available", false))
				and str(source.get("mound", {}).get("state", "")) == "opened"
				and _node_visible(TARGET_ID)
				and _verify_subjects(kind, touch_visible),
				"opened mound did not expose the titanium pickup"
			)
		"cargo_full":
			var cargo: Dictionary = _main._held_cargo_hud.get_test_report()
			return _expect(
				int(cargo.get("used", -1)) == int(cargo.get("capacity", -2))
				and bool(source.get("available", false))
				and _node_visible(TARGET_ID)
				and _verify_subjects(kind, touch_visible),
				"cargo-full state did not preserve the visible pickup"
			)
		"material_held":
			var cargo: Dictionary = _main._held_cargo_hud.get_test_report()
			return _expect(
				bool(source.get("depleted", false))
				and str(source.get("mound", {}).get("state", "")) == "empty"
				and int(_main._material_runtime.held_quantities().get("titanium_scrap", 0)) == 1
				and _cargo_has(cargo, "titanium_scrap")
				and not _node_visible(TARGET_ID)
				and _verify_subjects(kind, touch_visible),
				"successful pickup did not read in the world and cargo HUD"
			)
	return _fail("unknown capture state %s" % kind)


func _verify_habitat(touch_visible: bool) -> bool:
	var panel: Dictionary = _main._companion_sortie.report().get("habitat", {}).get("panel", {})
	var rows: Array = panel.get("rows", [])
	var highlighted := int(panel.get("highlighted_index", -1))
	var highlighted_id := str((rows[highlighted] as Dictionary).get("individual_id", "")) if highlighted >= 0 and highlighted < rows.size() else ""
	return _expect(
		bool(panel.get("visible", false))
		and bool(panel.get("selection_open", false))
		and rows.size() == 3
		and highlighted_id == MARL_ID
		and _bounded(panel.get("rect", Rect2()), _viewport_rect())
		and (not touch_visible or _avoids_touch_controls(panel.get("rect", Rect2()))),
		"three-row habitat selection was not readable"
	)


func _verify_palette(touch_visible: bool) -> bool:
	var control: Dictionary = _main._companion_sortie.control_runtime().report()
	var palette: Dictionary = control.get("palette", {})
	var commands: Array = palette.get("commands", [])
	var index := int(palette.get("selected_index", -1))
	var selected := str((commands[index] as Dictionary).get("id", "")) if index >= 0 and index < commands.size() else ""
	return _expect(
		bool(palette.get("visible", false))
		and selected == "excavate"
		and _bounded(palette.get("rect", Rect2()), _viewport_rect())
		and (not touch_visible or _avoids_touch_controls(palette.get("rect", Rect2()))),
		"BOND palette did not visibly select Excavate"
	)


func _verify_marl(companion, expected_state: String) -> bool:
	if companion == null:
		return false
	var report: Dictionary = companion.report()
	var excavation: Dictionary = report.get("excavate", {})
	return (
		str(report.get("species_id", "")) == "silt_hound"
		and str(report.get("identity", {}).get("individual_id", "")) == MARL_ID
		and (expected_state == "follow" or str(excavation.get("state", "")) == expected_state)
	)


func _verify_subjects(kind: String, touch_visible: bool) -> bool:
	var companion = _main._companion_sortie.companion()
	var source: Dictionary = _main._world.get_material_candidate_state(TARGET_ID)
	var points := {"player": _main._player.global_position}
	if companion != null:
		points["Marl"] = companion.global_position
	if kind not in ["following"]:
		points["mound"] = source.get("candidate", {}).get("center", Vector2.ZERO)
	var safe_rect := _viewport_rect().grow(-18.0)
	var blocked_rects := _hud_rects(kind)
	for label in points:
		var screen_position: Vector2 = _main.get_viewport().get_canvas_transform() * (points[label] as Vector2)
		if not safe_rect.has_point(screen_position):
			return _fail("%s escaped the %s frame: %s" % [label, kind, str(screen_position)])
		for rect in blocked_rects:
			if (rect as Rect2).has_point(screen_position):
				return _fail("%s was hidden by a HUD in %s" % [label, kind])
		if touch_visible and _point_under_touch_control(screen_position):
			return _fail("%s was hidden by mobile controls in %s" % [label, kind])
	return true


func _hud_rects(kind: String) -> Array[Rect2]:
	var values: Array[Rect2] = [
		_main._held_cargo_hud.get_test_report().get("rect", Rect2()),
		_main._active_tool_hud.get_test_report().get("rect", Rect2()),
	]
	if kind == "command":
		values.append(_main._companion_sortie.control_runtime().report().get("palette", {}).get("rect", Rect2()))
	return values


func _active_or_pending_companion(kind: String):
	return _main._companion_rescue.pending_companion() if kind == "pending_return" else _main._companion_sortie.companion()


func _excavate_report() -> Dictionary:
	return _main._companion_sortie.control_runtime().report().get("excavate", {})


func _selected_tool() -> String:
	return str(_main._active_tool_hud.get_test_report().get("selected_tool_id", ""))


func _cargo_has(report: Dictionary, item_id: String) -> bool:
	return (report.get("items", []) as Array).any(func(value): return str((value as Dictionary).get("id", "")) == item_id and int((value as Dictionary).get("quantity", 0)) == 1)


func _node_visible(node_name: String) -> bool:
	var node := _main._world.find_child(node_name, true, false) as CanvasItem
	return node != null and node.visible


func _point_under_touch_control(point: Vector2) -> bool:
	var controls: Dictionary = _mobile_controls.get_test_report()
	if (controls.get("stick_rect", Rect2()) as Rect2).has_point(point):
		return true
	for value in (controls.get("command_rects", {}) as Dictionary).values():
		if (value as Rect2).has_point(point):
			return true
	return false


func _avoids_touch_controls(rect: Rect2) -> bool:
	var controls: Dictionary = _mobile_controls.get_test_report()
	if rect.intersects(controls.get("stick_rect", Rect2())):
		return false
	for value in (controls.get("command_rects", {}) as Dictionary).values():
		if rect.intersects(value as Rect2):
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
	print("Saved Living Expedition 05 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 05 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
