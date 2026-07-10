extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const ShockProdController := preload("res://scripts/main/shock_prod_controller.gd")
const TerritorialHostileController := preload("res://scripts/main/territorial_hostile_controller.gd")

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

	_test_base_warning_hit(world)
	_test_capacitor_warning_interrupt(world)
	_test_capacitor_lunge_interrupt(world)
	_test_range_window_and_lethal_precedence(world)

	world.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Shock-prod capacitor state smoke failed: %s" % failure)
		quit(1)
		return
	print("Shock-prod capacitor state smoke passed: base_warning_preserved=true capacitor_warning_interrupt=true capacitor_lunge_interrupt=true damage=1 recovery=1.25 range=72 cooldown=0.65 non_window_preserved=true lethal_defeat_precedence=true.")
	quit(0)


func _test_base_warning_hit(world) -> void:
	var fixture := _warning_fixture(world)
	var hostiles = fixture["hostiles"]
	var weapon := ShockProdController.new()
	var result: Dictionary = weapon.try_attack(hostiles, world, fixture["player"], 1.0, true, false)
	var state: Dictionary = hostiles.state_for(HOSTILE_ID)
	_expect(bool(result.get("changed", false)) and not bool(result.get("interrupted", false)), "base shock prod unexpectedly interrupted warning")
	_expect(int(state.get("health", 0)) == 2 and state.get("phase") == "warning", "base warning hit changed damage or phase")


func _test_capacitor_warning_interrupt(world) -> void:
	var fixture := _warning_fixture(world)
	var hostiles = fixture["hostiles"]
	var weapon := ShockProdController.new()
	var result: Dictionary = weapon.try_attack(hostiles, world, fixture["player"], 1.0, true, true)
	var state: Dictionary = hostiles.state_for(HOSTILE_ID)
	_expect(bool(result.get("interrupted", false)) and result.get("reason") == "interrupted", "capacitor did not report warning interruption")
	_expect(int(state.get("health", 0)) == 2 and state.get("phase") == "recovery", "warning interrupt changed damage or missed recovery")
	_expect(is_equal_approx(float(state.get("phase_seconds", 0.0)), 1.25), "warning interrupt did not use source recovery timing")
	_expect(str(result.get("note", "")).begins_with("Lunge interrupted"), "interrupt feedback was not compact/readable")
	var cooldown: Dictionary = weapon.try_attack(hostiles, world, fixture["player"], 1.0, true, true)
	_expect(cooldown.get("reason") == "cooldown" and int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 2, "capacitor bypassed base cooldown")
	_expect(weapon.overlay_text(true, true).find("capacitor") != -1 and bool(weapon.report(true, true).get("capacitor_unlocked", false)), "capacitor readiness/report was missing")


func _test_capacitor_lunge_interrupt(world) -> void:
	var fixture := _warning_fixture(world)
	var hostiles = fixture["hostiles"]
	hostiles.update(world, fixture["player"], 0.8)
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "lunge", "lunge interrupt fixture did not enter lunge")
	var weapon := ShockProdController.new()
	var result: Dictionary = weapon.try_attack(hostiles, world, fixture["player"], 1.0, true, true)
	var state: Dictionary = hostiles.state_for(HOSTILE_ID)
	_expect(bool(result.get("interrupted", false)) and state.get("phase") == "recovery", "capacitor did not interrupt active lunge")
	_expect(int(state.get("health", 0)) == 2, "lunge interruption changed one-hit damage")


func _test_range_window_and_lethal_precedence(world) -> void:
	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world, false)
	var home: Vector2 = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	var weapon := ShockProdController.new()
	var home_hit: Dictionary = weapon.try_attack(hostiles, world, home + Vector2(-60, 0), 1.0, true, true)
	_expect(not bool(home_hit.get("interrupted", false)) and hostiles.state_for(HOSTILE_ID).get("phase") == "home", "capacitor interrupted outside warning/lunge")
	weapon.reset()
	var miss: Dictionary = weapon.try_attack(hostiles, world, home + Vector2(-100, 0), 1.0, true, true)
	_expect(miss.get("reason") == "miss" and int(hostiles.state_for(HOSTILE_ID).get("health", 0)) == 2, "capacitor changed range or miss damage")

	hostiles.reset_for_failure(world)
	hostiles.apply_weapon_hit(world, HOSTILE_ID, 2)
	home = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	var player := home + Vector2(-60, 0)
	hostiles.update(world, player, 0.0)
	weapon.reset()
	var lethal: Dictionary = weapon.try_attack(hostiles, world, player, 1.0, true, true)
	_expect(bool(lethal.get("defeated", false)) and not bool(lethal.get("interrupted", true)), "lethal capacitor hit did not preserve defeat precedence")
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "defeated", "lethal capacitor hit entered recovery")


func _warning_fixture(world) -> Dictionary:
	var hostiles := TerritorialHostileController.new()
	hostiles.on_map_loaded(world, false)
	var home: Vector2 = hostiles.state_for(HOSTILE_ID).get("home_center", Vector2.ZERO)
	var player := home + Vector2(-60, 0)
	hostiles.update(world, player, 0.0)
	_expect(hostiles.state_for(HOSTILE_ID).get("phase") == "warning", "capacitor fixture did not enter warning")
	return {"hostiles": hostiles, "player": player}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
