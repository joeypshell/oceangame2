extends RefCounted

const OUTPUT := "res://visual_captures/living_expedition_07"
const SIZES := [
	{"id": "1280x720", "window": Vector2i(1280, 720), "canvas": Vector2i(1280, 720), "touch": false},
	{"id": "mobile_844x390", "window": Vector2i(844, 390), "canvas": Vector2i(693, 390), "touch": true},
]
var main
var driver
var camera: Camera2D
var records: Array = []


func _init(main_node, review_driver) -> void:
	main = main_node
	driver = review_driver
	camera = Camera2D.new()
	camera.name = "MarlReviewCamera"
	main.add_child(camera)
	camera.limit_top = 0
	camera.make_current()


func capture(state: String) -> void:
	for spec in SIZES:
		main.get_window().mode = Window.MODE_WINDOWED
		main.get_window().size = spec["window"]
		await settle()
		var touch: bool = spec["touch"]
		var mobile = main.get_node("MobileTestControls")
		mobile.visible = touch
		var logical_size: Vector2 = main.get_viewport().get_visible_rect().size
		main._active_tool_hud.set_mobile_controls_visible(touch)
		main._active_tool_hud.layout_for_size(logical_size)
		main._held_cargo_hud.layout_for_size(logical_size)
		var source_camera := {}
		for test in main._world.camera_tests:
			if test.get("id") == "living_expedition_07_pin_review_01": source_camera = test
		driver.expect(not source_camera.is_empty(), "missing authored review camera")
		camera.zoom = Vector2.ONE * (0.55 if touch else float(source_camera.get("zoom", 0.7)))
		var focus: Vector2 = Vector2(float(source_camera.get("center_x", 123)), float(source_camera.get("center_y", 77))) * main._world.tile_size
		if state == "night_choice":
			focus = main._world.get_entry_position("surface_boat_entry")
		# Layout and camera coordinates are logical viewport units, not output PNG
		# pixels. Keep one fixed framing per size for all before/after field states.
		var screen_focus := Vector2(960, 450) if not touch else Vector2(650, 550)
		camera.global_position = focus - (screen_focus - logical_size * 0.5) / camera.zoom
		camera.force_update_scroll()
		await settle()
		var evidence := _evidence(state, touch)
		var image: Image = main.get_viewport().get_texture().get_image()
		driver.expect(image.get_size() == spec["canvas"], "capture dimensions differ: %s" % image.get_size())
		var path := "%s/%s_%s.png" % [OUTPUT, state, spec["id"]]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
		driver.expect(image.save_png(path) == OK, "PNG write failed")
		evidence.merge({"state": state, "file": path.get_file(), "size": [image.get_width(), image.get_height()],
			"logical_size": [logical_size.x, logical_size.y],
			"checkpoint": main._review_checkpoint_id, "camera_id": "surface_boat_entry" if state == "night_choice" else source_camera.get("id"),
			"camera_position": [camera.global_position.x, camera.global_position.y], "zoom": camera.zoom.x,
			"baseline_accepted": false, "guidance": driver.guidance()})
		records.append(evidence)
		print("Captured LE07: " + path)
	main.get_node("MobileTestControls").visible = true


func _evidence(state: String, touch: bool) -> Dictionary:
	var viewport: Rect2 = main.get_viewport().get_visible_rect()
	var rectangles: Array[Rect2] = []
	var huds := {}
	for name in ["_held_cargo_hud", "_active_tool_hud"]:
		var hud = main.get(name)
		var report: Dictionary = hud.get_test_report()
		if report.get("visible", true):
			var rect: Rect2 = report.get("rect", Rect2())
			driver.expect(viewport.grow(1).encloses(rect), "HUD outside canvas: " + name)
			rectangles.append(rect)
			huds[name] = _rect(rect)
	var panel = main._review_canvas.get_node("ReviewPanel")
	if panel.visible:
		var rect := Rect2(panel.global_position, panel.size)
		rectangles.append(rect)
		huds["status"] = _rect(rect)
	if touch:
		var controls: Dictionary = main.get_node("MobileTestControls").get_test_report()
		for id in controls["command_rects"]:
			var rect: Rect2 = controls["command_rects"][id]
			driver.expect(viewport.encloses(rect), "touch button outside canvas")
			for hud in rectangles:
				driver.expect(not hud.intersects(rect), "touch button overlapped HUD: " + str(id))
			huds[str(id)] = _rect(rect)
		# Include buttons after checking HUDs, not against each other.
		rectangles.append((controls["stick_rect"] as Rect2))
		for value in controls["command_rects"].values(): rectangles.append(value)
	var profile: Dictionary = main._anomaly_survey.profile_state().companion_report()["individual"]
	var evidence := {"individual_id": profile["individual_id"], "adaptation_id": profile["selected_adaptation_id"],
		"hud_bounds": huds, "subjects": {}, "map_id": main._world.map_id, "main_scene": "res://scenes/main/Main.tscn",
		"refuge": main._world.burrow_refuge_presentation().report()}
	if state == "night_choice":
		var rect := Rect2(main._result_panel.global_position, main._result_panel.size)
		driver.expect(viewport.encloses(rect), "night panel outside canvas: %s" % rect)
		for hud in rectangles:
			driver.expect(not hud.intersects(rect), "night panel overlaps another control")
		evidence["night_text"] = main._result_label.text
		evidence["night_bounds"] = _rect(rect)
	else:
		var marl = main._companion_sortie.companion()
		evidence["presentation"] = marl.get_node("Presentation").report()
		evidence["pin"] = driver.control().ground_pin_runtime().report()
		var subjects := {"Marl": marl.global_position, "diver": main._player.global_position,
			"refuge": main._world.burrow_refuge_presentation().target,
			"eel": main._hostiles.state_for(driver.EEL)["position"]}
		for id in subjects:
			var screen: Vector2 = main.get_viewport().get_canvas_transform() * subjects[id]
			var radius := Vector2(35, 26) if id == "Marl" else Vector2(22, 18)
			var rect := Rect2(screen - radius, radius * 2)
			driver.expect(viewport.encloses(rect), id + " outside frame")
			for hud in rectangles: driver.expect(not hud.intersects(rect), "%s obscured by HUD %s at %s" % [id, hud, rect])
			evidence["subjects"][id] = _rect(rect)
	return evidence


func write_manifest() -> void:
	var path := "%s/%s.json" % [OUTPUT, main._review_checkpoint_id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	driver.expect(file != null, "manifest write failed")
	if file != null:
		file.store_string(JSON.stringify({"baseline_accepted": false, "bounds_verified": driver.failures.is_empty(), "captures": records}, "  "))


func settle() -> void:
	RenderingServer.force_draw()
	for frame in range(4): await main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
