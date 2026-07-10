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


func update(world, player, has_upgrade: Callable, has_capability: Callable, delta: float) -> Dictionary:
	reset()
	if world == null or player == null or not world.has_method("get_current_gate_at"):
		return {}

	var gate: Dictionary = world.get_current_gate_at(player.global_position)
	if gate.is_empty():
		return {}

	var requirement := _requirement(gate)
	if requirement.is_empty() or _has_requirement(requirement, has_upgrade, has_capability):
		return {"inside": true, "blocked": false, "id": str(gate.get("id", "current_gate"))}

	_blocking_gate = gate
	var push_vector := _direction_vector(str(gate.get("current_direction", "")))
	var strength := maxf(0.0, float(gate.get("current_strength", 1.0)))
	if push_vector != Vector2.ZERO and delta > 0.0:
		player.global_position += push_vector * BASE_PUSH_SPEED * strength * delta

	_current_prompt = block_prompt(gate)
	var result := {
		"inside": true,
		"blocked": true,
		"id": str(gate.get("id", "current_gate")),
		"direction": str(gate.get("current_direction", "")),
		"strength": strength,
		"requirement_kind": str(requirement["kind"]),
		"requirement_id": str(requirement["id"]),
		"prompt": _current_prompt,
	}
	result[str(requirement["field"])] = str(requirement["id"])
	return result


func gate_blocks_position(world, position: Vector2, has_upgrade: Callable, has_capability: Callable) -> Dictionary:
	if world == null or not world.has_method("get_current_gate_at"):
		return {}
	var gate: Dictionary = world.get_current_gate_at(position)
	if gate.is_empty():
		return {}
	var requirement := _requirement(gate)
	if requirement.is_empty() or _has_requirement(requirement, has_upgrade, has_capability):
		return {}
	return gate


func block_prompt(gate: Dictionary) -> String:
	var requirement := _requirement(gate)
	if requirement.is_empty():
		return ""
	return "%s - need %s" % [_display_label(gate), _requirement_label(str(requirement["id"]))]


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


func _requirement(gate: Dictionary) -> Dictionary:
	var upgrade_id := str(gate.get("required_upgrade_id", "")).strip_edges()
	if not upgrade_id.is_empty():
		return {"kind": "upgrade", "field": "required_upgrade_id", "id": upgrade_id}
	var capability_id := str(gate.get("required_capability_id", "")).strip_edges()
	if not capability_id.is_empty():
		return {"kind": "capability", "field": "required_capability_id", "id": capability_id}
	return {}


func _has_requirement(requirement: Dictionary, has_upgrade: Callable, has_capability: Callable) -> bool:
	if str(requirement["kind"]) == "upgrade":
		return has_upgrade.is_valid() and bool(has_upgrade.call(str(requirement["id"])))
	return has_capability.is_valid() and bool(has_capability.call(str(requirement["id"])))


func _requirement_label(requirement_id: String) -> String:
	return requirement_id.replace("_", " ")
