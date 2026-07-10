extends RefCounted

const SessionProgression := preload("res://scripts/main/session_progression.gd")

var _progression


func _init(progression) -> void:
	_progression = progression


func record_banked_salvage(banked_score: int) -> int:
	return _progression.record_banked_salvage(banked_score) if _progression != null else 0


func grant_wallet_reward(amount: int) -> int:
	return _progression.grant_wallet_reward(amount) if _progression != null else 0


func spend_wallet(amount: int) -> Dictionary:
	return _progression.spend_wallet(amount) if _progression != null else {"spent": false, "reason": "wallet_unavailable"}


func wallet() -> int:
	return _progression.wallet() if _progression != null else 0


func total_payout_earned() -> int:
	return _progression.total_payout_earned() if _progression != null else 0


func try_purchase(upgrade_id: String, world, player) -> Dictionary:
	if _progression == null or world == null or player == null:
		return {"purchased": false}
	if not world.is_inside_extraction(player.global_position):
		return {"purchased": false, "note": "Upgrade at extraction"}

	var result := _purchase(upgrade_id)
	if bool(result.get("purchased", false)):
		if upgrade_id == SessionProgression.LIGHT_UPGRADE_ID:
			apply_light_profile(world, player)
		return {
			"purchased": true,
			"note": _purchase_note(upgrade_id, true),
		}

	var reason := str(result.get("reason", "blocked"))
	if reason == "insufficient_funds":
		return {
			"purchased": false,
			"note": "Need %d more" % int(result.get("needed", 0)),
		}
	if reason == "already_purchased":
		return {
			"purchased": false,
			"note": _purchase_note(upgrade_id, false),
		}
	return {"purchased": false, "note": "Upgrade blocked"}


func _purchase(upgrade_id: String) -> Dictionary:
	match upgrade_id:
		SessionProgression.OXYGEN_TANK_UPGRADE_ID:
			return _progression.purchase_oxygen_tank_upgrade()
		SessionProgression.CARGO_CAPACITY_UPGRADE_ID:
			return _progression.purchase_cargo_capacity_upgrade()
		SessionProgression.LIGHT_UPGRADE_ID:
			return _progression.purchase_light_upgrade()
	return {"purchased": false, "reason": "blocked"}


func _purchase_note(upgrade_id: String, purchased: bool) -> String:
	match upgrade_id:
		SessionProgression.OXYGEN_TANK_UPGRADE_ID:
			return "O2 tank upgraded" if purchased else "O2 tank already upgraded"
		SessionProgression.CARGO_CAPACITY_UPGRADE_ID:
			return "Cargo +1 upgraded" if purchased else "Cargo +1 already upgraded"
		SessionProgression.LIGHT_UPGRADE_ID:
			return "Light +range upgraded" if purchased else "Light +range already upgraded"
	return "Upgrade blocked"


func has_oxygen_tank_upgrade() -> bool:
	return _progression != null and _progression.has_oxygen_tank_upgrade()


func has_cargo_capacity_upgrade() -> bool:
	return _progression != null and _progression.has_cargo_capacity_upgrade()


func has_light_upgrade() -> bool:
	return _progression != null and _progression.has_light_upgrade()


func has_upgrade_id(upgrade_id: String) -> bool:
	match upgrade_id:
		SessionProgression.OXYGEN_TANK_UPGRADE_ID:
			return has_oxygen_tank_upgrade()
		SessionProgression.CARGO_CAPACITY_UPGRADE_ID:
			return has_cargo_capacity_upgrade()
		SessionProgression.LIGHT_UPGRADE_ID:
			return has_light_upgrade()
	return false


func apply_light_profile(world, player) -> void:
	if _progression == null:
		return
	if player != null and player.has_method("apply_light_profile"):
		player.apply_light_profile(_progression.light_range_scale(), _progression.light_alpha())
	if world != null and world.has_method("set_visibility_upgrade_state"):
		world.set_visibility_upgrade_state(SessionProgression.LIGHT_UPGRADE_ID, has_light_upgrade())


func held_salvage_capacity(base_capacity: int) -> int:
	return base_capacity + _progression.cargo_capacity_bonus() if _progression != null else base_capacity


func oxygen_capacity_seconds(base_seconds: float) -> float:
	return base_seconds + _progression.oxygen_bonus_seconds() if _progression != null else base_seconds


func overlay_text(world, player) -> String:
	var oxygen_text := "O2 tank +%ds" % int(SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS)
	if not has_oxygen_tank_upgrade():
		oxygen_text = "U: O2 +%ds (%d)" % [
			int(SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS),
			SessionProgression.OXYGEN_TANK_UPGRADE_COST,
		]
	var cargo_text := "Cargo +%d" % int(SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS)
	if not has_cargo_capacity_upgrade():
		cargo_text = "C: Cargo +%d (%d)" % [
			int(SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS),
			SessionProgression.CARGO_CAPACITY_UPGRADE_COST,
		]
	var at_extraction: bool = world != null and player != null and world.is_inside_extraction(player.global_position)
	var light_text := "Light +range" if has_light_upgrade() else "Light base"
	if not has_light_upgrade() and at_extraction:
		light_text = "L: Light +range (%d)" % SessionProgression.LIGHT_UPGRADE_COST
	return "Wallet %d\n%s | %s\n%s" % [
		wallet(),
		oxygen_text,
		cargo_text,
		light_text,
	]


func result_text() -> String:
	var oxygen_text := "O2 tank +%ds" % int(SessionProgression.OXYGEN_TANK_UPGRADE_SECONDS) if has_oxygen_tank_upgrade() else "O2 tank base"
	var cargo_text := "Cargo +%d" % int(SessionProgression.CARGO_CAPACITY_UPGRADE_BONUS) if has_cargo_capacity_upgrade() else "Cargo base"
	var light_text := "Light +range" if has_light_upgrade() else "Light base"
	return "Wallet %d | %s | %s | %s" % [wallet(), oxygen_text, cargo_text, light_text]


func is_status_note(status_note: String) -> bool:
	return (
		status_note == "O2 tank upgraded"
		or status_note == "O2 tank already upgraded"
		or status_note == "Cargo +1 upgraded"
		or status_note == "Cargo +1 already upgraded"
		or status_note == "Light +range upgraded"
		or status_note == "Light +range already upgraded"
		or status_note.begins_with("Upgrade chest +")
		or status_note == "Upgrade at extraction"
		or status_note == "Upgrade blocked"
		or status_note.begins_with("Need ")
	)
