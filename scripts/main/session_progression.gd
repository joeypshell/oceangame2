extends RefCounted

const OXYGEN_TANK_UPGRADE_ID := "oxygen_tank_1"
const OXYGEN_TANK_UPGRADE_COST := 500
const OXYGEN_TANK_UPGRADE_SECONDS := 15.0
const CARGO_CAPACITY_UPGRADE_ID := "cargo_pouch_1"
const CARGO_CAPACITY_UPGRADE_COST := 700
const CARGO_CAPACITY_UPGRADE_BONUS := 1

var _wallet := 0
var _total_payout_earned := 0
var _purchased_upgrades: Dictionary = {}


func record_banked_salvage(banked_score: int) -> int:
	var payout: int = maxi(0, banked_score)
	if payout <= 0:
		return 0
	_wallet += payout
	_total_payout_earned += payout
	return payout


func purchase_oxygen_tank_upgrade() -> Dictionary:
	if has_oxygen_tank_upgrade():
		return {"purchased": false, "reason": "already_purchased", "wallet": _wallet}
	if _wallet < OXYGEN_TANK_UPGRADE_COST:
		return {
			"purchased": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": OXYGEN_TANK_UPGRADE_COST - _wallet,
		}
	_wallet -= OXYGEN_TANK_UPGRADE_COST
	_purchased_upgrades[OXYGEN_TANK_UPGRADE_ID] = true
	return {"purchased": true, "wallet": _wallet, "upgrade_id": OXYGEN_TANK_UPGRADE_ID}


func purchase_cargo_capacity_upgrade() -> Dictionary:
	if has_cargo_capacity_upgrade():
		return {"purchased": false, "reason": "already_purchased", "wallet": _wallet}
	if _wallet < CARGO_CAPACITY_UPGRADE_COST:
		return {
			"purchased": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": CARGO_CAPACITY_UPGRADE_COST - _wallet,
		}
	_wallet -= CARGO_CAPACITY_UPGRADE_COST
	_purchased_upgrades[CARGO_CAPACITY_UPGRADE_ID] = true
	return {"purchased": true, "wallet": _wallet, "upgrade_id": CARGO_CAPACITY_UPGRADE_ID}


func has_oxygen_tank_upgrade() -> bool:
	return bool(_purchased_upgrades.get(OXYGEN_TANK_UPGRADE_ID, false))


func has_cargo_capacity_upgrade() -> bool:
	return bool(_purchased_upgrades.get(CARGO_CAPACITY_UPGRADE_ID, false))


func oxygen_bonus_seconds() -> float:
	return OXYGEN_TANK_UPGRADE_SECONDS if has_oxygen_tank_upgrade() else 0.0


func cargo_capacity_bonus() -> int:
	return CARGO_CAPACITY_UPGRADE_BONUS if has_cargo_capacity_upgrade() else 0


func cargo_capacity_upgrade_cost() -> int:
	return CARGO_CAPACITY_UPGRADE_COST


func wallet() -> int:
	return _wallet


func total_payout_earned() -> int:
	return _total_payout_earned
