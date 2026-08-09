extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const LivingExpedition04Capture := preload("res://scripts/main/captures/living_expedition_04_capture.gd")
const CAPTURE_DIR := "res://visual_captures/living_expedition_04"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame
	var capture := LivingExpedition04Capture.new(main)
	await capture.capture_and_quit(CAPTURE_DIR)
