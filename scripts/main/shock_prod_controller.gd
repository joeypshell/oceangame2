extends RefCounted

const ATTACK_RANGE_PX := 72.0
const ATTACK_COOLDOWN_SECONDS := 0.65
const ATTACK_DAMAGE := 1

var cooldown_seconds := 0.0


func update(delta: float) -> void:
	cooldown_seconds = maxf(0.0, cooldown_seconds - maxf(0.0, delta))


func reset() -> void:
	cooldown_seconds = 0.0


func try_attack(hostiles, world, player_position: Vector2, facing_sign: float, unlocked: bool, capacitor_unlocked := false) -> Dictionary:
	if not unlocked:
		return _result(false, "locked", "Shock prod required to fight")
	if cooldown_seconds > 0.0:
		return _result(false, "cooldown", "Shock prod recharging")
	if hostiles == null:
		return _result(false, "no_controller", "Shock prod unavailable")

	var facing := 1.0 if facing_sign >= 0.0 else -1.0
	cooldown_seconds = ATTACK_COOLDOWN_SECONDS
	var target: Dictionary = hostiles.attack_target(player_position, facing_sign, ATTACK_RANGE_PX)
	if target.is_empty():
		return _discharge_result(
			_result(false, "miss", "Shock prod miss - move closer and face eel"),
			player_position + Vector2(ATTACK_RANGE_PX * facing, 0.0),
			facing,
			false
		)
	var target_position: Vector2 = target.get("position", player_position + Vector2(ATTACK_RANGE_PX * facing, 0.0))
	var hit: Dictionary = hostiles.apply_weapon_hit(world, str(target.get("id", "")), ATTACK_DAMAGE, capacitor_unlocked)
	if bool(hit.get("defeated", false)):
		var victory := _result(true, "defeated", "Territory clear for today")
		victory.merge(hit, true)
		return _discharge_result(victory, target_position, facing, true)
	var note := "Shock prod hit: eel health %d/3 (-1)" % int(hit.get("health", 0))
	if bool(hit.get("interrupted", false)):
		note = "Shock prod capacitor hit: eel health %d/3 (-1), recovery %.1fs" % [int(hit.get("health", 0)), float(hit.get("recovery_seconds", 0.0))]
	var result := _result(bool(hit.get("changed", false)), str(hit.get("reason", "hit")), note)
	result.merge(hit, true)
	return _discharge_result(result, target_position, facing, true)


func overlay_text(unlocked: bool, capacitor_unlocked := false, selected := true) -> String:
	if not unlocked:
		return "Shock prod locked"
	if not selected:
		return "Shock prod owned | select active tool"
	if cooldown_seconds > 0.0:
		return "Shock prod +capacitor %.1fs | interrupts warning/lunge" % cooldown_seconds if capacitor_unlocked else "Shock prod %.1fs" % cooldown_seconds
	return "Shock prod +capacitor ready | hit warning/lunge to force recovery" if capacitor_unlocked else "Shock prod ready"


func report(unlocked: bool, capacitor_unlocked := false) -> Dictionary:
	return {
		"unlocked": unlocked,
		"capacitor_unlocked": capacitor_unlocked,
		"cooldown_seconds": cooldown_seconds,
		"attack_range_px": ATTACK_RANGE_PX,
		"attack_damage": ATTACK_DAMAGE,
	}


func _result(changed: bool, reason: String, note: String) -> Dictionary:
	return {
		"changed": changed,
		"reason": reason,
		"note": note,
		"defeated": false,
		"discharged": false,
		"connected": false,
	}


func _discharge_result(result: Dictionary, target_position: Vector2, facing_sign: float, connected: bool) -> Dictionary:
	result["discharged"] = true
	result["connected"] = connected
	result["target_position"] = target_position
	result["facing_sign"] = facing_sign
	result["attack_range_px"] = ATTACK_RANGE_PX
	return result
