extends SceneTree

const Main := preload("res://scenes/main/Main.tscn")
const Driver := preload("res://scripts/main/smoke/marl_review_driver.gd")
const Renderer := preload("res://scripts/main/captures/living_expedition_07_capture_renderer.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = Main.instantiate()
	root.add_child(main)
	for frame in range(4):
		await process_frame
		await physics_frame
	var driver := Driver.new(main)
	var renderer := Renderer.new(main, driver)
	driver.capture = Callable(renderer, "capture")
	await driver.run()
	renderer.write_manifest()
	paused = false
	for failure in driver.failures: push_error("LE07 capture: " + failure)
	main.queue_free()
	await process_frame
	driver.capture = Callable()
	quit(0 if driver.failures.is_empty() else 1)
