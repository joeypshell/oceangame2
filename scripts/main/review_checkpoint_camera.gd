extends Node

# Only attached to LE07 field checkpoints. Normal play and all older fixtures
# keep their existing camera; this node dies with the review player on reload.
func _ready() -> void:
	get_window().size_changed.connect(_frame)
	_frame()


func _frame() -> void:
	var camera := get_parent().get_node("Camera2D") as Camera2D
	var logical := get_viewport().get_visible_rect().size
	var mobile := DisplayServer.is_touchscreen_available() or get_window().size.x < 900
	var focus := Vector2(900, 500) if not mobile else Vector2(650, 555)
	camera.offset = (logical * 0.5 - focus) / camera.zoom
	camera.reset_smoothing()
	camera.force_update_scroll()
