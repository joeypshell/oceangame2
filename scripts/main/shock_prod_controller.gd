extends RefCounted

const ATTACK_RANGE_PX := 72.0
const ATTACK_COOLDOWN_SECONDS := 0.65
const ATTACK_DAMAGE := 1

var cooldown_seconds := 0.0


func update(delta: float) -> void:
	cooldown_seconds = maxf(0.0, cooldown_seconds - maxf(0.0, delta))


func reset() -> void:
	cooldown_seconds = 0.0


func try_attack(hostiles, world, player_position: Vector2, facing_sign: float, unlocked: bool) -> Dictionary:
	if not unlocked:
		return _result(false, "locked", "Shock prod required to fight")
	if cooldown_seconds > 0.0:
		return _result(false, "cooldown", "Shock prod recharging")
	if hostiles == null:
		return _result(false, "no_controller", "Shock prod unavailable")

	cooldown_seconds = ATTACK_COOLDOWN_SECONDS
	var target: Dictionary = hostiles.attack_target(player_position, facing_sign, ATTACK_RANGE_PX)
	if target.is_empty():
		return _result(false, "miss", "Shock prod discharged")
	var hit: Dictionary = hostiles.apply_weapon_hit(world, str(target.get("id", "")), ATTACK_DAMAGE)
	if bool(hit.get("defeated", false)):
		var victory := _result(true, "defeated", "Territory clear for today")
		victory.merge(hit, true)
		return victory
	var result := _result(bool(hit.get("changed", false)), str(hit.get("reason", "hit")), "Shock prod hit - eel health %d/3" % int(hit.get("health", 0)))
	result.merge(hit, true)
	return result


func overlay_text(unlocked: bool) -> String:
	if not unlocked:
		return "Shock prod locked"
	if cooldown_seconds > 0.0:
		return "Shock prod %.1fs" % cooldown_seconds
	return "Shock prod ready"


func report(unlocked: bool) -> Dictionary:
	return {
		"unlocked": unlocked,
		"cooldown_seconds": cooldown_seconds,
		"attack_range_px": ATTACK_RANGE_PX,
		"attack_damage": ATTACK_DAMAGE,
	}


func _result(changed: bool, reason: String, note: String) -> Dictionary:
	return {"changed": changed, "reason": reason, "note": note, "defeated": false}
