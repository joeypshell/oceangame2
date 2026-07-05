extends Node2D

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")


func _ready() -> void:
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	world.load_greybox()

	var player := PLAYER_SCENE.instantiate()
	player.position = world.spawn_position
	add_child(player)

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(Rect2(Vector2.ZERO, world.map_pixel_size))
