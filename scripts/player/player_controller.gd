extends CharacterBody2D

@export var swim_speed := 200.0
@export var acceleration := 620.0
@export var deceleration := 900.0

const LIGHT_CONE_OFFSET_X := 88.0

@onready var _body := $Body as Sprite2D
@onready var _light_cone := $LightCone as Sprite2D

var _facing_sign := 1.0


func _ready() -> void:
	_set_facing(_facing_sign)


func _physics_process(delta: float) -> void:
	swim_in_direction(_input_direction(), delta)


func swim_in_direction(direction: Vector2, delta: float) -> void:
	if direction.length() > 1.0:
		direction = direction.normalized()

	var target_velocity := direction * swim_speed
	var change_rate := acceleration if direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(target_velocity, change_rate * delta)
	move_and_slide()

	if direction.x != 0.0:
		_set_facing(1.0 if direction.x > 0.0 else -1.0)


func _input_direction() -> Vector2:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction += _wasd_vector()
	return direction


func set_camera_limits(world_rect: Rect2) -> void:
	var camera := $Camera2D as Camera2D
	camera.limit_left = int(world_rect.position.x)
	camera.limit_top = int(world_rect.position.y)
	camera.limit_right = int(world_rect.end.x)
	camera.limit_bottom = int(world_rect.end.y)


func reset_motion() -> void:
	velocity = Vector2.ZERO


func snap_camera() -> void:
	var camera := $Camera2D as Camera2D
	camera.reset_smoothing()


func get_facing_report() -> Dictionary:
	return {
		"root_scale_x": scale.x,
		"body_flip_h": _body.flip_h,
		"light_cone_position_x": _light_cone.position.x,
		"light_cone_scale_x": _light_cone.scale.x,
	}


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


func _set_facing(sign: float) -> void:
	_facing_sign = 1.0 if sign >= 0.0 else -1.0
	scale.x = 1.0
	_body.flip_h = _facing_sign < 0.0
	_light_cone.position.x = LIGHT_CONE_OFFSET_X * _facing_sign
	_light_cone.scale.x = _facing_sign
