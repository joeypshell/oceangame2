extends RefCounted

const MobileTestControls := preload("res://scripts/main/mobile_test_controls.gd")

const KITE_ID := "spark_ray_juvenile_01"
const EAST_GATE_ID := "lower_right_east_current_gate"
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
	_camera.name = "LivingExpedition06CaptureCamera"
	_camera.position_smoothing_enabled = false
	_main.add_child(_camera)
	_camera.make_current()
	_mobile_controls = MobileTestControls.new()
	_mobile_controls.name = "LivingExpedition06CaptureMobileControls"
	_mobile_controls.force_visible = true
	_main.add_child(_mobile_controls)
	_mobile_controls.visible = false


func capture_pair(capture_dir: String, state_id: String, camera_test: Dictionary, expectation: Dictionary) -> bool:
	for spec in CAPTURE_SIZES:
		var canvas_size: Vector2i = spec["canvas_size"]
		var touch_visible := bool(spec["touch"])
		_main.get_window().mode = Window.MODE_WINDOWED
		_main.get_window().size = spec["window_size"]
		await _main.get_tree().process_frame
		_mobile_controls.set_context_mode("dive")
		_mobile_controls.visible = touch_visible
		_layout_huds(canvas_size, touch_visible)
		_frame_camera(camera_test, touch_visible)
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


func _frame_camera(camera_test: Dictionary, touch_visible: bool) -> void:
	var tile_size := float(_main._world.tile_size)
	var zoom := float(camera_test.get("zoom", 0.62))
	var camera_id := str(camera_test.get("id", ""))
	if touch_visible:
		zoom *= 0.62 if camera_id == "living_expedition_06_approach_review_01" else 0.90
	_camera.zoom = Vector2(zoom, zoom)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_main._world.map_pixel_size.x)
	_camera.limit_bottom = int(_main._world.map_pixel_size.y)
	var camera_position := Vector2(
		float(camera_test.get("center_x", 0.0)) * tile_size,
		float(camera_test.get("center_y", 0.0)) * tile_size
	)
	if touch_visible:
		camera_position.y = _mobile_focus_y(camera_id) - 268.0 / zoom
	_camera.position = camera_position
	_camera.make_current()
	_camera.force_update_scroll()


func _mobile_focus_y(camera_id: String) -> float:
	var nursery: Dictionary = _main._world.get_signal_reef_nursery_report()
	if camera_id == "living_expedition_06_anchor_review_01":
		return _gate_center().y
	if camera_id == "living_expedition_06_guardian_review_01":
		return (nursery.get("pressure_center", Vector2.ZERO) as Vector2).y
	if camera_id in ["living_expedition_06_pending_return_review_01", "living_expedition_06_restored_review_01"]:
		return (nursery.get("nursery_center", Vector2.ZERO) as Vector2).y
	return (nursery.get("school_center", Vector2.ZERO) as Vector2).y


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
	if _main._status_label == null or not _main._status_label.visible or _main._status_label.text.find("Kite") == -1:
		return _fail("status feedback omitted Kite's local context")
	var viewport := _viewport_rect()
	var cargo: Dictionary = _main._held_cargo_hud.get_test_report()
	if not _bounded(cargo.get("rect", Rect2()), viewport):
		return _fail("cargo/equipment HUD escaped the canvas")
	var equipment: Dictionary = cargo.get("equipment", {})
	if not _equipment_has(equipment, "propulsion_fins") or not _equipment_has(equipment, "dive_light_1"):
		return _fail("equipment context omitted Fins or Dive Light")
	var tools: Dictionary = _main._active_tool_hud.get_test_report()
	var owned_tools: Array = tools.get("owned_tool_ids", [])
	if not owned_tools.is_empty() and (not bool(tools.get("visible", false)) or not _bounded(tools.get("rect", Rect2()), viewport)):
		return _fail("active-tool HUD was not readable inside the canvas")
	var companion: Dictionary = _main._companion_sortie.report()
	if (
		str(companion.get("active_species_id", "")) != "spark_ray"
		or str(companion.get("identity", {}).get("individual_id", "")) != KITE_ID
		or str(companion.get("identity", {}).get("callsign", "")) != "Kite"
	):
		return _fail("active companion identity drifted")
	if touch_visible:
		var hud_rects := [cargo.get("rect", Rect2())]
		if not owned_tools.is_empty():
			hud_rects.append(tools.get("rect", Rect2()))
		for rect in hud_rects:
			if not _avoids_touch_controls(rect):
				return _fail("HUD overlapped landscape-mobile controls")
	return true


