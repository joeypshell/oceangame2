extends SceneTree

const Main := preload("res://scenes/main/Main.tscn")
const Driver := preload("res://scripts/main/smoke/marl_review_driver.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = Main.instantiate()
	root.add_child(main)
	for frame in range(4):
		await process_frame
		await physics_frame
	var driver := Driver.new(main)
	await driver.run()
	paused = false
	for failure in driver.failures: push_error("LE07 checkpoint: " + failure)
	if driver.failures.is_empty():
		print("PASS: LE07 actual Main checkpoint=%s isolation=true clearance=true guidance=true real_controls=true" % main._review_checkpoint_id)
	main.queue_free()
	await process_frame
	quit(0 if driver.failures.is_empty() else 1)
