extends CharacterBody2D

@export var swim_speed := 200.0
@export var acceleration := 620.0
@export var deceleration := 900.0

const LIGHT_CONE_OFFSET_X := 88.0
const BASE_LIGHT_RANGE_SCALE := 1.0
const BASE_LIGHT_ALPHA := 0.38
const SWIM_FRAME_COUNT := 4
const SWIM_FRAME_RATE := 8.0

@onready var _body := $Body as Sprite2D
@onready var _light_cone := $LightCone as Sprite2D

var _facing_sign := 1.0
var _light_range_scale := BASE_LIGHT_RANGE_SCALE
var _light_alpha := BASE_LIGHT_ALPHA
var _swim_frame_time := 0.0
var _movement_disruption_seconds := 0.0


func _ready() -> void:
	_body.region_filter_clip_enabled = true
	_set_facing(_facing_sign)


func _physics_process(delta: float) -> void:
	if _movement_disruption_seconds > 0.0:
		_movement_disruption_seconds = maxf(0.0, _movement_disruption_seconds - maxf(0.0, delta))
		move_and_slide()
		_update_swim_animation(velocity.normalized(), delta)
		return
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
	_update_swim_animation(direction, delta)


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
	_movement_disruption_seconds = 0.0
	_update_swim_animation(Vector2.ZERO, 0.0)


func apply_knockback(direction: Vector2, force: float, disruption_seconds: float) -> void:
	var away_direction := direction.normalized()
	if away_direction == Vector2.ZERO:
		away_direction = Vector2.UP
	velocity = away_direction * maxf(0.0, force)
	_movement_disruption_seconds = maxf(0.0, disruption_seconds)


func movement_disruption_seconds() -> float:
	return _movement_disruption_seconds


func snap_camera() -> void:
	var camera := $Camera2D as Camera2D
	camera.reset_smoothing()


func apply_light_profile(range_scale: float, alpha: float) -> void:
	_light_range_scale = maxf(0.01, range_scale)
	_light_alpha = clampf(alpha, 0.0, 1.0)
	_set_facing(_facing_sign)


func get_facing_report() -> Dictionary:
	return {
		"root_scale_x": scale.x,
		"body_flip_h": _body.flip_h,
		"body_region_filter_clip_enabled": _body.region_filter_clip_enabled,
		"light_cone_position_x": _light_cone.position.x,
		"light_cone_scale_x": _light_cone.scale.x,
		"light_cone_range_scale": absf(_light_cone.scale.x),
		"light_cone_alpha": _light_cone.modulate.a,
		"body_frame": _body.frame,
		"body_hframes": _body.hframes,
	}


func get_facing_sign() -> float:
	return _facing_sign


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
	_light_cone.scale.x = _facing_sign * _light_range_scale
	var light_color := _light_cone.modulate
	light_color.a = _light_alpha
	_light_cone.modulate = light_color


func _update_swim_animation(direction: Vector2, delta: float) -> void:
	if direction == Vector2.ZERO and velocity.length() < 1.0:
		_swim_frame_time = 0.0
		_body.frame = 0
		return

	_swim_frame_time += delta * SWIM_FRAME_RATE
	_body.frame = int(floor(_swim_frame_time)) % SWIM_FRAME_COUNT
