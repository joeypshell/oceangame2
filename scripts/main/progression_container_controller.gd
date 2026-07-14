extends RefCounted

const DEFAULT_LABEL := "Upgrade chest"
const EXPLICIT_INTERACTION := "interact"

var _opened_ids: Dictionary = {}


func is_opened(container_id: String) -> bool:
	return bool(_opened_ids.get(container_id, false))


func opened_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in _opened_ids.keys():
		if bool(_opened_ids[id]):
			ids.append(str(id))
	return ids


func apply_opened_to_world(world, has_discovery: Callable) -> void:
	if world == null or not world.has_method("set_progression_container_opened"):
		return
	if world.has_method("get_progression_containers") and has_discovery.is_valid():
		for container in world.get_progression_containers():
			if str(container.get("reward_type", "")) != "blueprint":
				continue
			if bool(has_discovery.call(str(container.get("reward_id", "")))):
				_opened_ids[str(container.get("id", "progression_container"))] = true
	for container_id in opened_ids():
		world.set_progression_container_opened(container_id, true)


func prompt_at(world, player_position: Vector2) -> String:
	if world == null or not world.has_method("get_progression_container_at"):
		return ""
	var container: Dictionary = world.get_progression_container_at(player_position)
	if container.is_empty() or is_opened(str(container.get("id", "progression_container"))):
		return ""
	if str(container.get("interaction", "instant")) != EXPLICIT_INTERACTION:
		return ""
	if str(container.get("reward_type", "")) == "blueprint":
		return "E: Recover %s blueprint" % _blueprint_label(container).to_lower()
	return "E: Open %s" % _display_label(container)


func try_open(world, player_position: Vector2, grant_wallet: Callable, grant_discovery: Callable, explicit_interaction := false) -> Dictionary:
	if world == null or not world.has_method("get_progression_container_at"):
		return {}

	var container: Dictionary = world.get_progression_container_at(player_position)
	if container.is_empty():
		return {}

	var container_id := str(container.get("id", "progression_container"))
	if is_opened(container_id):
		return {"state": "already_opened", "id": container_id}
	if str(container.get("interaction", "instant")) == EXPLICIT_INTERACTION and not explicit_interaction:
		return {"state": "nearby", "id": container_id}

	var container_type := str(container.get("container_type", ""))
	var reward_type := str(container.get("reward_type", ""))
	if container_type != "upgrade_chest" or not reward_type in ["wallet", "blueprint"]:
		return {"state": "unsupported", "id": container_id}

	if reward_type == "blueprint":
		return _open_blueprint(world, container, container_id, grant_discovery)

	var amount := maxi(0, int(container.get("reward_amount", 0)))
	if amount <= 0:
		return {"state": "invalid", "id": container_id}

	_opened_ids[container_id] = true
	var wallet_after: int = int(grant_wallet.call(amount))
	var note := "%s +%d wallet" % [_display_label(container), amount]
	if world.has_method("set_progression_container_opened"):
		world.set_progression_container_opened(container_id, true)
	return {
		"state": "opened",
		"id": container_id,
		"reward_amount": amount,
		"wallet_after": wallet_after,
		"note": note,
	}


func _open_blueprint(world, container: Dictionary, container_id: String, grant_discovery: Callable) -> Dictionary:
	var reward_id := str(container.get("reward_id", ""))
	if reward_id.is_empty() or not grant_discovery.is_valid():
		return {"state": "invalid", "id": container_id}
	var discovery_result: Dictionary = grant_discovery.call(reward_id)
	var reason := str(discovery_result.get("reason", ""))
	if not bool(discovery_result.get("changed", false)) and reason != "already_completed":
		return {"state": "storage_error" if reason == "storage_error" else "invalid", "id": container_id}
	_opened_ids[container_id] = true
	if world.has_method("set_progression_container_opened"):
		world.set_progression_container_opened(container_id, true)
	return {
		"state": "opened",
		"id": container_id,
		"reward_id": reward_id,
		"note": "Blueprint recovered: %s" % _blueprint_label(container),
	}


func _display_label(container: Dictionary) -> String:
	var label := str(container.get("display_label", DEFAULT_LABEL)).strip_edges()
	if label.is_empty():
		label = DEFAULT_LABEL
	return label.replace("_", " ")


func _blueprint_label(container: Dictionary) -> String:
	var label := str(container.get("reward_label", "")).strip_edges()
	return label if not label.is_empty() else str(container.get("reward_id", "blueprint")).replace("_", " ").capitalize()