func _verify_state(kind: String, touch_visible: bool) -> bool:
	var nursery: Dictionary = _main._world.get_signal_reef_nursery_report()
	var state := str(nursery.get("state", ""))
	match kind:
		"approach":
			return _expect(
				state == "unresolved"
				and int(nursery.get("school_member_count", 0)) == 5
				and _passive_contract(nursery)
				and _verify_subjects(kind, touch_visible),
				"approach did not frame the passive school, pressure, and nursery"
			)
		"anchor_action":
			var anchor: Dictionary = _main._companion_sortie.adaptation_runtime().report()
			return _expect(
				state == "unresolved"
				and bool(anchor.get("active", false))
				and float(anchor.get("progress", 0.0)) > 0.0
				and float(anchor.get("progress", 1.0)) < 1.0
				and bool(_main._companion_sortie.companion().report().get("anchor_braced", false))
				and _verify_subjects(kind, touch_visible),
				"Anchor action was not visibly in progress"
			)
		"guardian_action":
			var guardian: Dictionary = _main._companion_sortie.guardian_pulse_runtime().report()
			return _expect(
				state == "guardian_active"
				and str(guardian.get("last_result", "")) == "hit"
				and int(guardian.get("last_damage", -1)) == 0
				and float(nursery.get("shelter_progress", 0.0)) > 0.0
				and _verify_subjects(kind, touch_visible),
				"Guardian action did not show displacement without damage"
			)
		"immediate_sheltering":
			return _expect(
				state == "anchor_active"
				and float(nursery.get("shelter_progress", 0.0)) > 0.0
				and float(nursery.get("shelter_progress", 1.0)) < 1.0
				and _verify_subjects(kind, touch_visible),
				"Anchor lee did not show the school moving to shelter"
			)
		"pending_return":
			return _expect(
				state == "sheltered_pending_return"
				and _main._status_label.text.find("surface boat") != -1
				and _verify_subjects(kind, touch_visible),
				"pending return did not show sheltered wildlife and boat guidance"
			)
		"restored_next_day":
			return _expect(
				state == "restored"
				and int(nursery.get("school_member_count", 0)) == 7
				and not _command_ids().has("anchor_brace")
				and not _command_ids().has("guardian_pulse_action")
				and _verify_subjects(kind, touch_visible),
				"restored nursery did not show seven skates and no repeat action"
			)
	return _fail("unknown capture state %s" % kind)


func _passive_contract(nursery: Dictionary) -> bool:
	return (
		bool(nursery.get("passive", false))
		and not bool(nursery.get("bondable", true))
		and not bool(nursery.get("collectible", true))
		and not bool(nursery.get("harvestable", true))
		and not bool(nursery.get("damaging", true))
		and (nursery.get("reward_ids", []) as Array).is_empty()
	)


func _verify_subjects(kind: String, touch_visible: bool) -> bool:
	var nursery: Dictionary = _main._world.get_signal_reef_nursery_report()
	var companion = _main._companion_sortie.companion()
	var points := {"diver": _main._player.global_position, "Kite": companion.global_position}
	match kind:
		"approach":
			points["school"] = nursery.get("school_center", Vector2.ZERO)
			points["pressure"] = nursery.get("pressure_center", Vector2.ZERO)
			points["nursery"] = nursery.get("nursery_center", Vector2.ZERO)
		"anchor_action":
			points["east current"] = _gate_center()
		"guardian_action":
			points["school"] = nursery.get("school_center", Vector2.ZERO)
			points["pressure"] = nursery.get("pressure_center", Vector2.ZERO)
		"immediate_sheltering", "pending_return", "restored_next_day":
			points["school"] = nursery.get("school_center", Vector2.ZERO)
			points["nursery"] = nursery.get("nursery_center", Vector2.ZERO)
	var safe_rect := _viewport_rect().grow(-18.0)
	var blocked_rects := _hud_rects()
	for label in points:
		var screen_position: Vector2 = _main.get_viewport().get_canvas_transform() * (points[label] as Vector2)
		if not safe_rect.has_point(screen_position):
			return _fail("%s escaped the %s frame: %s" % [label, kind, str(screen_position)])
		for rect in blocked_rects:
			if (rect as Rect2).has_point(screen_position):
				return _fail("%s was hidden by a HUD in %s" % [label, kind])
		if touch_visible and _point_under_touch_control(screen_position):
			return _fail("%s was hidden by mobile controls in %s at %s; controls=%s" % [
				label,
				kind,
				str(screen_position),
				str(_mobile_controls.get_test_report()),
			])
	return true


func _gate_center() -> Vector2:
	for gate in _main._world.get_current_gates():
		if str((gate as Dictionary).get("id", "")) == EAST_GATE_ID:
			return (gate as Dictionary).get("center", Vector2.ZERO)
	return Vector2.ZERO


func _command_ids() -> Array[String]:
	var ids: Array[String] = []
	for command in _main._companion_sortie.control_runtime().report().get("context_commands", []):
		ids.append(str((command as Dictionary).get("id", "")))
	return ids


func _equipment_has(report: Dictionary, equipment_id: String) -> bool:
	return (report.get("owned_items", []) as Array).any(
		func(value): return str((value as Dictionary).get("id", "")) == equipment_id
	)


func _hud_rects() -> Array[Rect2]:
	return [
		_main._held_cargo_hud.get_test_report().get("rect", Rect2()),
		_main._active_tool_hud.get_test_report().get("rect", Rect2()),
	]


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
	print("Saved Living Expedition 06 capture: %s" % ProjectSettings.globalize_path(output_path))
	return true


func _expect(condition: bool, message: String) -> bool:
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	push_error("Living Expedition 06 capture failed: %s." % message)
	_main.get_tree().quit(1)
	return false
