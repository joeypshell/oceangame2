extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const MAP_PATH := "res://maps/production_slice_01.greybox.json"
const HOSTILE_ID := "deep_cache_territorial_eel"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	await process_frame

	_test_input_boundary()
	_test_world_boundary(world)
	_test_warning_retreat_and_contact(world)
	_test_weapon_and_day_state(world)

	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: combat runtime state source=deep_cache_territorial_eel warning=true unarmed_retreat=true contact_damage=1 weapon_locked=true hits=3 defeated=true rewards=none connector_persisted=true new_day_restored=true.")
	quit(0)


func _test_input_boundary() -> void:
	_expect(InputMap.has_action("combat_attack"), "combat_attack input action is missing")
	var events := InputMap.action_get_events("combat_attack")
	_expect(events.size() == 1, "combat_attack should have one bounded keyboard event")
	if not events.is_empty() and events[0] is InputEventKey:
		_expect((events[0] as InputEventKey).physical_keycode == KEY_SPACE, "combat_attack is not bound to physical Space")


func _test_world_boundary(world) -> void:
	var encounters: Array = world.get_hostile_encounters()
	_expect(encounters.size() == 1, "world did not expose exactly one hostile source record")
	if encounters.is_empty():
		return
	var source: Dictionary = encounters[0]
	_expect(str(source.get("id", "")) == HOSTILE_ID, "world exposed the wrong hostile id")
	_expect(source.get("home_center", Vector2.ZERO) == Vector2(66.5, 74.5) * 32.0, "hostile home center was not source-derived")
	_expect(source.get("territory_rect", Rect2()) == Rect2(Vector2(60, 71) * 32.0, Vector2(10, 8) * 32.0), "hostile territory was not source-derived")
	_expect(is_equal_approx(float(source.get("warning_radius_px", 0.0)), 128.0), "warning radius was not converted to pixels")
	_expect(is_equal_approx(float(source.get("contact_radius_px", 0.0)), 24.0), "contact radius was not converted to pixels")
	_expect(int(world.get_hostile_visual_report().get("rendered_count", 0)) == 1, "hostile renderer did not create one source-owned visual")
	source["id"] = "mutated"
	_expect(str(world.get_hostile_encounters()[0].get("id", "")) == HOSTILE_ID, "world leaked mutable hostile source state")


func _test_warning_retreat_and_contact(world) -> void:
	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world)
	var home: Vector2 = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	var approach := home + Vector2(-80, 0)
	var warning: Dictionary = hostiles.update(world, approach, 0.0)
	_expect(str(warning.get("kind", "")) == "warning", "approach did not start the warning phase")
	_expect(str(hostiles.state_for(HOSTILE_ID).get("phase", "")) == "warning", "warning phase was not retained")
	_expect(hostiles.prompt().find("watch the lunge") != -1, "warning prompt omitted the source label")

	var lower_evade_lane := Vector2(60.5, 78.5) * 32.0
	var retreat: Dictionary = hostiles.update(world, lower_evade_lane, 0.1)
	_expect(str(retreat.get("kind", "")) == "retreat", "leaving the threat envelope did not cancel the warning")
	_expect(not retreat.has("damage"), "unarmed retreat produced combat damage")
	_expect(hostiles.prompt().find("retreat or evade") != -1, "unarmed retreat omitted compact feedback")

	hostiles.reset_for_failure(world)
	home = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	var contact_position := home + Vector2(-40, 0)
	hostiles.update(world, contact_position, 0.0)
	hostiles.update(world, contact_position, 0.8)
	var contact: Dictionary = hostiles.update(world, contact_position, 0.25)
	_expect(str(contact.get("kind", "")) == "contact", "completed lunge did not emit contact")
	_expect(int(contact.get("damage", 0)) == 1, "contact did not request exactly one health damage")
	var repeated_contact: Dictionary = hostiles.update(world, contact_position, 0.01)
	_expect(not repeated_contact.has("damage"), "one lunge emitted repeated contact damage")


func _test_weapon_and_day_state(world) -> void:
	var hostiles := TerritorialHostileController.new()
	var weapon := ShockProdController.new()
	hostiles.on_map_loaded(world)
	var home: Vector2 = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	var attack_position := home + Vector2(-60, 0)

	var locked: Dictionary = weapon.try_attack(hostiles, world, attack_position, 1.0, false)
	_expect(str(locked.get("reason", "")) == "locked", "weapon attacked without the durable capability")
	_expect(int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 3, "locked weapon changed hostile health")
	var wrong_facing: Dictionary = weapon.try_attack(hostiles, world, attack_position, -1.0, true)
	_expect(str(wrong_facing.get("reason", "")) == "miss", "weapon ignored player facing")
	_expect(int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 3, "wrong-facing attack changed hostile health")
	weapon.reset()

	for expected_health in [2, 1, 0]:
		var hit: Dictionary = weapon.try_attack(hostiles, world, attack_position, 1.0, true)
		_expect(bool(hit.get("changed", false)), "unlocked in-range weapon did not hit")
		_expect(int(hostiles.state_for(HOSTILE_ID).get("health", -1)) == expected_health, "weapon hit did not apply one damage")
		_expect(not _contains_reward_key(hit), "hostile defeat result introduced a forbidden reward")
		if expected_health == 2:
			var blocked: Dictionary = weapon.try_attack(hostiles, world, attack_position, 1.0, true)
			_expect(str(blocked.get("reason", "")) == "cooldown", "weapon ignored its attack cooldown")
			_expect(int(hostiles.state_for(HOSTILE_ID).get("health", -1)) == 2, "cooldown-blocked attack changed hostile health")
		weapon.update(ShockProdController.ATTACK_COOLDOWN_SECONDS)
	_expect(str(hostiles.state_for(HOSTILE_ID).get("phase", "")) == "defeated", "third hit did not defeat the encounter")

	hostiles.on_map_loaded(world, true)
	_expect(str(hostiles.state_for(HOSTILE_ID).get("phase", "")) == "defeated", "connector-style reload did not preserve current-day defeat")
	hostiles.on_map_loaded(world, false)
	_expect(int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 3, "new-day load did not restore hostile health")
	_expect(str(hostiles.state_for(HOSTILE_ID).get("phase", "")) == "home", "new-day load did not restore hostile home phase")

	weapon.reset()
	weapon.try_attack(hostiles, world, attack_position, 1.0, true)
	hostiles.on_map_loaded(world, true)
	var refreshed: Dictionary = hostiles.state_for(HOSTILE_ID)
	_expect(int(refreshed.get("health", 0)) == 3 and refreshed.get("position", Vector2.ZERO) == refreshed.get("home_center", Vector2.ONE), "active connector reload did not restart the encounter at full health/home")
	hostiles.reset_for_failure(world)
	_expect(int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 3, "failure reset did not restore the encounter")


func _contains_reward_key(result: Dictionary) -> bool:
	for key in ["loot", "drop", "reward", "score", "cargo", "material", "wallet", "discovery_id"]:
		if result.has(key):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
