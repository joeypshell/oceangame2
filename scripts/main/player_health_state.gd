extends RefCounted

const DEFAULT_MAX_HEALTH := 3
const DEFAULT_INVULNERABILITY_SECONDS := 1.0

var max_health := DEFAULT_MAX_HEALTH
var current_health := DEFAULT_MAX_HEALTH
var invulnerability_seconds := 0.0
var last_damage_source_id := ""


func _init(health_max := DEFAULT_MAX_HEALTH) -> void:
	max_health = maxi(1, int(health_max))
	current_health = max_health


func begin_map_leg(preserve_health := false) -> void:
	if not preserve_health:
		current_health = max_health
	invulnerability_seconds = 0.0
	last_damage_source_id = ""


func update(delta: float) -> void:
	invulnerability_seconds = maxf(0.0, invulnerability_seconds - maxf(0.0, delta))


func apply_damage(amount: int, source_id: String) -> Dictionary:
	if amount <= 0:
		return _result(false, "invalid_damage", false)
	if current_health <= 0:
		return _result(false, "already_defeated", true)
	if invulnerability_seconds > 0.0:
		return _result(false, "invulnerable", false)
	current_health = maxi(0, current_health - amount)
	invulnerability_seconds = DEFAULT_INVULNERABILITY_SECONDS
	last_damage_source_id = source_id
	return _result(true, "defeated" if current_health == 0 else "damaged", current_health == 0)


func refill_at_boat() -> bool:
	if current_health >= max_health:
		return false
	current_health = max_health
	invulnerability_seconds = 0.0
	last_damage_source_id = ""
	return true


func reset() -> void:
	begin_map_leg(false)


func overlay_text() -> String:
	return "Health %d/%d" % [current_health, max_health]


func report() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"invulnerability_seconds": invulnerability_seconds,
		"last_damage_source_id": last_damage_source_id,
		"defeated": current_health <= 0,
	}


func _result(changed: bool, reason: String, defeated: bool) -> Dictionary:
	return {
		"changed": changed,
		"reason": reason,
		"defeated": defeated,
		"current_health": current_health,
		"max_health": max_health,
		"source_id": last_damage_source_id,
	}
