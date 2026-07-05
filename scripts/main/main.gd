extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const SCREENSHOT_PATH := "res://visual_baselines/001_greybox_in_engine.png"


func _ready() -> void:
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	world.load_greybox()

	var player := PLAYER_SCENE.instantiate()
	player.position = world.spawn_position
	add_child(player)

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))

	var user_args := OS.get_cmdline_user_args()
	var engine_args := OS.get_cmdline_args()
	if "--capture-greybox-screenshot" in user_args or "--capture-greybox-screenshot" in engine_args:
		_capture_screenshot_and_quit()


func _capture_screenshot_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://visual_baselines"))
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)
	print("Saved screenshot: %s" % ProjectSettings.globalize_path(SCREENSHOT_PATH))
	get_tree().quit()
