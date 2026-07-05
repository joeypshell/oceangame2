extends CharacterBody2D

@export var swim_speed := 220.0
@export var acceleration := 900.0
@export var deceleration := 1200.0


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction += _wasd_vector()
	if direction.length() > 1.0:
		direction = direction.normalized()

	var target_velocity := direction * swim_speed
	var change_rate := acceleration if direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(target_velocity, change_rate * delta)
	move_and_slide()

	if direction.x != 0.0:
		scale.x = 1.0 if direction.x > 0.0 else -1.0


func set_camera_limits(world_rect: Rect2) -> void:
	var camera := $Camera2D as Camera2D
	camera.limit_left = int(world_rect.position.x)
	camera.limit_top = int(world_rect.position.y)
	camera.limit_right = int(world_rect.end.x)
	camera.limit_bottom = int(world_rect.end.y)


func _wasd_vector() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A):
		x -= 1.0
	if Input.is_key_pressed(KEY_D):
		x += 1.0
	if Input.is_key_pressed(KEY_W):
		y -= 1.0
	if Input.is_key_pressed(KEY_S):
		y += 1.0
	return Vector2(x, y)
