extends RefCounted

const BASE_PUSH_SPEED := 160.0
const DEFAULT_LABEL := "Strong current"

var _current_prompt := ""
var _blocking_gate := {}


func reset() -> void:
	_current_prompt = ""
	_blocking_gate = {}


func current_prompt() -> String:
	return _current_prompt


func blocking_gate() -> Dictionary:
	return _blocking_gate


func update(world, player, has_upgrade: Callable, delta: float) -> Dictionary:
	reset()
	if world == null or player == null or not world.has_method("get_current_gate_at"):
		return {}

	var gate: Dictionary = world.get_current_gate_at(player.global_position)
	if gate.is_empty():
		return {}

	var upgrade_id := str(gate.get("required_upgrade_id", "")).strip_edges()
	if upgrade_id.is_empty() or has_upgrade.call(upgrade_id):
		return {"inside": true, "blocked": false, "id": str(gate.get("id", "current_gate"))}

	_blocking_gate = gate
	var push_vector := _direction_vector(str(gate.get("current_direction", "")))
	var strength := maxf(0.0, float(gate.get("current_strength", 1.0)))
	if push_vector != Vector2.ZERO and delta > 0.0:
		player.global_position += push_vector * BASE_PUSH_SPEED * strength * delta

	_current_prompt = "%s - need %s" % [_display_label(gate), _upgrade_label(upgrade_id)]
	return {
		"inside": true,
		"blocked": true,
		"id": str(gate.get("id", "current_gate")),
		"direction": str(gate.get("current_direction", "")),
		"strength": strength,
		"required_upgrade_id": upgrade_id,
		"prompt": _current_prompt,
	}


func gate_blocks_position(world, position: Vector2, has_upgrade: Callable) -> Dictionary:
	if world == null or not world.has_method("get_current_gate_at"):
		return {}
	var gate: Dictionary = world.get_current_gate_at(position)
	if gate.is_empty():
		return {}
	var upgrade_id := str(gate.get("required_upgrade_id", "")).strip_edges()
	if upgrade_id.is_empty() or has_upgrade.call(upgrade_id):
		return {}
	return gate


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
	return Vector2.ZERO


func _display_label(gate: Dictionary) -> String:
	var label := str(gate.get("current_gate_label", DEFAULT_LABEL)).strip_edges()
	if label.is_empty():
		label = DEFAULT_LABEL
	return label.replace("_", " ")


func _upgrade_label(upgrade_id: String) -> String:
	return upgrade_id.replace("_", " ")
